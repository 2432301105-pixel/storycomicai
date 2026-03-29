import Foundation

struct HeroPreviewStartResponseDTO: Codable {
    let jobID: UUID
    let status: String
    let currentStage: String

    enum CodingKeys: String, CodingKey {
        case jobID = "jobId"
        case status
        case currentStage
    }
}

struct HeroPreviewStatusResponseDTO: Codable {
    let jobID: UUID
    let projectID: UUID
    let status: String
    let currentStage: String
    let progressPct: Int
    let result: HeroPreviewResultDTO?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case jobID = "jobId"
        case projectID = "projectId"
        case status
        case currentStage
        case progressPct
        case result
        case errorMessage
    }
}

struct HeroPreviewResultDTO: Codable {
    let heroSheetVersion: Int
    let style: String
    let previewAssets: HeroPreviewAssetURLsDTO
    let consistencySeed: String
}

struct HeroPreviewAssetURLsDTO: Codable {
    let front: URL?
    let threeQuarter: URL?
    let side: URL?
}
