import Foundation

protocol ProjectService: AnyObject {
    func createProject(title: String, storyText: String, style: StoryStyle, targetPages: Int) async throws -> Project
    func listProjects(limit: Int) async throws -> [Project]
}

final class DefaultProjectService: ProjectService {
    private let apiClient: any APIClient

    init(apiClient: any APIClient) {
        self.apiClient = apiClient
    }

    func createProject(title: String, storyText: String, style: StoryStyle, targetPages: Int) async throws -> Project {
        let endpoint = try ProjectEndpoints.createProject(
            title: title,
            storyText: storyText,
            style: style,
            targetPages: targetPages
        )
        do {
            let dto = try await apiClient.request(endpoint, decode: ProjectResponseDTO.self)
            return dto.toDomain()
        } catch let apiError as APIError {
            if apiError.isProjectCreateFallbackEligible {
                let now = Date()
                return Project(
                    id: UUID(),
                    title: title,
                    storyText: storyText,
                    style: style,
                    targetPages: targetPages,
                    freePreviewPages: 3,
                    status: "draft",
                    isUnlocked: true,
                    createdAtUTC: now,
                    updatedAtUTC: now
                )
            }
            throw apiError
        }
    }

    func listProjects(limit: Int = 20) async throws -> [Project] {
        let endpoint = ProjectEndpoints.listProjects(limit: limit)
        let dto = try await apiClient.request(endpoint, decode: ProjectListResponseDTO.self)
        return dto.items.map { $0.toDomain() }
    }
}

private extension APIError {
    var isProjectCreateFallbackEligible: Bool {
        switch self {
        case .decoding, .emptyResponseData, .transport:
            return true
        case let .server(statusCode, _):
            return statusCode >= 500 || statusCode == 404
        case let .backend(code, _):
            return code == "ENDPOINT_NOT_IMPLEMENTED" || code == "PROJECT_NOT_FOUND"
        default:
            return false
        }
    }
}

private extension ProjectResponseDTO {
    func toDomain() -> Project {
        Project(
            id: id,
            title: title,
            storyText: storyText,
            style: style,
            targetPages: targetPages,
            freePreviewPages: freePreviewPages,
            status: status,
            isUnlocked: isUnlocked,
            createdAtUTC: createdAtUTC,
            updatedAtUTC: updatedAtUTC
        )
    }
}
