import XCTest
@testable import StoryComicAIApp

final class ExportPollerTests: XCTestCase {
    func testPollRetriesTransientFailuresThenSucceeds() async throws {
        let service = MockExportServiceForTests()
        let poller = ExportPoller(exportService: service)
        let projectID = UUID()
        let jobID = UUID()

        service.statusErrors = [
            ExportServiceError.temporarilyUnavailable,
            ExportServiceError.generationNotReady
        ]
        service.statusSequence = [
            ComicExportJob(
                jobID: jobID,
                projectID: projectID,
                type: .pdf,
                status: .running,
                progressPct: 40,
                artifactURL: nil,
                errorCode: nil,
                errorMessage: nil,
                retryable: true
            ),
            ComicExportJob(
                jobID: jobID,
                projectID: projectID,
                type: .pdf,
                status: .succeeded,
                progressPct: 100,
                artifactURL: URL(string: "https://mock.storycomicai.local/exports/final.pdf"),
                errorCode: nil,
                errorMessage: nil,
                retryable: true
            )
        ]

        let policy = ExportPollingPolicy(
            intervalSeconds: 0,
            maxAttempts: 10,
            maxTransientFailures: 3,
            baseRetryDelaySeconds: 0,
            maxRetryDelaySeconds: 0
        )

        let result = try await poller.poll(
            projectID: projectID,
            jobID: jobID,
            policy: policy
        ) { _ in }

        XCTAssertEqual(result.status, .succeeded)
        XCTAssertGreaterThanOrEqual(service.statusCalls, 4)
    }

    func testPollFailsAfterTransientFailureLimitExceeded() async {
        let service = MockExportServiceForTests()
        let poller = ExportPoller(exportService: service)
        let projectID = UUID()
        let jobID = UUID()

        service.statusErrors = [
            ExportServiceError.temporarilyUnavailable,
            ExportServiceError.temporarilyUnavailable,
            ExportServiceError.temporarilyUnavailable
        ]

        let policy = ExportPollingPolicy(
            intervalSeconds: 0,
            maxAttempts: 10,
            maxTransientFailures: 2,
            baseRetryDelaySeconds: 0,
            maxRetryDelaySeconds: 0
        )

        do {
            _ = try await poller.poll(
                projectID: projectID,
                jobID: jobID,
                policy: policy
            ) { _ in }
            XCTFail("Expected poller to throw after transient failure limit.")
        } catch let error as ExportServiceError {
            XCTAssertEqual(error, .temporarilyUnavailable)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
