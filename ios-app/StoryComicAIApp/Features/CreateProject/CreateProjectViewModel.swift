import Foundation

@MainActor
final class CreateProjectViewModel: ObservableObject {
    @Published var validationMessage: String?

    func validateProjectName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            validationMessage = L10n.string("create.validation.short")
            return false
        }
        validationMessage = nil
        return true
    }
}
