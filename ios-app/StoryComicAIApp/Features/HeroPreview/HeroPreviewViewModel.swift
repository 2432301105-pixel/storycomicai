import Foundation

@MainActor
final class HeroPreviewViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<HeroPreviewJob> = .idle
    @Published private(set) var isStarting: Bool = false

    private let heroPreviewService: any HeroPreviewService
    private let pollingIntervalSeconds: UInt64
    private let poller: HeroPreviewPoller
    private let pollingController = PollingTaskController()

    init(heroPreviewService: any HeroPreviewService, pollingIntervalSeconds: UInt64) {
        self.heroPreviewService = heroPreviewService
        self.pollingIntervalSeconds = pollingIntervalSeconds
        self.poller = HeroPreviewPoller(heroPreviewService: heroPreviewService)
    }

    func startIfNeeded(flowStore: CreateProjectFlowStore) {
        guard case .idle = state else { return }
        Task { await start(flowStore: flowStore) }
    }

    func retry(flowStore: CreateProjectFlowStore) {
        pollingController.stop()
        state = .idle
        Task { await start(flowStore: flowStore) }
    }

    private func start(flowStore: CreateProjectFlowStore) async {
        guard let projectID = flowStore.createdProject?.id else {
            state = .failed("Project is not ready.")
            return
        }
        guard !flowStore.uploadedPhotoIDs.isEmpty else {
            state = .failed("Upload photos before starting hero preview.")
            return
        }

        isStarting = true
        state = .loading
        defer { isStarting = false }

        do {
            let started = try await heroPreviewService.startHeroPreview(
                projectID: projectID,
                photoIDs: flowStore.uploadedPhotoIDs,
                style: flowStore.selectedStyle
            )
            flowStore.heroPreviewJob = started
            state = .loaded(started)

            pollingController.start { [weak self] in
                guard let self else { return }
                do {
                    try await self.poller.poll(
                        projectID: projectID,
                        jobID: started.jobID,
                        intervalSeconds: self.pollingIntervalSeconds
                    ) { [weak self] status in
                        guard let self else { return }
                        flowStore.heroPreviewJob = status
                        self.state = .loaded(status)
                    }
                } catch {
                    self.state = .failed(error.userFacingMessage)
                }
            }
        } catch {
            state = .failed(error.userFacingMessage)
        }
    }

}
