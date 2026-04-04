import Foundation

struct HeroPreviewJob: Equatable {
    enum Status: String {
        case queued
        case running
        case succeeded
        case failed

        var isTerminal: Bool {
            self == .succeeded || self == .failed
        }

        var displayTitle: String {
            switch self {
            case .queued: return L10n.string("hero_status.queued")
            case .running: return L10n.string("hero_status.running")
            case .succeeded: return L10n.string("hero_status.succeeded")
            case .failed: return L10n.string("hero_status.failed")
            }
        }
    }

    let jobID: UUID
    let projectID: UUID
    let status: Status
    let currentStage: String
    let progressPercent: Int
    let previewAssets: HeroPreviewAssets?
    let errorMessage: String?
}

struct HeroPreviewAssets: Equatable {
    let frontURL: URL?
    let threeQuarterURL: URL?
    let sideURL: URL?
}
