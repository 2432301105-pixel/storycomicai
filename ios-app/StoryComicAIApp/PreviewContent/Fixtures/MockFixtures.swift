import Foundation

enum MockFixtures {
    static func samplePhotos() -> [LocalPhotoAsset] {
        [
            LocalPhotoAsset(
                filename: "hero_primary.jpg",
                data: Data(repeating: 0xA1, count: 120_000)
            ),
            LocalPhotoAsset(
                filename: "hero_secondary.jpg",
                data: Data(repeating: 0xB2, count: 110_000)
            )
        ]
    }

    static func sampleProjects() -> [Project] {
        let now = Date()
        return [
            Project(
                id: UUID(),
                title: "Night Runner",
                style: .manga,
                targetPages: 12,
                freePreviewPages: 3,
                status: "free_preview_ready",
                isUnlocked: false,
                createdAtUTC: now,
                updatedAtUTC: now
            ),
            Project(
                id: UUID(),
                title: "Parallel Hearts",
                style: .cinematic,
                targetPages: 16,
                freePreviewPages: 3,
                status: "completed",
                isUnlocked: true,
                createdAtUTC: now.addingTimeInterval(-3600 * 24),
                updatedAtUTC: now
            )
        ]
    }

    static func sampleComicPages() -> [ComicPage] {
        [
            ComicPage(pageNumber: 1, title: "Cover", caption: "Shadow of the City"),
            ComicPage(pageNumber: 2, title: "Arrival", caption: "The night starts with a whisper."),
            ComicPage(pageNumber: 3, title: "Clue", caption: "A hidden sign appears in the rain.")
        ]
    }

    static func sampleComicBookPackage(
        projectID: UUID,
        source: ComicPackageSource = .mock
    ) -> ComicBookPackage {
        let title = "Shadow Protocol"
        let subtitle = "A personalized night-runner saga"
        let pageCount = 10
        let pages: [ComicPresentationPage] = (1...pageCount).map { pageNumber in
            ComicPresentationPage(
                id: UUID(),
                pageNumber: pageNumber,
                title: pageNumber == 1 ? "Cover" : "Chapter \(pageNumber - 1)",
                caption: "Generated scene \(pageNumber) with personalized hero identity.",
                thumbnailURL: URL(string: "https://mock.storycomicai.local/comic/\(projectID.uuidString)/thumb-\(pageNumber).jpg"),
                fullImageURL: URL(string: "https://mock.storycomicai.local/comic/\(projectID.uuidString)/full-\(pageNumber).jpg")
            )
        }

        return ComicBookPackage(
            projectID: projectID,
            title: title,
            subtitle: subtitle,
            styleLabel: StoryStyle.manga.displayName,
            cover: ComicBookCover(
                imageURL: URL(string: "https://mock.storycomicai.local/comic/\(projectID.uuidString)/cover.jpg"),
                titleText: title,
                subtitleText: subtitle
            ),
            pages: pages,
            previewPageCount: 3,
            presentationHints: ComicPresentationHints(
                readingDirection: .leftToRight,
                preferredRevealMode: true,
                deskTheme: .graphite,
                accentHex: "9AA4B2",
                extra: [
                    "camera_language": "cinematic_closeups",
                    "panel_density": "medium"
                ]
            ),
            exportAvailability: ComicExportAvailability(
                isPDFAvailable: true,
                pdfURL: nil,
                isImagePackAvailable: true,
                lockedByPaywall: false
            ),
            paywallMetadata: ComicPaywallMetadata(
                isUnlocked: true,
                lockReason: nil,
                offers: [
                    ComicPaywallOffer(id: "unlock_full", price: "7.99", currency: "USD")
                ]
            ),
            ctaMetadata: ComicCTAMetadata(
                revealHeadline: "Your Personalized Comic Is Ready",
                revealSubheadline: "Built from your photos and story prompt.",
                revealPrimaryLabel: "Open Book",
                revealSecondaryLabel: "Open Reader",
                exportLabel: "Export"
            ),
            readingProgress: ComicReadingProgress(
                currentPageIndex: 0,
                lastOpenedAtUTC: nil
            ),
            legacyRevealMetadata: ComicRevealMetadata(
                headline: "Your Personalized Comic Is Ready",
                subheadline: "Built from your photos and story prompt.",
                personalizationTag: "Hero Edition",
                generatedAtUTC: Date()
            ),
            source: source
        )
    }
}
