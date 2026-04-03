import Foundation

protocol ComicPackageService: AnyObject {
    func fetchComicBookPackage(projectID: UUID) async throws -> ComicBookPackage
    func fetchGenerationBlueprint(projectID: UUID) async throws -> ComicGenerationBlueprint
    func updateReadingProgress(
        projectID: UUID,
        currentPageIndex: Int,
        lastOpenedAtUTC: Date
    ) async throws -> ComicReadingProgress
}

final class DefaultComicPackageService: ComicPackageService {
    private let apiClient: any APIClient

    init(apiClient: any APIClient) {
        self.apiClient = apiClient
    }

    func fetchComicBookPackage(projectID: UUID) async throws -> ComicBookPackage {
        do {
            let endpoint = ComicPackageEndpoints.fetch(projectID: projectID)
            let dto = try await apiClient.request(endpoint, decode: ComicBookPackageResponseDTO.self)
            return dto.toDomain(source: .remote)
        } catch let apiError as APIError {
            // Keep a narrow fallback only for explicit contract-not-implemented states.
            if apiError.isContractFallbackEligible {
                return MockFixtures.sampleComicBookPackage(projectID: projectID, source: .fallback)
            }
            throw apiError
        } catch {
            throw error
        }
    }

    func fetchGenerationBlueprint(projectID: UUID) async throws -> ComicGenerationBlueprint {
        do {
            let endpoint = ComicPackageEndpoints.fetchGenerationBlueprint(projectID: projectID)
            let dto = try await apiClient.request(endpoint, decode: ComicGenerationBlueprintResponseDTO.self)
            return dto.toDomain()
        } catch let apiError as APIError {
            if apiError.isContractFallbackEligible {
                return MockFixtures.sampleGenerationBlueprint(
                    projectID: projectID,
                    style: .cinematic,
                    storyText: "A personalized comic is being generated from the story you wrote."
                )
            }
            throw apiError
        } catch {
            throw error
        }
    }

    func updateReadingProgress(
        projectID: UUID,
        currentPageIndex: Int,
        lastOpenedAtUTC: Date
    ) async throws -> ComicReadingProgress {
        do {
            let endpoint = try ComicPackageEndpoints.updateReadingProgress(
                projectID: projectID,
                currentPageIndex: currentPageIndex,
                lastOpenedAtUTC: lastOpenedAtUTC
            )
            let dto = try await apiClient.request(endpoint, decode: ComicReadingProgressResponseDTO.self)
            return ComicReadingProgress(
                currentPageIndex: dto.currentPageIndex,
                lastOpenedAtUTC: dto.lastOpenedAtUTC
            )
        } catch let apiError as APIError {
            // Temporary no-op fallback while PATCH endpoint becomes widely available.
            if apiError.isWriteBackFallbackEligible {
                return ComicReadingProgress(
                    currentPageIndex: currentPageIndex,
                    lastOpenedAtUTC: lastOpenedAtUTC
                )
            }
            throw apiError
        } catch {
            throw error
        }
    }
}

final class MockComicPackageService: ComicPackageService {
    func fetchComicBookPackage(projectID: UUID) async throws -> ComicBookPackage {
        MockFixtures.sampleComicBookPackage(projectID: projectID, source: .mock)
    }

    func fetchGenerationBlueprint(projectID: UUID) async throws -> ComicGenerationBlueprint {
        MockFixtures.sampleGenerationBlueprint(
            projectID: projectID,
            style: .cinematic,
            storyText: "A personalized comic is being generated from the story you wrote."
        )
    }

    func updateReadingProgress(
        projectID: UUID,
        currentPageIndex: Int,
        lastOpenedAtUTC: Date
    ) async throws -> ComicReadingProgress {
        _ = (projectID, lastOpenedAtUTC)
        return ComicReadingProgress(currentPageIndex: currentPageIndex, lastOpenedAtUTC: lastOpenedAtUTC)
    }
}

extension ComicBookPackageResponseDTO {
    func toDomain(source: ComicPackageSource) -> ComicBookPackage {
        let fallbackStyle = styleLabel.flatMap(StoryStyle.init(displayLabel:)) ?? .cinematic
        let defaultPackage = MockFixtures.sampleComicBookPackage(projectID: projectID, style: fallbackStyle, source: source)
        let mappedGenerationBlueprint = generationBlueprint?.toDomain() ?? defaultPackage.generationBlueprint

        let mappedPages: [ComicPresentationPage] = pages.isEmpty
            ? defaultPackage.pages
            : pages.enumerated().map { index, page in
                ComicPresentationPage(
                    id: page.id,
                    pageNumber: page.pageNumber,
                    title: page.title,
                    caption: page.caption,
                    thumbnailURL: page.thumbnailURL,
                    fullImageURL: page.fullImageURL,
                    overlays: Self.resolveOverlays(
                        for: page.pageNumber,
                        generationBlueprint: mappedGenerationBlueprint,
                        fallback: defaultPackage.pages[safe: index]?.overlays ?? []
                    )
                )
            }

        let mappedHints = ComicPresentationHints(
            readingDirection: Self.mapReadingDirection(
                presentationHints?.readingDirection,
                fallback: defaultPackage.presentationHints.readingDirection
            ),
            preferredRevealMode: presentationHints?.preferredRevealMode ?? defaultPackage.presentationHints.preferredRevealMode,
            deskTheme: Self.mapDeskTheme(
                presentationHints?.deskTheme,
                fallback: defaultPackage.presentationHints.deskTheme
            ),
            accentHex: presentationHints?.accentHex ?? defaultPackage.presentationHints.accentHex,
            extra: presentationHints?.extra ?? defaultPackage.presentationHints.extra
        )

        let mappedExportAvailability = ComicExportAvailability(
            isPDFAvailable: exportAvailability?.isPDFAvailable ?? defaultPackage.exportAvailability.isPDFAvailable,
            pdfURL: exportAvailability?.pdfURL ?? defaultPackage.exportAvailability.pdfURL,
            isImagePackAvailable: exportAvailability?.isImagePackAvailable ?? defaultPackage.exportAvailability.isImagePackAvailable,
            lockedByPaywall: exportAvailability?.lockedByPaywall ?? defaultPackage.exportAvailability.lockedByPaywall
        )

        let mappedPaywallOffers: [ComicPaywallOffer] = (paywallMetadata?.offers ?? []).compactMap { offerDTO in
            guard let id = offerDTO.offerID?.trimmedNonEmpty else { return nil }
            guard let price = offerDTO.price?.trimmedNonEmpty else { return nil }
            guard let currency = offerDTO.currency?.trimmedNonEmpty else { return nil }
            let normalizedPriority = offerDTO.priority.map { min(max($0, 0), 1_000) }
            return ComicPaywallOffer(
                id: id,
                price: price,
                currency: currency,
                priority: normalizedPriority,
                isRecommended: offerDTO.isRecommended,
                badgeLabel: offerDTO.badgeLabel?.trimmedNonEmpty
            )
        }
        let resolvedPaywallOffers = mappedPaywallOffers.isEmpty
            ? defaultPackage.paywallMetadata.offers
            : mappedPaywallOffers

        let mappedPaywall = ComicPaywallMetadata(
            isUnlocked: paywallMetadata?.isUnlocked ?? defaultPackage.paywallMetadata.isUnlocked,
            lockReason: paywallMetadata?.lockReason?.trimmedNonEmpty ?? defaultPackage.paywallMetadata.lockReason,
            offers: resolvedPaywallOffers
        )

        let mappedCTA = ComicCTAMetadata(
            revealHeadline: ctaMetadata?.revealHeadline?.trimmedNonEmpty
                ?? legacyRevealMetadata?.headline
                ?? defaultPackage.ctaMetadata.revealHeadline,
            revealSubheadline: ctaMetadata?.revealSubheadline?.trimmedNonEmpty
                ?? legacyRevealMetadata?.subheadline
                ?? defaultPackage.ctaMetadata.revealSubheadline,
            revealPrimaryLabel: ctaMetadata?.revealPrimaryLabel?.trimmedNonEmpty
                ?? defaultPackage.ctaMetadata.revealPrimaryLabel,
            revealSecondaryLabel: ctaMetadata?.revealSecondaryLabel?.trimmedNonEmpty
                ?? defaultPackage.ctaMetadata.revealSecondaryLabel,
            exportLabel: ctaMetadata?.exportLabel?.trimmedNonEmpty
                ?? defaultPackage.ctaMetadata.exportLabel
        )
        let mappedLegacyReveal = legacyRevealMetadata.map {
            ComicRevealMetadata(
                headline: $0.headline,
                subheadline: $0.subheadline,
                personalizationTag: $0.personalizationTag,
                generatedAtUTC: $0.generatedAtUTC
            )
        }
        let resolvedPreviewPageCount = min(
            max(0, previewPages ?? defaultPackage.previewPageCount),
            mappedPages.count
        )
        let maxPageIndex = max(0, mappedPages.count - 1)
        let resolvedReadingProgressIndex = min(
            max(0, readingProgress?.currentPageIndex ?? defaultPackage.readingProgress.currentPageIndex),
            maxPageIndex
        )

        return ComicBookPackage(
            projectID: projectID,
            title: title,
            subtitle: subtitle,
            styleLabel: styleLabel?.trimmedNonEmpty ?? defaultPackage.styleLabel,
            cover: ComicBookCover(
                imageURL: cover?.imageURL ?? defaultPackage.cover.imageURL,
                titleText: cover?.titleText ?? defaultPackage.cover.titleText,
                subtitleText: cover?.subtitleText ?? defaultPackage.cover.subtitleText
            ),
            pages: mappedPages,
            previewPageCount: resolvedPreviewPageCount,
            presentationHints: mappedHints,
            exportAvailability: mappedExportAvailability,
            paywallMetadata: mappedPaywall,
            ctaMetadata: mappedCTA,
            readingProgress: ComicReadingProgress(
                currentPageIndex: resolvedReadingProgressIndex,
                lastOpenedAtUTC: readingProgress?.lastOpenedAtUTC ?? defaultPackage.readingProgress.lastOpenedAtUTC
            ),
            legacyRevealMetadata: mappedLegacyReveal,
            generationBlueprint: mappedGenerationBlueprint,
            source: source
        )
    }

    static func resolveOverlays(
        for pageNumber: Int,
        generationBlueprint: ComicGenerationBlueprint?,
        fallback: [ComicPageTextOverlay]
    ) -> [ComicPageTextOverlay] {
        guard
            let generationBlueprint,
            let generatedPage = generationBlueprint.pages.first(where: { $0.pageNumber == pageNumber })
        else {
            return fallback
        }

        let anchorPositions: [(Double, Double)] = [
            (0.24, 0.18),
            (0.74, 0.34),
            (0.28, 0.72),
            (0.72, 0.82),
        ]
        var overlays: [ComicPageTextOverlay] = []

        for (index, panel) in generatedPage.panelSpecs.prefix(anchorPositions.count).enumerated() {
            let (x, y) = anchorPositions[index]

            if let narration = panel.narration?.trimmedNonEmpty {
                overlays.append(
                    ComicPageTextOverlay(
                        kind: .narration,
                        text: narration,
                        normalizedX: x,
                        normalizedY: y,
                        normalizedWidth: index.isMultiple(of: 2) ? 0.34 : 0.30,
                        tone: index == 0 ? .accent : .ink
                    )
                )
            }

            if let dialogue = panel.dialogue?.trimmedNonEmpty {
                overlays.append(
                    ComicPageTextOverlay(
                        kind: .speech,
                        text: dialogue,
                        speaker: "Hero",
                        normalizedX: min(0.78, x + 0.08),
                        normalizedY: min(0.86, y + 0.12),
                        normalizedWidth: 0.34,
                        tone: .paper,
                        tailDirection: x < 0.5 ? .left : .right
                    )
                )
            }
        }

        return overlays.isEmpty ? fallback : overlays
    }

    static func mapReadingDirection(
        _ value: String?,
        fallback: ComicPresentationHints.ReadingDirection
    ) -> ComicPresentationHints.ReadingDirection {
        guard let normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !normalized.isEmpty else {
            return fallback
        }

        switch normalized {
        case ComicPresentationHints.ReadingDirection.leftToRight.rawValue, "ltr":
            return .leftToRight
        case ComicPresentationHints.ReadingDirection.rightToLeft.rawValue, "rtl":
            return .rightToLeft
        default:
            return fallback
        }
    }

    static func mapDeskTheme(
        _ value: String?,
        fallback: ComicPresentationHints.DeskTheme
    ) -> ComicPresentationHints.DeskTheme {
        guard let normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !normalized.isEmpty else {
            return fallback
        }

        switch normalized {
        case ComicPresentationHints.DeskTheme.graphite.rawValue, "charcoal", "slate":
            return .graphite
        case ComicPresentationHints.DeskTheme.silver.rawValue, "light", "paper", "linen":
            return .silver
        case ComicPresentationHints.DeskTheme.walnut.rawValue, "oak", "wood":
            return .walnut
        default:
            return fallback
        }
    }
}

extension ComicGenerationBlueprintResponseDTO {
    func toDomain() -> ComicGenerationBlueprint {
        ComicGenerationBlueprint(
            storyPlan: storyPlan.toDomain(),
            characterBible: characterBible.toDomain(),
            styleGuide: styleGuide.toDomain(),
            referenceAssets: referenceAssets.map { $0.toDomain() },
            pages: pages.map { $0.toDomain() },
            panelRenders: panelRenders.map { $0.toDomain() },
            qualitySignals: qualitySignals.map { $0.toDomain() }
        )
    }
}

private extension ComicStoryPlanResponseDTO {
    func toDomain() -> ComicStoryPlan {
        ComicStoryPlan(
            logline: logline,
            tone: tone,
            beats: beats.map { $0.toDomain() }
        )
    }
}

private extension ComicStoryBeatResponseDTO {
    func toDomain() -> ComicStoryBeat {
        ComicStoryBeat(
            id: beatID,
            title: title,
            summary: summary,
            emotionalIntent: emotionalIntent,
            sceneType: sceneType,
            panelCountHint: panelCountHint,
            keyMoment: keyMoment
        )
    }
}

private extension ComicCharacterBibleResponseDTO {
    func toDomain() -> ComicCharacterBible {
        ComicCharacterBible(
            codename: codename,
            essence: essence,
            physicalTraits: physicalTraits,
            wardrobeKeywords: wardrobeKeywords,
            paletteHexes: paletteHexes,
            silhouetteKeywords: silhouetteKeywords,
            continuityRules: continuityRules,
            sourcePhotoCount: sourcePhotoCount
        )
    }
}

private extension ComicStyleGuideResponseDTO {
    func toDomain() -> ComicStyleGuide {
        ComicStyleGuide(
            styleID: styleID,
            displayLabel: displayLabel,
            lineWeight: lineWeight,
            shading: shading,
            framingRules: framingRules,
            paletteNotes: paletteNotes,
            bubbleLanguage: bubbleLanguage,
            pageLayoutLanguage: pageLayoutLanguage
        )
    }
}

private extension ComicReferenceAssetResponseDTO {
    func toDomain() -> ComicReferenceAsset {
        ComicReferenceAsset(
            id: assetID,
            title: title,
            source: source,
            tags: tags.toDomain(),
            retrievalReason: retrievalReason,
            usagePrompt: usagePrompt
        )
    }
}

private extension ComicReferenceAssetTagsResponseDTO {
    func toDomain() -> ComicReferenceAssetTags {
        ComicReferenceAssetTags(
            style: style,
            shotType: shotType,
            sceneType: sceneType,
            lighting: lighting,
            mood: mood,
            environment: environment,
            characterPose: characterPose,
            panelDensity: panelDensity,
            panelRole: panelRole,
            renderTraits: renderTraits,
            speechDensity: speechDensity
        )
    }
}

private extension ComicGenerationPageResponseDTO {
    func toDomain() -> ComicGenerationPage {
        ComicGenerationPage(
            id: "page-\(pageNumber)",
            pageNumber: pageNumber,
            title: title,
            narrativePurpose: narrativePurpose,
            panelSpecs: panelSpecs.map { $0.toDomain() }
        )
    }
}

private extension ComicGenerationPanelSpecResponseDTO {
    func toDomain() -> ComicGenerationPanelSpec {
        ComicGenerationPanelSpec(
            id: panelID,
            beatID: beatID,
            pageNumber: pageNumber,
            panelIndex: panelIndex,
            shotType: shotType,
            environment: environment,
            mood: mood,
            action: action,
            narration: narration,
            dialogue: dialogue,
            continuityNotes: continuityNotes,
            referenceAssetIDs: referenceAssetIDs,
            renderPrompt: renderPrompt
        )
    }
}

private extension ComicPanelRenderResponseDTO {
    func toDomain() -> ComicPanelRender {
        ComicPanelRender(
            id: panelID,
            pageNumber: pageNumber,
            imageURL: imageURL,
            thumbnailURL: thumbnailURL,
            caption: caption,
            dialogue: dialogue,
            renderPrompt: renderPrompt
        )
    }
}

private extension ComicQualitySignalResponseDTO {
    func toDomain() -> ComicQualitySignal {
        ComicQualitySignal(name: name, status: status, message: message)
    }
}

private extension APIError {
    var isContractFallbackEligible: Bool {
        switch self {
        case .decoding, .emptyResponseData, .transport:
            return true
        case let .server(statusCode, _):
            return statusCode == 501 || statusCode == 404
        case let .backend(code, _):
            return code == "ENDPOINT_NOT_IMPLEMENTED" || code == "PROJECT_NOT_FOUND"
        default:
            return false
        }
    }

    var isWriteBackFallbackEligible: Bool {
        switch self {
        case .transport:
            return true
        case let .server(statusCode, _):
            return statusCode >= 500
        case let .backend(code, _):
            return code == "ENDPOINT_NOT_IMPLEMENTED"
        default:
            return false
        }
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
