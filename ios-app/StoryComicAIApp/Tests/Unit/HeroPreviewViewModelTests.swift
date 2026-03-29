import XCTest
@testable import StoryComicAIApp

@MainActor
final class HeroPreviewViewModelTests: XCTestCase {
    func testStartIfNeededEventuallySetsSucceededState() async {
        let service = MockHeroPreviewServiceForTests()
        let projectID = UUID()
        let jobID = UUID()

        service.startResult = HeroPreviewJob(
            jobID: jobID,
            projectID: projectID,
            status: .queued,
            currentStage: "queued",
            progressPercent: 0,
            previewAssets: nil,
            errorMessage: nil
        )
        service.statusSequence = [
            HeroPreviewJob(
                jobID: jobID,
                projectID: projectID,
                status: .running,
                currentStage: "rendering_preview",
                progressPercent: 45,
                previewAssets: nil,
                errorMessage: nil
            ),
            HeroPreviewJob(
                jobID: jobID,
                projectID: projectID,
                status: .succeeded,
                currentStage: "completed",
                progressPercent: 100,
                previewAssets: nil,
                errorMessage: nil
            )
        ]

        let viewModel = HeroPreviewViewModel(heroPreviewService: service, pollingIntervalSeconds: 0)
        let flowStore = CreateProjectFlowStore()
        flowStore.createdProject = Project(
            id: projectID,
            title: "Test",
            style: .manga,
            targetPages: 12,
            freePreviewPages: 3,
            status: "draft",
            isUnlocked: false,
            createdAtUTC: Date(),
            updatedAtUTC: Date()
        )
        flowStore.uploadedPhotoIDs = [UUID()]

        viewModel.startIfNeeded(flowStore: flowStore)

        await AsyncTestHelpers.assertEventually {
            if case let .loaded(job) = viewModel.state {
                return job.status == .succeeded
            }
            return false
        }

        if case let .loaded(job) = viewModel.state {
            XCTAssertEqual(job.status, .succeeded)
            XCTAssertEqual(job.progressPercent, 100)
        } else {
            XCTFail("Expected loaded state")
        }
    }
}
