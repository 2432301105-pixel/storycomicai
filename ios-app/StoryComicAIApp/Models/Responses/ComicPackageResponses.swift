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
    let generationBlueprint: ComicGenerationBlueprintResponseDTO?

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
        case generationBlueprint
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
        legacyRevealMetadata: ComicRevealMetadataResponseDTO?,
        generationBlueprint: ComicGenerationBlueprintResponseDTO?
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
        self.generationBlueprint = generationBlueprint
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
        generationBlueprint = try container.decodeIfPresent(ComicGenerationBlueprintResponseDTO.self, forKey: .generationBlueprint)
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
        try container.encodeIfPresent(generationBlueprint, forKey: .generationBlueprint)
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

struct ComicGenerationBlueprintResponseDTO: Codable {
    let storyPlan: ComicStoryPlanResponseDTO
    let characterBible: ComicCharacterBibleResponseDTO
    let styleGuide: ComicStyleGuideResponseDTO
    let referenceAssets: [ComicReferenceAssetResponseDTO]
    let pages: [ComicGenerationPageResponseDTO]
    let panelRenders: [ComicPanelRenderResponseDTO]
    let qualitySignals: [ComicQualitySignalResponseDTO]
}

struct ComicStoryPlanResponseDTO: Codable {
    let logline: String
    let tone: String
    let beats: [ComicStoryBeatResponseDTO]
}

struct ComicStoryBeatResponseDTO: Codable {
    let beatID: String
    let title: String
    let summary: String
    let emotionalIntent: String
    let sceneType: String
    let panelCountHint: Int
    let keyMoment: String

    enum CodingKeys: String, CodingKey {
        case beatID = "beatId"
        case title
        case summary
        case emotionalIntent
        case sceneType
        case panelCountHint
        case keyMoment
    }
}

struct ComicCharacterBibleResponseDTO: Codable {
    let codename: String
    let essence: String
    let physicalTraits: [String]
    let wardrobeKeywords: [String]
    let paletteHexes: [String]
    let silhouetteKeywords: [String]
    let continuityRules: [String]
    let sourcePhotoCount: Int
}

struct ComicStyleGuideResponseDTO: Codable {
    let styleID: String
    let displayLabel: String
    let lineWeight: String
    let shading: String
    let framingRules: [String]
    let paletteNotes: [String]
    let bubbleLanguage: String
    let pageLayoutLanguage: String

    enum CodingKeys: String, CodingKey {
        case styleID = "styleId"
        case displayLabel
        case lineWeight
        case shading
        case framingRules
        case paletteNotes
        case bubbleLanguage
        case pageLayoutLanguage
    }
}

struct ComicReferenceAssetResponseDTO: Codable {
    let assetID: String
    let title: String
    let source: String
    let tags: ComicReferenceAssetTagsResponseDTO
    let retrievalReason: String
    let usagePrompt: String

    enum CodingKeys: String, CodingKey {
        case assetID = "assetId"
        case title
        case source
        case tags
        case retrievalReason
        case usagePrompt
    }
}

struct ComicReferenceAssetTagsResponseDTO: Codable {
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

struct ComicGenerationPageResponseDTO: Codable {
    let pageNumber: Int
    let title: String
    let narrativePurpose: String
    let panelSpecs: [ComicGenerationPanelSpecResponseDTO]
}

struct ComicGenerationPanelSpecResponseDTO: Codable {
    let panelID: String
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

    enum CodingKeys: String, CodingKey {
        case panelID = "panelId"
        case beatID = "beatId"
        case pageNumber
        case panelIndex
        case shotType
        case environment
        case mood
        case action
        case narration
        case dialogue
        case continuityNotes
        case referenceAssetIDs = "referenceAssetIds"
        case renderPrompt
    }
}

struct ComicPanelRenderResponseDTO: Codable {
    let panelID: String
    let pageNumber: Int
    let imageURL: URL?
    let thumbnailURL: URL?
    let caption: String?
    let dialogue: String?
    let renderPrompt: String

    enum CodingKeys: String, CodingKey {
        case panelID = "panelId"
        case pageNumber
        case imageURL = "imageUrl"
        case thumbnailURL = "thumbnailUrl"
        case caption
        case dialogue
        case renderPrompt
    }
}

struct ComicGenerationStartResponseDTO: Codable {
    let jobID: UUID
    let projectID: UUID
    let status: String
    let currentStage: String
    let progressPct: Int
    let generationBlueprint: ComicGenerationBlueprintResponseDTO?
    let renderedPagesCount: Int
    let renderedPanelsCount: Int
    let providerName: String?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case jobID = "jobId"
        case projectID = "projectId"
        case status
        case currentStage
        case progressPct
        case generationBlueprint
        case renderedPagesCount
        case renderedPanelsCount
        case providerName
        case errorMessage
    }
}

struct ComicGenerationStatusResponseDTO: Codable {
    let jobID: UUID
    let projectID: UUID
    let status: String
    let currentStage: String
    let progressPct: Int
    let generationBlueprint: ComicGenerationBlueprintResponseDTO?
    let renderedPagesCount: Int
    let renderedPanelsCount: Int
    let providerName: String?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case jobID = "jobId"
        case projectID = "projectId"
        case status
        case currentStage
        case progressPct
        case generationBlueprint
        case renderedPagesCount
        case renderedPanelsCount
        case providerName
        case errorMessage
    }
}

struct ComicQualitySignalResponseDTO: Codable {
    let name: String
    let status: String
    let message: String
}
