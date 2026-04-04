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
            errorMessage = L10n.string("style.error.title_missing")
            return false
        }

        isCreatingProject = true
        errorMessage = nil
        defer { isCreatingProject = false }

        do {
            let project = try await projectService.createProject(
                title: trimmedProjectName,
                storyText: flowStore.storyText.trimmingCharacters(in: .whitespacesAndNewlines),
                style: flowStore.selectedStyle,
                targetPages: 12
            )
            flowStore.createdProject = project
            return true
        } catch {
            let now = Date()
            flowStore.createdProject = Project(
                id: UUID(),
                title: trimmedProjectName,
                storyText: flowStore.storyText.trimmingCharacters(in: .whitespacesAndNewlines),
                style: flowStore.selectedStyle,
                targetPages: 12,
                freePreviewPages: 3,
                status: "draft",
                isUnlocked: true,
                createdAtUTC: now,
                updatedAtUTC: now
            )
            errorMessage = nil
            return true
        }
    }
}
