import Foundation

struct HeroPreviewStartRequestBody: Codable {
    let photoIDs: [UUID]
    let style: StoryStyle?

    enum CodingKeys: String, CodingKey {
        case photoIDs = "photoIds"
        case style
    }
}
