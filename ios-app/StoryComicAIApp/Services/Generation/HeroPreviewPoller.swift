import Foundation

final class HeroPreviewPoller {
    private let heroPreviewService: any HeroPreviewService

    init(heroPreviewService: any HeroPreviewService) {
        self.heroPreviewService = heroPreviewService
    }

    func poll(
        projectID: UUID,
        jobID: UUID,
        intervalSeconds: UInt64,
        onUpdate: @escaping @MainActor (HeroPreviewJob) -> Void
    ) async throws {
        while !Task.isCancelled {
            let status = try await heroPreviewService.fetchHeroPreviewStatus(projectID: projectID, jobID: jobID)
            await onUpdate(status)

            if status.status.isTerminal {
                break
            }

            try await Task.sleep(nanoseconds: intervalSeconds * 1_000_000_000)
        }
    }
}
