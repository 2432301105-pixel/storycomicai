import Foundation

struct PhotoPresignResponseDTO: Codable {
    let photoID: UUID
    let uploadURL: URL
    let storageKey: String
    let expiresInSeconds: Int

    enum CodingKeys: String, CodingKey {
        case photoID = "photoId"
        case uploadURL = "uploadUrl"
        case storageKey
        case expiresInSeconds
    }
}

struct PhotoCompleteResponseDTO: Codable {
    let photoID: UUID
    let status: String
    let qualityScore: Double?

    enum CodingKeys: String, CodingKey {
        case photoID = "photoId"
        case status
        case qualityScore
    }
}
