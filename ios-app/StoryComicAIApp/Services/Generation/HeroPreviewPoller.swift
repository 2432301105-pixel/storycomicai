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

final class ComicGenerationPoller {
    private let comicGenerationService: any ComicGenerationService

    init(comicGenerationService: any ComicGenerationService) {
        self.comicGenerationService = comicGenerationService
    }

    func poll(
        projectID: UUID,
        jobID: UUID,
        intervalSeconds: UInt64,
        onUpdate: @escaping @MainActor (ComicGenerationJob) -> Void
    ) async throws {
        while !Task.isCancelled {
            let status = try await comicGenerationService.fetchComicGenerationStatus(
                projectID: projectID,
                jobID: jobID
            )
            await onUpdate(status)

            if status.status.isTerminal {
                break
            }

            try await Task.sleep(nanoseconds: intervalSeconds * 1_000_000_000)
        }
    }
}
