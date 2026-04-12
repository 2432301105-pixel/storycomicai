import Foundation

@MainActor
final class GenerationProgressViewModel: ObservableObject {
    @Published private(set) var steps: [GenerationPipelineStep] = []
    @Published private(set) var progress: Double = 0
    @Published private(set) var isComplete: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var currentStageTitle: String = L10n.string("generation.stage.queued")
    @Published private(set) var sceneBreakdown: [String] = []
    @Published private(set) var renderedPageSummary: [String] = []

    private let comicGenerationService: any ComicGenerationService
    private let comicPackageService: any ComicPackageService
    private let pollingIntervalSeconds: UInt64
    private let projectID: UUID
    private var task: Task<Void, Never>?

    init(
        comicGenerationService: any ComicGenerationService,
        comicPackageService: any ComicPackageService,
        pollingIntervalSeconds: UInt64,
        projectID: UUID
    ) {
        self.comicGenerationService = comicGenerationService
        self.comicPackageService = comicPackageService
        self.pollingIntervalSeconds = pollingIntervalSeconds
        self.projectID = projectID
        self.steps = Self.baseSteps()
    }

    func startIfNeeded(flowStore: CreateProjectFlowStore) {
        guard task == nil else { return }

        task = Task { [weak self] in
            guard let self else { return }
            await self.run(flowStore: flowStore)
        }
    }

    private func run(flowStore: CreateProjectFlowStore) async {
        errorMessage = nil
        isComplete = false

        do {
            let activeJob: ComicGenerationJob
            if let existingJob = flowStore.comicGenerationJob, existingJob.projectID == projectID {
                activeJob = existingJob
                apply(job: existingJob)
            } else {
                let startedJob = try await comicGenerationService.startComicGeneration(
                    projectID: projectID,
                    forceRegenerate: false
                )
                flowStore.comicGenerationJob = startedJob
                activeJob = startedJob
                apply(job: startedJob)
            }

            if activeJob.status.isTerminal {
                if activeJob.status == .succeeded {
                    await hydrateRenderedPages()
                }
                return
            }

            let poller = ComicGenerationPoller(comicGenerationService: comicGenerationService)
            try await poller.poll(
                projectID: projectID,
                jobID: activeJob.jobID,
                intervalSeconds: pollingIntervalSeconds
            ) { [weak self] status in
                guard let self else { return }
                flowStore.comicGenerationJob = status
                self.apply(job: status)
            }

            if flowStore.comicGenerationJob?.status == .succeeded {
                await hydrateRenderedPages()
            }
        } catch {
            // Generation never started (auth error, network error, etc.)
            // Don't mark any stage as failed — no stage ran.
            progress = 0
            errorMessage = (error as? APIError)?.userMessage ?? error.localizedDescription
            isComplete = false
        }
    }

    private func apply(job: ComicGenerationJob) {
        let blueprint = job.generationBlueprint
        steps = Self.makeSteps(from: blueprint, currentStage: job.currentStage, status: job.status)
        progress = max(0, min(1, Double(job.progressPercent) / 100.0))
        currentStageTitle = Self.displayTitle(for: job.currentStage)
        sceneBreakdown = Self.makeSceneBreakdown(from: blueprint)
        renderedPageSummary = Self.makeRenderedPageSummary(job: job, blueprint: blueprint)
        errorMessage = job.status == .failed ? (job.errorMessage ?? L10n.string("generation.error_failed")) : nil
        isComplete = job.status == .succeeded
    }

    private func hydrateRenderedPages() async {
        do {
            let package = try await comicPackageService.fetchComicBookPackage(projectID: projectID)
            let summaries = package.pages.prefix(max(1, min(4, package.pages.count))).map {
                L10n.string("generation.page_summary", $0.pageNumber, $0.title)
            }
            if !summaries.isEmpty {
                renderedPageSummary = summaries
            }
        } catch {
            // Preserve already rendered summaries from the status payload.
        }
    }

    private static func baseSteps() -> [GenerationPipelineStep] {
        [
            GenerationPipelineStep(title: L10n.string("generation.step.story_planner"), status: .pending),
            GenerationPipelineStep(title: L10n.string("generation.step.character_bible"), status: .pending),
            GenerationPipelineStep(title: L10n.string("generation.step.style_guide"), status: .pending),
            GenerationPipelineStep(title: L10n.string("generation.step.reference_taxonomy"), status: .pending),
            GenerationPipelineStep(title: L10n.string("generation.step.panel_prompts"), status: .pending),
            GenerationPipelineStep(title: L10n.string("generation.step.page_composer"), status: .pending),
        ]
    }

    private static func makeSteps(
        from blueprint: ComicGenerationBlueprint?,
        currentStage: String,
        status: ComicGenerationJob.Status
    ) -> [GenerationPipelineStep] {
        let referenceCount = blueprint?.referenceAssets.count ?? 0
        let panelCount = blueprint?.panelRenders.count ?? blueprint?.pages.flatMap(\.panelSpecs).count ?? 0
        let pageCount = blueprint?.pages.count ?? 0
        let steps = [
            GenerationPipelineStep(
                title: blueprint.map {
                    L10n.string("generation.step.story_planner_beats", $0.storyPlan.beats.count)
                } ?? L10n.string("generation.step.story_planner"),
                status: .pending
            ),
            GenerationPipelineStep(
                title: blueprint.map {
                    L10n.string("generation.step.character_bible_codename", $0.characterBible.codename)
                } ?? L10n.string("generation.step.character_bible"),
                status: .pending
            ),
            GenerationPipelineStep(
                title: blueprint.map {
                    L10n.string("generation.step.style_guide_label", $0.styleGuide.displayLabel)
                } ?? L10n.string("generation.step.style_guide"),
                status: .pending
            ),
            GenerationPipelineStep(
                title: referenceCount > 0
                    ? L10n.string("generation.step.reference_taxonomy_count", referenceCount)
                    : L10n.string("generation.step.reference_taxonomy"),
                status: .pending
            ),
            GenerationPipelineStep(
                title: panelCount > 0
                    ? L10n.string("generation.step.panel_prompts_count", panelCount)
                    : L10n.string("generation.step.panel_prompts"),
                status: .pending
            ),
            GenerationPipelineStep(
                title: pageCount > 0
                    ? L10n.string("generation.step.page_composer_count", pageCount)
                    : L10n.string("generation.step.page_composer"),
                status: .pending
            ),
        ]

        var updated = steps
        let stageIndex = stageOrder.firstIndex(of: normalizedStage(currentStage))

        if status == .succeeded {
            for index in updated.indices {
                updated[index].status = .completed
            }
            return updated
        }

        if status == .failed {
            return markFailed(steps: updated, currentStage: currentStage)
        }

        guard let stageIndex else {
            if !updated.isEmpty {
                updated[0].status = status == .queued ? .pending : .active
            }
            return updated
        }

        for index in updated.indices {
            if index < stageIndex {
                updated[index].status = .completed
            } else if index == stageIndex {
                updated[index].status = status == .queued ? .pending : .active
            } else {
                updated[index].status = .pending
            }
        }
        return updated
    }

    private static func markFailed(steps: [GenerationPipelineStep], currentStage: String?) -> [GenerationPipelineStep] {
        var updated = steps
        guard let currentStage else {
            if let firstIndex = updated.indices.first {
                updated[firstIndex].status = .failed
            }
            return updated
        }

        let stageIndex = stageOrder.firstIndex(of: normalizedStage(currentStage)) ?? 0
        for index in updated.indices {
            if index < stageIndex {
                updated[index].status = .completed
            } else if index == stageIndex {
                updated[index].status = .failed
            } else {
                updated[index].status = .pending
            }
        }
        return updated
    }

    private static func makeSceneBreakdown(from blueprint: ComicGenerationBlueprint?) -> [String] {
        guard let blueprint else { return [] }
        return blueprint.storyPlan.beats.prefix(4).map {
            "\($0.title) • \($0.summary)"
        }
    }

    private static func makeRenderedPageSummary(
        job: ComicGenerationJob,
        blueprint: ComicGenerationBlueprint?
    ) -> [String] {
        guard let blueprint else { return [] }

        let renderedCount = max(job.renderedPagesCount, job.status == .succeeded ? blueprint.pages.count : 0)
        if renderedCount > 0 {
            return blueprint.pages.prefix(renderedCount).map {
                L10n.string("generation.page_summary", $0.pageNumber, $0.title)
            }
        }

        return blueprint.pages.prefix(2).map {
            L10n.string("generation.preparing_page_summary", $0.pageNumber, $0.title)
        }
    }

    private static func displayTitle(for stage: String) -> String {
        switch normalizedStage(stage) {
        case "story_planner": return L10n.string("generation.stage.story_planner")
        case "character_bible": return L10n.string("generation.stage.character_bible")
        case "style_guide": return L10n.string("generation.stage.style_guide")
        case "reference_taxonomy": return L10n.string("generation.stage.reference_taxonomy")
        case "panel_prompts": return L10n.string("generation.stage.panel_prompts")
        case "page_composer": return L10n.string("generation.stage.page_composer")
        case "completed": return L10n.string("generation.stage.completed")
        case "failed": return L10n.string("generation.stage.failed")
        default: return L10n.string("generation.stage.queued")
        }
    }

    private static func normalizedStage(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
    }

    private static let stageOrder = [
        "story_planner",
        "character_bible",
        "style_guide",
        "reference_taxonomy",
        "panel_prompts",
        "page_composer",
    ]

    deinit {
        task?.cancel()
    }
}
