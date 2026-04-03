import Foundation

struct ComicBookPackage: Identifiable, Equatable {
    let id: UUID
    let projectID: UUID
    let title: String
    let subtitle: String?
    let styleLabel: String
    let cover: ComicBookCover
    let pages: [ComicPresentationPage]
    let previewPageCount: Int
    let presentationHints: ComicPresentationHints
    let exportAvailability: ComicExportAvailability
    let paywallMetadata: ComicPaywallMetadata
    let ctaMetadata: ComicCTAMetadata
    let readingProgress: ComicReadingProgress
    // Temporary fallback while backend transitions away from reveal_metadata.
    let legacyRevealMetadata: ComicRevealMetadata?
    let generationBlueprint: ComicGenerationBlueprint?
    let source: ComicPackageSource

    init(
        projectID: UUID,
        title: String,
        subtitle: String?,
        styleLabel: String,
        cover: ComicBookCover,
        pages: [ComicPresentationPage],
        previewPageCount: Int,
        presentationHints: ComicPresentationHints,
        exportAvailability: ComicExportAvailability,
        paywallMetadata: ComicPaywallMetadata,
        ctaMetadata: ComicCTAMetadata,
        readingProgress: ComicReadingProgress,
        legacyRevealMetadata: ComicRevealMetadata?,
        generationBlueprint: ComicGenerationBlueprint?,
        source: ComicPackageSource
    ) {
        self.id = projectID
        self.projectID = projectID
        self.title = title
        self.subtitle = subtitle
        self.styleLabel = styleLabel
        self.cover = cover
        self.pages = pages
        self.previewPageCount = previewPageCount
        self.presentationHints = presentationHints
        self.exportAvailability = exportAvailability
        self.paywallMetadata = paywallMetadata
        self.ctaMetadata = ctaMetadata
        self.readingProgress = readingProgress
        self.legacyRevealMetadata = legacyRevealMetadata
        self.generationBlueprint = generationBlueprint
        self.source = source
    }
}

enum ComicPackageSource: String, Equatable {
    case remote
    case mock
    case fallback
}

struct ComicBookCover: Equatable {
    let imageURL: URL?
    let titleText: String?
    let subtitleText: String?
}

struct ComicPresentationPage: Identifiable, Equatable {
    let id: UUID
    let pageNumber: Int
    let title: String
    let caption: String?
    let thumbnailURL: URL?
    let fullImageURL: URL?
    let overlays: [ComicPageTextOverlay]
}

struct ComicPageTextOverlay: Identifiable, Equatable {
    enum Kind: String, Equatable {
        case speech
        case narration
        case thought
        case sfx
    }

    enum Tone: String, Equatable {
        case paper
        case ink
        case accent
        case inverse
    }

    enum TailDirection: String, Equatable {
        case left
        case right
        case down
    }

    let id: UUID
    let kind: Kind
    let text: String
    let speaker: String?
    let normalizedX: Double
    let normalizedY: Double
    let normalizedWidth: Double
    let tone: Tone
    let tailDirection: TailDirection?
    let rotationDegrees: Double
    let emphasisScale: Double

    init(
        id: UUID = UUID(),
        kind: Kind,
        text: String,
        speaker: String? = nil,
        normalizedX: Double,
        normalizedY: Double,
        normalizedWidth: Double = 0.34,
        tone: Tone = .paper,
        tailDirection: TailDirection? = nil,
        rotationDegrees: Double = 0,
        emphasisScale: Double = 1
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.speaker = speaker
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
        self.normalizedWidth = normalizedWidth
        self.tone = tone
        self.tailDirection = tailDirection
        self.rotationDegrees = rotationDegrees
        self.emphasisScale = emphasisScale
    }
}

struct ComicPresentationHints: Equatable {
    enum ReadingDirection: String, Equatable {
        case leftToRight = "left_to_right"
        case rightToLeft = "right_to_left"
    }

    enum DeskTheme: String, Equatable {
        case graphite
        case silver
        case walnut
    }

    let readingDirection: ReadingDirection
    let preferredRevealMode: Bool
    let deskTheme: DeskTheme
    let accentHex: String?
    let extra: [String: String]
}

struct ComicExportAvailability: Equatable {
    let isPDFAvailable: Bool
    let pdfURL: URL?
    let isImagePackAvailable: Bool
    let lockedByPaywall: Bool
}

struct ComicRevealMetadata: Equatable {
    let headline: String
    let subheadline: String?
    let personalizationTag: String?
    let generatedAtUTC: Date?
}

struct ComicPaywallMetadata: Equatable {
    let isUnlocked: Bool
    let lockReason: String?
    let offers: [ComicPaywallOffer]
}

struct ComicPaywallOffer: Equatable, Identifiable {
    let id: String
    let price: String
    let currency: String
    let priority: Int?
    let isRecommended: Bool?
    let badgeLabel: String?

    init(
        id: String,
        price: String,
        currency: String,
        priority: Int? = nil,
        isRecommended: Bool? = nil,
        badgeLabel: String? = nil
    ) {
        self.id = id
        self.price = price
        self.currency = currency
        self.priority = priority
        self.isRecommended = isRecommended
        self.badgeLabel = badgeLabel
    }
}

struct ComicCTAMetadata: Equatable {
    let revealHeadline: String?
    let revealSubheadline: String?
    let revealPrimaryLabel: String
    let revealSecondaryLabel: String
    let exportLabel: String
}

struct ComicReadingProgress: Equatable {
    let currentPageIndex: Int
    let lastOpenedAtUTC: Date?
}

struct ComicGenerationBlueprint: Equatable {
    let storyPlan: ComicStoryPlan
    let characterBible: ComicCharacterBible
    let styleGuide: ComicStyleGuide
    let referenceAssets: [ComicReferenceAsset]
    let pages: [ComicGenerationPage]
    let panelRenders: [ComicPanelRender]
    let qualitySignals: [ComicQualitySignal]
}

struct ComicStoryPlan: Equatable {
    let logline: String
    let tone: String
    let beats: [ComicStoryBeat]
}

struct ComicStoryBeat: Identifiable, Equatable {
    let id: String
    let title: String
    let summary: String
    let emotionalIntent: String
    let sceneType: String
    let panelCountHint: Int
    let keyMoment: String
}

struct ComicCharacterBible: Equatable {
    let codename: String
    let essence: String
    let physicalTraits: [String]
    let wardrobeKeywords: [String]
    let paletteHexes: [String]
    let silhouetteKeywords: [String]
    let continuityRules: [String]
    let sourcePhotoCount: Int
}

struct ComicStyleGuide: Equatable {
    let styleID: String
    let displayLabel: String
    let lineWeight: String
    let shading: String
    let framingRules: [String]
    let paletteNotes: [String]
    let bubbleLanguage: String
    let pageLayoutLanguage: String
}

struct ComicReferenceAsset: Identifiable, Equatable {
    let id: String
    let title: String
    let source: String
    let tags: ComicReferenceAssetTags
    let retrievalReason: String
    let usagePrompt: String
}

struct ComicReferenceAssetTags: Equatable {
    let style: String
    let shotType: String
    let sceneType: String
    let lighting: String
    let mood: String
    let environment: String?
    let characterPose: String?
    let panelDensity: String?
    let panelRole: String?
    let renderTraits: [String]
    let speechDensity: String?
}

struct ComicGenerationPage: Identifiable, Equatable {
    let id: String
    let pageNumber: Int
    let title: String
    let narrativePurpose: String
    let panelSpecs: [ComicGenerationPanelSpec]
}

struct ComicGenerationPanelSpec: Identifiable, Equatable {
    let id: String
    let beatID: String
    let pageNumber: Int
    let panelIndex: Int
    let shotType: String
    let environment: String?
    let mood: String
    let action: String
    let narration: String?
    let dialogue: String?
    let continuityNotes: [String]
    let referenceAssetIDs: [String]
    let renderPrompt: String
}

struct ComicPanelRender: Identifiable, Equatable {
    let id: String
    let pageNumber: Int
    let imageURL: URL?
    let thumbnailURL: URL?
    let caption: String?
    let dialogue: String?
    let renderPrompt: String
}

struct ComicQualitySignal: Equatable {
    let name: String
    let status: String
    let message: String
}
