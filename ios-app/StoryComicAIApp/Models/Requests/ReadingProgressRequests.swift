import Foundation

struct ReadingProgressUpdateRequestBody: Codable {
    let currentPageIndex: Int
    let lastOpenedAtUTC: Date

    enum CodingKeys: String, CodingKey {
        case currentPageIndex
        case lastOpenedAtUTC = "lastOpenedAtUtc"
    }
}
