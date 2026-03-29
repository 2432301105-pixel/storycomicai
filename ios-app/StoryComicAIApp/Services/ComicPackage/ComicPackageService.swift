import Foundation

protocol ComicPackageService: AnyObject {
    func fetchComicBookPackage(projectID: UUID) async throws -> ComicBookPackage
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
            // Temporary compatibility path while backend contract rollout completes.
            if apiError.isContractFallbackEligible {
                return MockFixtures.sampleComicBookPackage(projectID: projectID, source: .fallback)
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

    func updateReadingProgress(
        projectID: UUID,
        currentPageIndex: Int,
        lastOpenedAtUTC: Date
    ) async throws -> ComicReadingProgress {
        _ = (projectID, lastOpenedAtUTC)
        return ComicReadingProgress(currentPageIndex: currentPageIndex, lastOpenedAtUTC: lastOpenedAtUTC)
    }
}

private extension ComicBookPackageResponseDTO {
    func toDomain(source: ComicPackageSource) -> ComicBookPackage {
        let defaultPackage = MockFixtures.sampleComicBookPackage(projectID: projectID, source: source)

        let mappedPages: [ComicPresentationPage] = pages.isEmpty
            ? defaultPackage.pages
            : pages.map { page in
                ComicPresentationPage(
                    id: page.id,
                    pageNumber: page.pageNumber,
                    title: page.title,
                    caption: page.caption,
                    thumbnailURL: page.thumbnailURL,
                    fullImageURL: page.fullImageURL
                )
            }

        let mappedHints = ComicPresentationHints(
            readingDirection: ComicPresentationHints.ReadingDirection(
                rawValue: presentationHints?.readingDirection ?? ""
            ) ?? defaultPackage.presentationHints.readingDirection,
            preferredRevealMode: presentationHints?.preferredRevealMode ?? defaultPackage.presentationHints.preferredRevealMode,
            deskTheme: ComicPresentationHints.DeskTheme(
                rawValue: presentationHints?.deskTheme ?? ""
            ) ?? defaultPackage.presentationHints.deskTheme,
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
            source: source
        )
    }
}

private extension APIError {
    var isContractFallbackEligible: Bool {
        switch self {
        case let .server(statusCode, _):
            return statusCode == 404 || statusCode == 409 || statusCode == 501
        case let .backend(code, _):
            return code == "ENDPOINT_NOT_IMPLEMENTED" || code == "NOT_FOUND"
        default:
            return false
        }
    }

    var isWriteBackFallbackEligible: Bool {
        if isContractFallbackEligible {
            return true
        }
        switch self {
        case .transport:
            return true
        case let .server(statusCode, _):
            return statusCode >= 500
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
