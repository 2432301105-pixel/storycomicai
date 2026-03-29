import Foundation

enum HeroPreviewEndpoints {
    static func start(
        projectID: UUID,
        photoIDs: [UUID],
        style: StoryStyle?
    ) throws -> APIEndpoint {
        APIEndpoint(
            path: "/v1/projects/\(projectID.uuidString)/hero-preview",
            method: .post,
            body: try APIEndpoint.encodeBody(
                HeroPreviewStartRequestBody(photoIDs: photoIDs, style: style)
            ),
            requiresAuth: true
        )
    }

    static func status(projectID: UUID, jobID: UUID) -> APIEndpoint {
        APIEndpoint(
            path: "/v1/projects/\(projectID.uuidString)/hero-preview/\(jobID.uuidString)",
            method: .get,
            requiresAuth: true
        )
    }
}
