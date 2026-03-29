import Foundation

struct ProjectResponseDTO: Codable, Identifiable {
    let id: UUID
    let title: String
    let style: StoryStyle
    let targetPages: Int
    let freePreviewPages: Int
    let status: String
    let isUnlocked: Bool
    let createdAtUTC: Date
    let updatedAtUTC: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case style
        case targetPages
        case freePreviewPages
        case status
        case isUnlocked
        case createdAtUTC = "createdAtUtc"
        case updatedAtUTC = "updatedAtUtc"
    }
}

struct ProjectListResponseDTO: Codable {
    let items: [ProjectResponseDTO]
    let nextCursor: String?
}
