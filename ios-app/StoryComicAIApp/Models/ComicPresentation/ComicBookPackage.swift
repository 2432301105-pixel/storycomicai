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
