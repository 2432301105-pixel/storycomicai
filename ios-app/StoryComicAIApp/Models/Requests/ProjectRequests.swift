import Foundation

struct CreateProjectRequestBody: Codable {
    let title: String
    let storyText: String
    let style: StoryStyle
    let targetPages: Int
}

struct ComicGenerationStartRequestBody: Codable {
    let forceRegenerate: Bool
}
