import Foundation

@MainActor
final class ProjectDetailViewModel: ObservableObject {
    let project: Project

    init(project: Project) {
        self.project = project
    }
}
