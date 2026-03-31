import XCTest
@testable import StoryComicAIApp

final class ComicPackageServiceTests: XCTestCase {
    func testFetchComicPackageFallsBackOnlyOnExplicitNotImplementedError() async throws {
        let apiClient = StubAPIClientForTests()
        apiClient.error = APIError.server(statusCode: 501, body: nil)
        let service = DefaultComicPackageService(apiClient: apiClient)
        let projectID = UUID()

        let package = try await service.fetchComicBookPackage(projectID: projectID)

        XCTAssertEqual(package.projectID, projectID)
        XCTAssertEqual(package.source, .fallback)
    }

    func testFetchComicPackageDoesNotFallbackOnNotFoundError() async {
        let apiClient = StubAPIClientForTests()
        apiClient.error = APIError.server(statusCode: 404, body: nil)
        let service = DefaultComicPackageService(apiClient: apiClient)

        do {
            _ = try await service.fetchComicBookPackage(projectID: UUID())
            XCTFail("Expected 404 server error to propagate.")
        } catch let error as APIError {
            if case let .server(statusCode, _) = error {
                XCTAssertEqual(statusCode, 404)
            } else {
                XCTFail("Expected APIError.server, got \(error)")
            }
        } catch {
            XCTFail("Expected APIError.server, got \(error)")
        }
    }

    func testFetchComicPackageDoesNotFallbackOnTransportError() async {
        let apiClient = StubAPIClientForTests()
        apiClient.error = APIError.transport(underlying: NSError(domain: "net", code: -1009))
        let service = DefaultComicPackageService(apiClient: apiClient)

        do {
            _ = try await service.fetchComicBookPackage(projectID: UUID())
            XCTFail("Expected transport error to propagate.")
        } catch let error as APIError {
            if case .transport = error {
                // expected
            } else {
                XCTFail("Expected APIError.transport, got \(error)")
            }
        } catch {
            XCTFail("Expected APIError.transport, got \(error)")
        }
    }

    func testUpdateReadingProgressFallsBackOnTransportError() async throws {
        let apiClient = StubAPIClientForTests()
        apiClient.error = APIError.transport(underlying: NSError(domain: "net", code: -1009))
        let service = DefaultComicPackageService(apiClient: apiClient)
        let now = Date()

        let progress = try await service.updateReadingProgress(
            projectID: UUID(),
            currentPageIndex: 4,
            lastOpenedAtUTC: now
        )

        XCTAssertEqual(progress.currentPageIndex, 4)
        XCTAssertEqual(progress.lastOpenedAtUTC, now)
    }

    func testMapReadingDirectionSupportsShortBackendValues() {
        let direction = ComicBookPackageResponseDTO.mapReadingDirection("ltr", fallback: .rightToLeft)
        XCTAssertEqual(direction, .leftToRight)
    }

    func testMapDeskThemeMapsBackendAliases() {
        let theme = ComicBookPackageResponseDTO.mapDeskTheme("light", fallback: .walnut)
        XCTAssertEqual(theme, .silver)
    }
}

private final class StubAPIClientForTests: APIClient {
    var error: Error?

    func request<T>(_ endpoint: APIEndpoint, decode: T.Type) async throws -> T where T: Decodable {
        _ = endpoint
        if let error {
            throw error
        }
        XCTFail("StubAPIClientForTests requires an injected error for this test path.")
        throw APIError.invalidResponse
    }
}
