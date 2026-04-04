import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    struct Page: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let systemImage: String
    }

    var pages: [Page] {
        [
            Page(
                title: L10n.string("onboarding.page1.title"),
                subtitle: L10n.string("onboarding.page1.subtitle"),
                systemImage: "person.crop.square"
            ),
            Page(
                title: L10n.string("onboarding.page2.title"),
                subtitle: L10n.string("onboarding.page2.subtitle"),
                systemImage: "text.book.closed"
            ),
            Page(
                title: L10n.string("onboarding.page3.title"),
                subtitle: L10n.string("onboarding.page3.subtitle"),
                systemImage: "sparkles.rectangle.stack"
            )
        ]
    }

    @Published var currentIndex: Int = 0

    var isLastPage: Bool {
        currentIndex == pages.count - 1
    }

    func next() {
        currentIndex = min(currentIndex + 1, pages.count - 1)
    }
}
