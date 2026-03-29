import Foundation

struct GenerationPipelineStep: Identifiable, Equatable {
    enum StepStatus: Equatable {
        case pending
        case active
        case completed
        case failed

        var title: String {
            switch self {
            case .pending: return "Pending"
            case .active: return "In Progress"
            case .completed: return "Done"
            case .failed: return "Failed"
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
        GenerationPipelineStep(title: "Story planning", status: .completed),
        GenerationPipelineStep(title: "Panel generation", status: .active),
        GenerationPipelineStep(title: "Dialogue layout", status: .pending),
        GenerationPipelineStep(title: "Final polish", status: .pending)
    ]
}
