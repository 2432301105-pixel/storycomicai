import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    struct Page: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let systemImage: String
    }

    let pages: [Page] = [
        Page(
            title: "Turn Yourself Into The Hero",
            subtitle: "Upload photos and build a personal comic with consistent character identity.",
            systemImage: "person.crop.square"
        ),
        Page(
            title: "Structured Story Pipeline",
            subtitle: "Scenes and panels are generated in sequence for a coherent reading flow.",
            systemImage: "text.book.closed"
        ),
        Page(
            title: "Premium Comic Experience",
            subtitle: "Cover pages, polished typography, and smooth page-by-page storytelling.",
            systemImage: "sparkles.rectangle.stack"
        )
    ]

    @Published var currentIndex: Int = 0

    var isLastPage: Bool {
        currentIndex == pages.count - 1
    }

    func next() {
        currentIndex = min(currentIndex + 1, pages.count - 1)
    }
}
