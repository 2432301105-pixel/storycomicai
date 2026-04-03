import Foundation

struct Project: Identifiable, Hashable {
    let id: UUID
    let title: String
    let storyText: String
    let style: StoryStyle
    let targetPages: Int
    let freePreviewPages: Int
    let status: String
    let isUnlocked: Bool
    let createdAtUTC: Date
    let updatedAtUTC: Date

    var statusDisplayName: String {
        switch status.lowercased() {
        case "completed":
            return "Complete"
        case "free_preview_ready":
            return "Preview Ready"
        case "hero_preview_ready":
            return "Hero Ready"
        case "generating", "queued", "running":
            return "In Production"
        default:
            return status.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var collectionSubtitle: String {
        let unlockLabel = isUnlocked ? "Unlocked" : "Preview"
        return "\(style.displayName) | \(unlockLabel)"
    }
}
