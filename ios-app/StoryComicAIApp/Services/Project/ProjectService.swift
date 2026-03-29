import Foundation

protocol ProjectService: AnyObject {
    func createProject(title: String, style: StoryStyle, targetPages: Int) async throws -> Project
    func listProjects(limit: Int) async throws -> [Project]
}

final class DefaultProjectService: ProjectService {
    private let apiClient: any APIClient

    init(apiClient: any APIClient) {
        self.apiClient = apiClient
    }

    func createProject(title: String, style: StoryStyle, targetPages: Int) async throws -> Project {
        let endpoint = try ProjectEndpoints.createProject(title: title, style: style, targetPages: targetPages)
        let dto = try await apiClient.request(endpoint, decode: ProjectResponseDTO.self)
        return dto.toDomain()
    }

    func listProjects(limit: Int = 20) async throws -> [Project] {
        let endpoint = ProjectEndpoints.listProjects(limit: limit)
        let dto = try await apiClient.request(endpoint, decode: ProjectListResponseDTO.self)
        return dto.items.map { $0.toDomain() }
    }
}

private extension ProjectResponseDTO {
    func toDomain() -> Project {
        Project(
            id: id,
            title: title,
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
