import Foundation

enum ProjectEndpoints {
    static func createProject(title: String, storyText: String, style: StoryStyle, targetPages: Int) throws -> APIEndpoint {
        APIEndpoint(
            path: "/v1/projects",
            method: .post,
            body: try APIEndpoint.encodeBody(
                CreateProjectRequestBody(
                    title: title,
                    storyText: storyText,
                    style: style,
                    targetPages: targetPages
                )
            ),
            requiresAuth: true
        )
    }

    static func listProjects(limit: Int = 20) -> APIEndpoint {
        APIEndpoint(
            path: "/v1/projects",
            method: .get,
            queryItems: [URLQueryItem(name: "limit", value: String(limit))],
            requiresAuth: true
        )
    }
}

enum ComicGenerationEndpoints {
    static func start(projectID: UUID, forceRegenerate: Bool = false) throws -> APIEndpoint {
        APIEndpoint(
            path: "/v1/projects/\(projectID.uuidString)/comic-generation",
            method: .post,
            body: try APIEndpoint.encodeBody(
                ComicGenerationStartRequestBody(forceRegenerate: forceRegenerate)
            ),
            requiresAuth: true
        )
    }

    static func status(projectID: UUID, jobID: UUID) -> APIEndpoint {
        APIEndpoint(
            path: "/v1/projects/\(projectID.uuidString)/comic-generation/\(jobID.uuidString)",
            method: .get,
            requiresAuth: true
        )
    }
}
