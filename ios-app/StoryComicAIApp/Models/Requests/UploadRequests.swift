import Foundation

struct PhotoPresignRequestBody: Codable {
    let filename: String
    let mimeType: String
    let sizeBytes: Int
}

struct PhotoCompleteRequestBody: Codable {
    let photoID: UUID
    let width: Int
    let height: Int
    let isPrimary: Bool

    enum CodingKeys: String, CodingKey {
        case photoID = "photoId"
        case width
        case height
        case isPrimary
    }
}
