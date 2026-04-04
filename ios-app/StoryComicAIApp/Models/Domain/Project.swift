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
            return L10n.string("project.status.complete")
        case "free_preview_ready":
            return L10n.string("project.status.preview_ready")
        case "hero_preview_ready":
            return L10n.string("project.status.hero_ready")
        case "generating", "queued", "running":
            return L10n.string("project.status.in_production")
        default:
            return status.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var collectionSubtitle: String {
        let unlockLabel = isUnlocked ? L10n.string("project.unlock.unlocked") : L10n.string("project.unlock.preview")
        return L10n.string("project.collection_subtitle", style.displayName, unlockLabel)
    }
}
