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
        style: StoryStyle = .cinematic,
        source: ComicPackageSource = .mock
    ) -> ComicBookPackage {
        let title = coverTitle(for: style)
        let subtitle = coverSubtitle(for: style)
        let pageCount = 10
        let pages: [ComicPresentationPage] = (1...pageCount).map { pageNumber in
            ComicPresentationPage(
                id: UUID(),
                pageNumber: pageNumber,
                title: pageNumber == 1 ? "Cover" : "Chapter \(pageNumber - 1)",
                caption: pageCaption(for: pageNumber, style: style),
                thumbnailURL: URL(string: "https://mock.storycomicai.local/comic/\(projectID.uuidString)/thumb-\(pageNumber).jpg"),
                fullImageURL: URL(string: "https://mock.storycomicai.local/comic/\(projectID.uuidString)/full-\(pageNumber).jpg"),
                overlays: pageOverlays(for: pageNumber, style: style)
            )
        }

        return ComicBookPackage(
            projectID: projectID,
            title: title,
            subtitle: subtitle,
            styleLabel: style.displayName,
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
                revealSubheadline: "Built from your photos and the story you wrote.",
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
                subheadline: "Built from your photos and the story you wrote.",
                personalizationTag: "Hero Edition",
                generatedAtUTC: Date()
            ),
            source: source
        )
    }

    private static func coverTitle(for style: StoryStyle) -> String {
        switch style {
        case .manga:
            return "Night Runner"
        case .western:
            return "Dust & Thunder"
        case .cartoon:
            return "City of Giggles"
        case .cinematic:
            return "Shadow Protocol"
        case .childrensBook:
            return "Moonlight Parade"
        }
    }

    private static func coverSubtitle(for style: StoryStyle) -> String {
        switch style {
        case .manga:
            return "An ink-forward personalized hero edition"
        case .western:
            return "A collector issue drawn from your own story"
        case .cartoon:
            return "A bright, animated adventure starring you"
        case .cinematic:
            return "A personalized prestige-cover comic edition"
        case .childrensBook:
            return "A keepsake storybook built around your hero"
        }
    }

    private static func pageCaption(for pageNumber: Int, style: StoryStyle) -> String {
        switch style {
        case .manga:
            return "Ink and momentum carry the hero across page \(pageNumber)."
        case .western:
            return "The dust settles just long enough for the next turn on page \(pageNumber)."
        case .cartoon:
            return "Bold expressions and quick timing drive scene \(pageNumber)."
        case .cinematic:
            return "Generated scene \(pageNumber) stages your hero with prestige-cover pacing."
        case .childrensBook:
            return "A warm story beat unfolds gently on page \(pageNumber)."
        }
    }

    private static func pageOverlays(for pageNumber: Int, style: StoryStyle) -> [ComicPageTextOverlay] {
        switch pageNumber {
        case 1:
            return [
                ComicPageTextOverlay(
                    kind: .narration,
                    text: style.moodLabel,
                    normalizedX: 0.26,
                    normalizedY: 0.16,
                    normalizedWidth: 0.32,
                    tone: .accent
                ),
                ComicPageTextOverlay(
                    kind: .sfx,
                    text: style == .manga ? "SHHNK" : "RUSTLE",
                    normalizedX: 0.74,
                    normalizedY: 0.78,
                    normalizedWidth: 0.22,
                    tone: .inverse,
                    rotationDegrees: style == .manga ? -7 : -4,
                    emphasisScale: 1.12
                )
            ]
        case 2:
            return [
                ComicPageTextOverlay(
                    kind: .narration,
                    text: "The city opens like a printed legend.",
                    normalizedX: 0.28,
                    normalizedY: 0.14,
                    normalizedWidth: 0.44,
                    tone: .accent
                ),
                ComicPageTextOverlay(
                    kind: .speech,
                    text: "This is where the story starts.",
                    speaker: "Hero",
                    normalizedX: 0.73,
                    normalizedY: 0.30,
                    normalizedWidth: 0.34,
                    tone: .paper,
                    tailDirection: .left
                ),
                ComicPageTextOverlay(
                    kind: .thought,
                    text: "Stay sharp. Something's waiting ahead.",
                    normalizedX: 0.29,
                    normalizedY: 0.72,
                    normalizedWidth: 0.36,
                    tone: .paper,
                    tailDirection: .down
                )
            ]
        case 3:
            return [
                ComicPageTextOverlay(
                    kind: .speech,
                    text: style == .cartoon ? "You made it right on cue!" : "You're later than the rain.",
                    speaker: "Companion",
                    normalizedX: 0.24,
                    normalizedY: 0.34,
                    normalizedWidth: 0.34,
                    tone: .paper,
                    tailDirection: .right
                ),
                ComicPageTextOverlay(
                    kind: .speech,
                    text: "Then let's not waste the entrance.",
                    speaker: "Hero",
                    normalizedX: 0.73,
                    normalizedY: 0.58,
                    normalizedWidth: 0.32,
                    tone: .paper,
                    tailDirection: .left
                )
            ]
        case 4:
            return [
                ComicPageTextOverlay(
                    kind: .sfx,
                    text: style == .western ? "CLANG" : "THRUM",
                    normalizedX: 0.68,
                    normalizedY: 0.22,
                    normalizedWidth: 0.22,
                    tone: .inverse,
                    rotationDegrees: -10,
                    emphasisScale: 1.18
                ),
                ComicPageTextOverlay(
                    kind: .narration,
                    text: "Every panel tightens the promise.",
                    normalizedX: 0.33,
                    normalizedY: 0.82,
                    normalizedWidth: 0.42,
                    tone: .ink
                )
            ]
        default:
            return [
                ComicPageTextOverlay(
                    kind: .speech,
                    text: "Keep turning. The finished edition is yours.",
                    speaker: "Hero",
                    normalizedX: 0.67,
                    normalizedY: 0.28,
                    normalizedWidth: 0.34,
                    tone: .paper,
                    tailDirection: .left
                ),
                ComicPageTextOverlay(
                    kind: .narration,
                    text: "StoryComicAI personalizes each beat around the main character.",
                    normalizedX: 0.31,
                    normalizedY: 0.84,
                    normalizedWidth: 0.44,
                    tone: .accent
                )
            ]
        }
    }
}
