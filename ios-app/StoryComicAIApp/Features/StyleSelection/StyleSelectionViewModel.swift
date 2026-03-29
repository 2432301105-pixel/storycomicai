import Foundation

@MainActor
final class StyleSelectionViewModel: ObservableObject {
    @Published private(set) var isCreatingProject: Bool = false
    @Published private(set) var errorMessage: String?

    private let projectService: any ProjectService

    init(projectService: any ProjectService) {
        self.projectService = projectService
    }

    func ensureProjectExists(for flowStore: CreateProjectFlowStore) async -> Bool {
        if flowStore.createdProject != nil {
            return true
        }

        let trimmedProjectName = flowStore.projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedProjectName.count >= 3 else {
            errorMessage = "Project title is missing. Go back and set a valid title."
            return false
        }

        isCreatingProject = true
        errorMessage = nil
        defer { isCreatingProject = false }

        do {
            let project = try await projectService.createProject(
                title: trimmedProjectName,
                style: flowStore.selectedStyle,
                targetPages: 12
            )
            flowStore.createdProject = project
            return true
        } catch {
            errorMessage = error.userFacingMessage
            return false
        }
    }
}
