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
                storyText: "A lone courier races through a neon city after discovering a conspiracy hidden inside the overnight dispatch route.",
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
                storyText: "Two strangers keep meeting across the same city on the night every timeline begins to split apart.",
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
        let storyText = sampleStoryText(for: style)
        let generationBlueprint = sampleGenerationBlueprint(
            projectID: projectID,
            style: style,
            storyText: storyText
        )
        let pageCount = 10
        let pages: [ComicPresentationPage] = (1...pageCount).map { pageNumber in
            let generatedRender = generationBlueprint.panelRenders.first { $0.pageNumber == pageNumber }
            return ComicPresentationPage(
                id: UUID(),
                pageNumber: pageNumber,
                title: pageNumber == 1 ? "Cover" : "Chapter \(pageNumber - 1)",
                caption: pageCaption(for: pageNumber, style: style),
                thumbnailURL: generatedRender?.thumbnailURL ?? URL(string: "https://mock.storycomicai.local/comic/\(projectID.uuidString)/thumb-\(pageNumber).jpg"),
                fullImageURL: generatedRender?.imageURL ?? URL(string: "https://mock.storycomicai.local/comic/\(projectID.uuidString)/full-\(pageNumber).jpg"),
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
            generationBlueprint: generationBlueprint,
            source: source
        )
    }

    static func sampleGenerationBlueprint(
        projectID: UUID,
        style: StoryStyle = .cinematic,
        storyText: String
    ) -> ComicGenerationBlueprint {
        let codename = coverTitle(for: style)
        let beatTitles = [
            "Opening Mystery",
            "First Encounter",
            "The Hidden Pattern",
            "Escalation",
            "Midnight Promise",
            "Climax"
        ]
        let panelSpecs: [ComicGenerationPanelSpec] = beatTitles.enumerated().flatMap { index, beatTitle in
            let pageNumber = index + 1
            return [
                ComicGenerationPanelSpec(
                    id: "page-\(pageNumber)-panel-1",
                    beatID: "beat-\(pageNumber)",
                    pageNumber: pageNumber,
                    panelIndex: 1,
                    shotType: index == 0 ? "establishing" : "medium",
                    environment: style == .western ? "frontier town" : "neon city",
                    mood: style.moodLabel.lowercased(),
                    action: "\(beatTitle) framed as the first visual beat of the page.",
                    narration: storyText.storyLines[safe: index]?.prefix(90).description,
                    dialogue: nil,
                    continuityNotes: [
                        "Keep the hero silhouette consistent across every panel.",
                        "Preserve the \(style.displayName.lowercased()) rendering language."
                    ],
                    referenceAssetIDs: ["\(style.rawValue)-ref-\(pageNumber)-1"],
                    renderPrompt: "\(style.displayName) comic panel, \(beatTitle.lowercased()), dramatic composition, main character centered, readable comic composition"
                ),
                ComicGenerationPanelSpec(
                    id: "page-\(pageNumber)-panel-2",
                    beatID: "beat-\(pageNumber)",
                    pageNumber: pageNumber,
                    panelIndex: 2,
                    shotType: "close_up",
                    environment: style == .childrensBook ? "storybook street" : "story scene",
                    mood: index >= 3 ? "tense" : "hopeful",
                    action: "Close-up reaction panel that lands the page emotion.",
                    narration: nil,
                    dialogue: index.isMultiple(of: 2) ? "Then the next move has to be precise." : "We only get one chance at this.",
                    continuityNotes: [
                        "Face shape, wardrobe, and palette must stay locked.",
                        "Panel should connect directly to the previous shot."
                    ],
                    referenceAssetIDs: ["\(style.rawValue)-ref-\(pageNumber)-2"],
                    renderPrompt: "\(style.displayName) comic close-up, emotional beat, strong facial acting, cinematic comic lighting"
                )
            ]
        }

        let pages: [ComicGenerationPage] = beatTitles.enumerated().map { index, beatTitle in
            let pageNumber = index + 1
            return ComicGenerationPage(
                id: "page-\(pageNumber)",
                pageNumber: pageNumber,
                title: beatTitle,
                narrativePurpose: index == 0 ? "Establish the hero, world, and problem." : "Advance the story beat with clear comic pacing.",
                panelSpecs: panelSpecs.filter { $0.pageNumber == pageNumber }
            )
        }

        let panelRenders: [ComicPanelRender] = pages.map { page in
            ComicPanelRender(
                id: "render-\(page.id)",
                pageNumber: page.pageNumber,
                imageURL: URL(string: "https://mock.storycomicai.local/comic/\(projectID.uuidString)/page-\(page.pageNumber).jpg"),
                thumbnailURL: URL(string: "https://mock.storycomicai.local/comic/\(projectID.uuidString)/thumb-\(page.pageNumber).jpg"),
                caption: storyText.storyLines[safe: page.pageNumber - 1] ?? page.narrativePurpose,
                dialogue: page.panelSpecs.last?.dialogue,
                renderPrompt: page.panelSpecs.map(\.renderPrompt).joined(separator: " | ")
            )
        }

        return ComicGenerationBlueprint(
            storyPlan: ComicStoryPlan(
                logline: storyText.storyLines.first ?? "A personalized comic adventure built from your story.",
                tone: style.editorialBlurb,
                beats: beatTitles.enumerated().map { index, beatTitle in
                    ComicStoryBeat(
                        id: "beat-\(index + 1)",
                        title: beatTitle,
                        summary: storyText.storyLines[safe: index] ?? "Story beat \(index + 1)",
                        emotionalIntent: index < 2 ? "Curiosity" : index < 4 ? "Tension" : "Resolve",
                        sceneType: index == 0 ? "reveal" : index == beatTitles.count - 1 ? "climax" : "dialogue",
                        panelCountHint: 2,
                        keyMoment: "Key visual beat for \(beatTitle.lowercased())"
                    )
                }
            ),
            characterBible: ComicCharacterBible(
                codename: codename,
                essence: "A hero shaped by the user's story and anchored to a premium comic silhouette.",
                physicalTraits: ["heroic jawline", "expressive eyes", "clear silhouette"],
                wardrobeKeywords: ["signature outerwear", "story-specific accent color", style.displayName.lowercased()],
                paletteHexes: [style.accentHex, "F4F1EA", "1A1714"],
                silhouetteKeywords: ["confident stance", "recognizable profile", "graphic shape language"],
                continuityRules: [
                    "Keep the face, hair, and costume family consistent.",
                    "Never drift away from the chosen \(style.displayName.lowercased()) language."
                ],
                sourcePhotoCount: 2
            ),
            styleGuide: ComicStyleGuide(
                styleID: style.rawValue,
                displayLabel: style.displayName,
                lineWeight: style == .manga ? "ink-heavy" : "clean-medium",
                shading: style == .cartoon ? "flat cel shading" : "soft comic shading",
                framingRules: ["Lead with a strong opener.", "Alternate wide context with emotional close-up."],
                paletteNotes: ["Accent with \(style.moodLabel.lowercased()) energy.", "Keep the paper tone visible."],
                bubbleLanguage: style == .western ? "bold pulp" : "premium comic dialogue",
                pageLayoutLanguage: "two-panel prestige layout"
            ),
            referenceAssets: [
                ComicReferenceAsset(
                    id: "\(style.rawValue)-ref-1-1",
                    title: "\(style.displayName) establishing mood",
                    source: "manual_moodboard",
                    tags: ComicReferenceAssetTags(
                        style: style.rawValue,
                        shotType: "establishing",
                        sceneType: "reveal",
                        lighting: style == .cinematic ? "neon night" : "graphic spotlight",
                        mood: "mysterious",
                        environment: "city",
                        characterPose: "standing_heroic",
                        panelDensity: "medium",
                        panelRole: "opener",
                        renderTraits: ["comic", "editorial", "premium"],
                        speechDensity: "light"
                    ),
                    retrievalReason: "Matches the chosen style and opening beat.",
                    usagePrompt: "Use as abstract guidance for framing and tone, not as a copied composition."
                )
            ],
            pages: pages,
            panelRenders: panelRenders,
            qualitySignals: [
                ComicQualitySignal(name: "story_planner", status: "planned", message: "Story beats are synchronized to page order."),
                ComicQualitySignal(name: "character_bible", status: "locked", message: "Core silhouette and palette are anchored for consistency."),
                ComicQualitySignal(name: "page_composer", status: "planned", message: "Panel density and reading order are resolved for comic layout.")
            ]
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

    private static func sampleStoryText(for style: StoryStyle) -> String {
        switch style {
        case .manga:
            return "A courier discovers that every delivery note predicts the next disaster in the city. To stop the final one, the courier becomes the masked runner the headlines fear."
        case .western:
            return "A lone rider returns to a frontier town carrying proof that the railroad bought every badge in the county. The last honest stand begins at sundown."
        case .cartoon:
            return "A quick-thinking hero turns a citywide mix-up into a race across rooftops, parades, and impossible escapes before the mayor's celebration begins."
        case .cinematic:
            return "When encrypted signals start appearing in the midnight rain, one investigator realizes the city has been staging its own cover-up for years. The only way out is through the story at the center of it."
        case .childrensBook:
            return "A brave child follows a moonlit map through the sleeping town and learns that every small act of courage can light the way for someone else."
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

private extension String {
    var storyLines: [String] {
        split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
