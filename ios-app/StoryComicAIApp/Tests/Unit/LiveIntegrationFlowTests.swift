import Foundation
import XCTest
@testable import StoryComicAIApp

final class LiveIntegrationFlowTests: XCTestCase {
    func testLiveFlowSignInCreateProjectHeroPreview() async throws {
        let env = ProcessInfo.processInfo.environment
        guard env["STORYCOMICAI_RUN_LIVE_INTEGRATION"] == "1" else {
            throw XCTSkip("Set STORYCOMICAI_RUN_LIVE_INTEGRATION=1 to run live integration test.")
        }

        let baseURLString = env["STORYCOMICAI_API_BASE_URL"] ?? "http://localhost:8000"
        guard let baseURL = URL(string: baseURLString) else {
            XCTFail("Invalid base URL: \(baseURLString)")
            return
        }

        let tokenStore = InMemoryAccessTokenStore()
        let apiClient = LiveAPIClient(
            environment: APIEnvironment(baseURL: baseURL, timeout: 30),
            tokenStore: tokenStore
        )

        let authService = DefaultAuthService(apiClient: apiClient)
        let projectService = DefaultProjectService(apiClient: apiClient)
        let uploadService = DefaultUploadService(apiClient: apiClient, transferClient: NoopUploadTransferClient())
        let heroService = DefaultHeroPreviewService(apiClient: apiClient)

        let appleClientID = env["STORYCOMICAI_APPLE_CLIENT_ID"] ?? "com.storycomicai.app"
        let identityToken = makeLocalAppleToken(clientID: appleClientID)

        let session = try await authService.verifyApple(identityToken: identityToken)
        await tokenStore.writeToken(session.accessToken)

        let project = try await projectService.createProject(
            title: "Live Flow \(Int(Date().timeIntervalSince1970))",
            storyText: "A lone hero follows a coded trail across the city to stop a midnight conspiracy before dawn.",
            style: .manga,
            targetPages: 12
        )

        let uploadedPhotoIDs = try await uploadService.uploadAssets(
            projectID: project.id,
            assets: [LocalPhotoAsset(filename: "live.jpg", data: Data(repeating: 7, count: 20_000))]
        )
        XCTAssertFalse(uploadedPhotoIDs.isEmpty)

        let started = try await heroService.startHeroPreview(
            projectID: project.id,
            photoIDs: uploadedPhotoIDs,
            style: .manga
        )
        XCTAssertEqual(started.projectID, project.id)

        let status = try await heroService.fetchHeroPreviewStatus(projectID: project.id, jobID: started.jobID)
        XCTAssertEqual(status.jobID, started.jobID)
        XCTAssertEqual(status.projectID, project.id)
    }
}

private final class NoopUploadTransferClient: UploadTransferClient {
    func upload(data: Data, to destinationURL: URL, mimeType: String) async throws {
        _ = (data, destinationURL, mimeType)
    }
}

private func makeLocalAppleToken(clientID: String) -> String {
    let header: [String: Any] = [
        "alg": "HS256",
        "typ": "JWT"
    ]

    let payload: [String: Any] = [
        "sub": "storycomicai-local-user",
        "aud": clientID,
        "iss": "https://appleid.apple.com",
        "exp": Int(Date().addingTimeInterval(3600).timeIntervalSince1970)
    ]

    let headerPart = base64URL(header)
    let payloadPart = base64URL(payload)
    return "\(headerPart).\(payloadPart).local-signature"
}

private func base64URL(_ object: [String: Any]) -> String {
    let data = try? JSONSerialization.data(withJSONObject: object, options: [])
    let base64 = (data ?? Data()).base64EncodedString()
    return base64
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}
