import Foundation

extension ComicBookPackage {
    var isPaywallLocked: Bool {
        !paywallMetadata.isUnlocked || exportAvailability.lockedByPaywall
    }

    var rankedPaywallOffers: [ComicPaywallOffer] {
        paywallMetadata.offers.sorted { lhs, rhs in
            if lhs.priority != rhs.priority {
                return (lhs.priority ?? Int.max) < (rhs.priority ?? Int.max)
            }
            if lhs.isRecommended != rhs.isRecommended {
                return (lhs.isRecommended ?? false) && !(rhs.isRecommended ?? false)
            }
            let lhsScore = lhs.priorityScore
            let rhsScore = rhs.priorityScore
            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }
            let lhsPrice = lhs.decimalPrice ?? Decimal.greatestFiniteMagnitude
            let rhsPrice = rhs.decimalPrice ?? Decimal.greatestFiniteMagnitude
            if lhsPrice != rhsPrice {
                return lhsPrice < rhsPrice
            }
            return lhs.id < rhs.id
        }
    }

    var primaryPaywallOffer: ComicPaywallOffer? {
        rankedPaywallOffers.first
    }

    var paywallLockReasonText: String {
        switch paywallMetadata.lockReason {
        case "preview_limit":
            return "Free preview pages are complete."
        case "subscription_required":
            return "An active subscription is required."
        case "purchase_required":
            return "A one-time unlock is required."
        case let value?:
            return value.replacingOccurrences(of: "_", with: " ").capitalized
        case nil:
            return "Unlock full story to continue."
        }
    }

    func personalized(with storyText: String?) -> ComicBookPackage {
        guard let storyText else { return self }
        let storyLines = storyText.storyLines
        guard !storyLines.isEmpty else { return self }
        let style = StoryStyle(displayLabel: styleLabel) ?? .cinematic

        let personalizedCover = ComicBookCover(
            imageURL: cover.imageURL,
            titleText: cover.titleText ?? title,
            subtitleText: storyLines.first
        )

        let personalizedPages = pages.enumerated().map { index, page in
            let beat = storyLines[index % storyLines.count]
            return ComicPresentationPage(
                id: page.id,
                pageNumber: page.pageNumber,
                title: beat.comicHeadline(fallback: page.title),
                caption: beat,
                thumbnailURL: page.thumbnailURL,
                fullImageURL: page.fullImageURL,
                overlays: beat.comicOverlays(style: style, fallback: page.overlays)
            )
        }

        return ComicBookPackage(
            projectID: projectID,
            title: title,
            subtitle: subtitle ?? storyLines.first,
            styleLabel: styleLabel,
            cover: personalizedCover,
            pages: personalizedPages,
            previewPageCount: previewPageCount,
            presentationHints: presentationHints,
            exportAvailability: exportAvailability,
            paywallMetadata: paywallMetadata,
            ctaMetadata: ctaMetadata,
            readingProgress: readingProgress,
            legacyRevealMetadata: legacyRevealMetadata,
            source: source
        )
    }
}

extension ComicPaywallOffer {
    var formattedPriceText: String {
        "\(price) \(currency)"
    }

    fileprivate var priorityScore: Int {
        var score = 0
        if isRecommended == true {
            score += 60
        }
        let normalizedID = id.lowercased()
        if normalizedID.contains("unlock_full") || normalizedID.contains("full_story") {
            score += 120
        } else if normalizedID.contains("unlock") {
            score += 100
        }
        if normalizedID.contains("subscription") || normalizedID.contains("monthly") {
            score += 70
        }
        if normalizedID.contains("annual") || normalizedID.contains("yearly") {
            score += 80
        }
        if normalizedID.contains("export") || normalizedID.contains("addon") {
            score += 40
        }

        if let decimalPrice {
            let capped = min(100, max(1, NSDecimalNumber(decimal: decimalPrice).intValue))
            score += (100 - capped)
        } else {
            score -= 30
        }

        return score
    }

    fileprivate var decimalPrice: Decimal? {
        let normalized = price
            .replacingOccurrences(of: ",", with: ".")
            .components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted)
            .joined()
        return Decimal(string: normalized)
    }
}

private extension String {
    var storyLines: [String] {
        components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 4 }
            .prefix(12)
            .map { $0.truncated(maxLength: 96) }
    }

    func truncated(maxLength: Int) -> String {
        guard count > maxLength else { return self }
        return String(prefix(maxLength - 1)) + "…"
    }

    func comicHeadline(fallback: String) -> String {
        let tokens = components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"“”'")) }
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return fallback }
        let headline = tokens.prefix(4).joined(separator: " ")
        return headline.capitalized
    }

    func comicOverlays(
        style: StoryStyle,
        fallback: [ComicPageTextOverlay]
    ) -> [ComicPageTextOverlay] {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }

        let narration = ComicPageTextOverlay(
            kind: .narration,
            text: trimmed.truncated(maxLength: 72),
            normalizedX: 0.3,
            normalizedY: 0.15,
            normalizedWidth: 0.46,
            tone: .accent
        )

        let reactionText: String
        switch style {
        case .manga:
            reactionText = "This changes everything."
        case .western:
            reactionText = "Then the town just got louder."
        case .cartoon:
            reactionText = "Okay. That escalated fast."
        case .cinematic:
            reactionText = "Then the next move has to be precise."
        case .childrensBook:
            reactionText = "So the journey kept glowing forward."
        }

        let speech = ComicPageTextOverlay(
            kind: .speech,
            text: reactionText,
            speaker: "Hero",
            normalizedX: 0.72,
            normalizedY: 0.72,
            normalizedWidth: 0.34,
            tone: .paper,
            tailDirection: .left
        )

        return [narration, speech]
    }
}
