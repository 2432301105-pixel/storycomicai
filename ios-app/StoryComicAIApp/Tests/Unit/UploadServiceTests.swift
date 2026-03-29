import XCTest
@testable import StoryComicAIApp

final class UploadServiceTests: XCTestCase {
    func testUploadAssetsReturnsUploadedPhotoIDs() async throws {
        let apiClient = MockAPIClient()
        let transferSpy = UploadTransferSpy()
        let service = DefaultUploadService(apiClient: apiClient, transferClient: transferSpy)

        let assets = [
            LocalPhotoAsset(filename: "a.jpg", data: Data(repeating: 1, count: 10_000)),
            LocalPhotoAsset(filename: "b.jpg", data: Data(repeating: 2, count: 12_000))
        ]

        let uploadedIDs = try await service.uploadAssets(projectID: UUID(), assets: assets)

        XCTAssertEqual(uploadedIDs.count, 2)
        XCTAssertEqual(transferSpy.uploadCallCount, 2)
    }
}

private final class UploadTransferSpy: UploadTransferClient {
    private(set) var uploadCallCount: Int = 0

    func upload(data: Data, to destinationURL: URL, mimeType: String) async throws {
        _ = (data, destinationURL, mimeType)
        uploadCallCount += 1
    }
}
