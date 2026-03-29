import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var recentProjectsState: LoadableState<[Project]> = .idle

    private let projectService: any ProjectService

    init(projectService: any ProjectService) {
        self.projectService = projectService
    }

    func loadRecentProjects() async {
        recentProjectsState = .loading
        do {
            let projects = try await projectService.listProjects(limit: 5)
            recentProjectsState = .loaded(projects)
        } catch {
            recentProjectsState = .failed(error.userFacingMessage)
        }
    }
}
