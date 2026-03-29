import Foundation

@MainActor
final class CreateProjectViewModel: ObservableObject {
    @Published var validationMessage: String?

    func validateProjectName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            validationMessage = "Project title must be at least 3 characters."
            return false
        }
        validationMessage = nil
        return true
    }
}
