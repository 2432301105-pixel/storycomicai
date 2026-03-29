import Foundation

struct Project: Identifiable, Hashable {
    let id: UUID
    let title: String
    let style: StoryStyle
    let targetPages: Int
    let freePreviewPages: Int
    let status: String
    let isUnlocked: Bool
    let createdAtUTC: Date
    let updatedAtUTC: Date
}
