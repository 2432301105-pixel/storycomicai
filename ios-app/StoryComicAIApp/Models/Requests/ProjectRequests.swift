import Foundation

struct CreateProjectRequestBody: Codable {
    let title: String
    let style: StoryStyle
    let targetPages: Int
}
