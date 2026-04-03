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
