import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<[Project]> = .idle

    private let projectService: any ProjectService

    init(projectService: any ProjectService) {
        self.projectService = projectService
    }

    func loadProjects() async {
        state = .loading
        do {
            let projects = try await projectService.listProjects(limit: 50)
            state = .loaded(projects)
        } catch {
            state = .failed(error.userFacingMessage)
        }
    }
}
