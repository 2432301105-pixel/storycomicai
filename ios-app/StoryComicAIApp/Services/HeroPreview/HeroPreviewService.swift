import Foundation

protocol HeroPreviewService: AnyObject {
    func startHeroPreview(projectID: UUID, photoIDs: [UUID], style: StoryStyle?) async throws -> HeroPreviewJob
    func fetchHeroPreviewStatus(projectID: UUID, jobID: UUID) async throws -> HeroPreviewJob
}

final class DefaultHeroPreviewService: HeroPreviewService {
    private let apiClient: any APIClient

    init(apiClient: any APIClient) {
        self.apiClient = apiClient
    }

    func startHeroPreview(projectID: UUID, photoIDs: [UUID], style: StoryStyle?) async throws -> HeroPreviewJob {
        let endpoint = try HeroPreviewEndpoints.start(projectID: projectID, photoIDs: photoIDs, style: style)
        let dto = try await apiClient.request(endpoint, decode: HeroPreviewStartResponseDTO.self)

        return HeroPreviewJob(
            jobID: dto.jobID,
            projectID: projectID,
            status: HeroPreviewJob.Status(rawValue: dto.status) ?? .queued,
            currentStage: dto.currentStage,
            progressPercent: 0,
            previewAssets: nil,
            errorMessage: nil
        )
    }

    func fetchHeroPreviewStatus(projectID: UUID, jobID: UUID) async throws -> HeroPreviewJob {
        let endpoint = HeroPreviewEndpoints.status(projectID: projectID, jobID: jobID)
        let dto = try await apiClient.request(endpoint, decode: HeroPreviewStatusResponseDTO.self)

        let assets: HeroPreviewAssets?
        if let previewAssets = dto.result?.previewAssets {
            assets = HeroPreviewAssets(
                frontURL: previewAssets.front,
                threeQuarterURL: previewAssets.threeQuarter,
                sideURL: previewAssets.side
            )
        } else {
            assets = nil
        }

        return HeroPreviewJob(
            jobID: dto.jobID,
            projectID: dto.projectID,
            status: HeroPreviewJob.Status(rawValue: dto.status) ?? .failed,
            currentStage: dto.currentStage,
            progressPercent: dto.progressPct,
            previewAssets: assets,
            errorMessage: dto.errorMessage
        )
    }
}
