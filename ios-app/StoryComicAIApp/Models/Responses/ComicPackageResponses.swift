import Foundation

struct ComicBookPackageResponseDTO: Codable {
    let projectID: UUID
    let title: String
    let subtitle: String?
    let styleLabel: String?
    let cover: ComicCoverResponseDTO?
    let pages: [ComicPageResponseDTO]
    let previewPages: Int?
    let presentationHints: ComicPresentationHintsResponseDTO?
    let exportAvailability: ComicExportAvailabilityResponseDTO?
    let paywallMetadata: ComicPaywallMetadataResponseDTO?
    let readingProgress: ComicReadingProgressResponseDTO?
    let ctaMetadata: ComicCTAMetadataResponseDTO?
    let legacyRevealMetadata: ComicRevealMetadataResponseDTO?

    enum CodingKeys: String, CodingKey {
        case projectID = "projectId"
        case title
        case subtitle
        case styleLabel
        case cover
        case pages
        case previewPages
        case presentationHints
        case exportAvailability
        case paywallMetadata
        case readingProgress
        case ctaMetadata
        case legacyRevealMetadata
        case revealMetadata
    }

    init(
        projectID: UUID,
        title: String,
        subtitle: String?,
        styleLabel: String?,
        cover: ComicCoverResponseDTO?,
        pages: [ComicPageResponseDTO],
        previewPages: Int?,
        presentationHints: ComicPresentationHintsResponseDTO?,
        exportAvailability: ComicExportAvailabilityResponseDTO?,
        paywallMetadata: ComicPaywallMetadataResponseDTO?,
        readingProgress: ComicReadingProgressResponseDTO?,
        ctaMetadata: ComicCTAMetadataResponseDTO?,
        legacyRevealMetadata: ComicRevealMetadataResponseDTO?
    ) {
        self.projectID = projectID
        self.title = title
        self.subtitle = subtitle
        self.styleLabel = styleLabel
        self.cover = cover
        self.pages = pages
        self.previewPages = previewPages
        self.presentationHints = presentationHints
        self.exportAvailability = exportAvailability
        self.paywallMetadata = paywallMetadata
        self.readingProgress = readingProgress
        self.ctaMetadata = ctaMetadata
        self.legacyRevealMetadata = legacyRevealMetadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectID = try container.decode(UUID.self, forKey: .projectID)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        styleLabel = try container.decodeIfPresent(String.self, forKey: .styleLabel)
        cover = try container.decodeIfPresent(ComicCoverResponseDTO.self, forKey: .cover)
        pages = try container.decodeIfPresent([ComicPageResponseDTO].self, forKey: .pages) ?? []
        if let previewCount = try container.decodeIfPresent(Int.self, forKey: .previewPages) {
            previewPages = previewCount
        } else if let previewPageIDs = try container.decodeIfPresent([UUID].self, forKey: .previewPages) {
            previewPages = previewPageIDs.count
        } else if let previewPageNumbers = try container.decodeIfPresent([Int].self, forKey: .previewPages) {
            previewPages = previewPageNumbers.count
        } else {
            previewPages = nil
        }
        presentationHints = try container.decodeIfPresent(ComicPresentationHintsResponseDTO.self, forKey: .presentationHints)
        exportAvailability = try container.decodeIfPresent(ComicExportAvailabilityResponseDTO.self, forKey: .exportAvailability)
        paywallMetadata = try container.decodeIfPresent(ComicPaywallMetadataResponseDTO.self, forKey: .paywallMetadata)
        readingProgress = try container.decodeIfPresent(ComicReadingProgressResponseDTO.self, forKey: .readingProgress)
        ctaMetadata = try container.decodeIfPresent(ComicCTAMetadataResponseDTO.self, forKey: .ctaMetadata)
        legacyRevealMetadata = try container.decodeIfPresent(ComicRevealMetadataResponseDTO.self, forKey: .legacyRevealMetadata)
            ?? container.decodeIfPresent(ComicRevealMetadataResponseDTO.self, forKey: .revealMetadata)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectID, forKey: .projectID)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encodeIfPresent(styleLabel, forKey: .styleLabel)
        try container.encodeIfPresent(cover, forKey: .cover)
        try container.encode(pages, forKey: .pages)
        try container.encodeIfPresent(previewPages, forKey: .previewPages)
        try container.encodeIfPresent(presentationHints, forKey: .presentationHints)
        try container.encodeIfPresent(exportAvailability, forKey: .exportAvailability)
        try container.encodeIfPresent(paywallMetadata, forKey: .paywallMetadata)
        try container.encodeIfPresent(readingProgress, forKey: .readingProgress)
        try container.encodeIfPresent(ctaMetadata, forKey: .ctaMetadata)
        try container.encodeIfPresent(legacyRevealMetadata, forKey: .legacyRevealMetadata)
    }
}

struct ComicCoverResponseDTO: Codable {
    let imageURL: URL?
    let titleText: String?
    let subtitleText: String?
    let focalPoint: ComicPointResponseDTO?

    enum CodingKeys: String, CodingKey {
        case imageURL = "imageUrl"
        case titleText
        case subtitleText
        case focalPoint
    }
}

struct ComicPointResponseDTO: Codable {
    let x: Double
    let y: Double
}

struct ComicPageResponseDTO: Codable {
    let id: UUID
    let pageNumber: Int
    let title: String
    let caption: String?
    let thumbnailURL: URL?
    let fullImageURL: URL?
    let width: Int?
    let height: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case pageNumber
        case title
        case caption
        case thumbnailURL = "thumbnailUrl"
        case fullImageURL = "fullImageUrl"
        case width
        case height
    }
}

struct ComicPresentationHintsResponseDTO: Codable {
    let readingDirection: String?
    let preferredRevealMode: Bool?
    let deskTheme: String?
    let accentHex: String?
    let motionProfile: String?
    let extra: [String: String]?

    enum CodingKeys: String, CodingKey {
        case readingDirection
        case preferredRevealMode
        case deskTheme
        case accentHex
        case motionProfile
        case extra
    }
}

struct ComicExportAvailabilityResponseDTO: Codable {
    let isPDFAvailable: Bool?
    let pdfURL: URL?
    let isImagePackAvailable: Bool?
    let lockedByPaywall: Bool?

    enum CodingKeys: String, CodingKey {
        case isPDFAvailable
        case pdfURL = "pdfUrl"
        case isImagePackAvailable
        case lockedByPaywall
    }
}

struct ComicPaywallMetadataResponseDTO: Codable {
    let isUnlocked: Bool?
    let lockReason: String?
    let offers: [ComicPaywallOfferResponseDTO]?

    enum CodingKeys: String, CodingKey {
        case isUnlocked
        case lockReason
        case offers
    }
}

struct ComicPaywallOfferResponseDTO: Codable {
    let offerID: String?
    let price: String?
    let currency: String?
    let priority: Int?
    let isRecommended: Bool?
    let badgeLabel: String?

    enum CodingKeys: String, CodingKey {
        case offerID = "offerId"
        case price
        case currency
        case priority
        case isRecommended
        case badgeLabel
    }
}

struct ComicCTAMetadataResponseDTO: Codable {
    let revealHeadline: String?
    let revealSubheadline: String?
    let revealPrimaryLabel: String?
    let revealSecondaryLabel: String?
    let exportLabel: String?

    enum CodingKeys: String, CodingKey {
        case revealHeadline
        case revealSubheadline
        case revealPrimaryLabel
        case revealSecondaryLabel
        case exportLabel
    }
}

struct ComicRevealMetadataResponseDTO: Codable {
    let headline: String
    let subheadline: String?
    let personalizationTag: String?
    let generatedAtUTC: Date?

    enum CodingKeys: String, CodingKey {
        case headline
        case subheadline
        case personalizationTag
        case generatedAtUTC = "generatedAtUtc"
    }
}

struct ComicReadingProgressResponseDTO: Codable {
    let currentPageIndex: Int
    let lastOpenedAtUTC: Date?

    enum CodingKeys: String, CodingKey {
        case currentPageIndex
        case lastOpenedAtUTC = "lastOpenedAtUtc"
    }
}
