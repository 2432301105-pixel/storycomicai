import Foundation

@MainActor
final class GenerationProgressViewModel: ObservableObject {
    @Published private(set) var steps: [GenerationPipelineStep] = []
    @Published private(set) var progress: Double = 0
    @Published private(set) var isComplete: Bool = false
    @Published private(set) var errorMessage: String?

    private let comicPackageService: any ComicPackageService
    private let projectID: UUID
    private var task: Task<Void, Never>?

    init(
        comicPackageService: any ComicPackageService,
        projectID: UUID
    ) {
        self.comicPackageService = comicPackageService
        self.projectID = projectID
    }

    func startIfNeeded() {
        guard task == nil else { return }

        task = Task { [weak self] in
            guard let self else { return }

            steps = [
                GenerationPipelineStep(title: "Story planner", status: .active),
                GenerationPipelineStep(title: "Character bible", status: .pending),
                GenerationPipelineStep(title: "Style guide", status: .pending),
                GenerationPipelineStep(title: "Panel prompts", status: .pending),
                GenerationPipelineStep(title: "Page composer", status: .pending)
            ]
            progress = 0.08
            errorMessage = nil

            do {
                let blueprint = try await comicPackageService.fetchGenerationBlueprint(projectID: projectID)
                let generatedSteps = self.makeSteps(from: blueprint)
                for index in generatedSteps.indices {
                    self.steps[index].status = .active
                    if index > 0 {
                        self.steps[index - 1].status = .completed
                    }
                    self.progress = min(0.92, Double(index + 1) / Double(max(generatedSteps.count + 1, 1)))
                    try? await Task.sleep(nanoseconds: 280_000_000)
                }
                if !self.steps.isEmpty {
                    self.steps[self.steps.count - 1].status = .completed
                }
                self.progress = 1
                self.isComplete = true
            } catch {
                for index in self.steps.indices {
                    if self.steps[index].status == .active {
                        self.steps[index].status = .failed
                        break
                    }
                }
                self.errorMessage = error.localizedDescription
                self.progress = 0
                self.isComplete = false
            }
        }
    }

    private func makeSteps(from blueprint: ComicGenerationBlueprint) -> [GenerationPipelineStep] {
        let referenceTitle = blueprint.referenceAssets.isEmpty ? "Reference taxonomy" : "Reference taxonomy (\(blueprint.referenceAssets.count))"
        let panelTitle = "Panel prompts (\(blueprint.panelRenders.count))"
        let pageTitle = "Page composer (\(blueprint.pages.count) pages)"
        return [
            GenerationPipelineStep(title: "Story planner (\(blueprint.storyPlan.beats.count) beats)", status: .pending),
            GenerationPipelineStep(title: "Character bible (\(blueprint.characterBible.codename))", status: .pending),
            GenerationPipelineStep(title: "Style guide (\(blueprint.styleGuide.displayLabel))", status: .pending),
            GenerationPipelineStep(title: referenceTitle, status: .pending),
            GenerationPipelineStep(title: panelTitle, status: .pending),
            GenerationPipelineStep(title: pageTitle, status: .pending)
        ]
    }

    deinit {
        task?.cancel()
    }
}
