import Foundation

@MainActor
final class StoryInputViewModel: ObservableObject {
    @Published var minLength: Int = 20

    func isStoryValid(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count >= minLength
    }
}
