import Foundation

enum ComicPackageEndpoints {
    static func fetch(projectID: UUID) -> APIEndpoint {
        APIEndpoint(
            path: "/v1/projects/\(projectID.uuidString)/comic-package",
            method: .get,
            requiresAuth: true
        )
    }

    static func fetchGenerationBlueprint(projectID: UUID) -> APIEndpoint {
        APIEndpoint(
            path: "/v1/projects/\(projectID.uuidString)/generation-blueprint",
            method: .get,
            requiresAuth: true
        )
    }

    static func updateReadingProgress(
        projectID: UUID,
        currentPageIndex: Int,
        lastOpenedAtUTC: Date
    ) throws -> APIEndpoint {
        APIEndpoint(
            path: "/v1/projects/\(projectID.uuidString)/reading-progress",
            method: .patch,
            body: try APIEndpoint.encodeBody(
                ReadingProgressUpdateRequestBody(
                    currentPageIndex: currentPageIndex,
                    lastOpenedAtUTC: lastOpenedAtUTC
                )
            ),
            requiresAuth: true
        )
    }
}
