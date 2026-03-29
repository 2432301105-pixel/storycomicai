import Foundation

@MainActor
final class GenerationProgressViewModel: ObservableObject {
    @Published private(set) var steps: [GenerationPipelineStep] = [
        GenerationPipelineStep(title: "Story planning", status: .pending),
        GenerationPipelineStep(title: "Panel generation", status: .pending),
        GenerationPipelineStep(title: "Dialogue layout", status: .pending),
        GenerationPipelineStep(title: "Final polish", status: .pending)
    ]
    @Published private(set) var progress: Double = 0
    @Published private(set) var isComplete: Bool = false

    private var task: Task<Void, Never>?

    func startIfNeeded() {
        guard task == nil else { return }

        task = Task { [weak self] in
            guard let self else { return }
            for index in steps.indices {
                steps[index].status = .active
                progress = Double(index) / Double(steps.count)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                steps[index].status = .completed
                progress = Double(index + 1) / Double(steps.count)
            }
            isComplete = true
        }
    }

    deinit {
        task?.cancel()
    }
}
