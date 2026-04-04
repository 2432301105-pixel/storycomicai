import Foundation

struct GenerationPipelineStep: Identifiable, Equatable {
    enum StepStatus: Equatable {
        case pending
        case active
        case completed
        case failed

        var title: String {
            switch self {
            case .pending: return L10n.string("step.pending")
            case .active: return L10n.string("step.active")
            case .completed: return L10n.string("step.completed")
            case .failed: return L10n.string("step.failed")
            }
        }
    }

    let id: UUID
    let title: String
    var status: StepStatus

    init(id: UUID = UUID(), title: String, status: StepStatus) {
        self.id = id
        self.title = title
        self.status = status
    }

    static let previewSteps: [GenerationPipelineStep] = [
        GenerationPipelineStep(title: L10n.string("generation.step.story_planner"), status: .completed),
        GenerationPipelineStep(title: L10n.string("generation.step.panel_prompts"), status: .active),
        GenerationPipelineStep(title: L10n.string("generation.scene_breakdown"), status: .pending),
        GenerationPipelineStep(title: L10n.string("generation.stage.completed"), status: .pending)
    ]
}

struct ComicGenerationJob: Equatable {
    enum Status: String, Equatable {
        case queued
        case running
        case succeeded
        case failed

        var isTerminal: Bool {
            self == .succeeded || self == .failed
        }
    }

    let jobID: UUID
    let projectID: UUID
    let status: Status
    let currentStage: String
    let progressPercent: Int
    let generationBlueprint: ComicGenerationBlueprint?
    let renderedPagesCount: Int
    let renderedPanelsCount: Int
    let providerName: String?
    let errorMessage: String?
}
