import Foundation

@MainActor
final class BookRevealViewModel: ObservableObject {
    private let coordinator: ComicPresentationCoordinator

    init(coordinator: ComicPresentationCoordinator) {
        self.coordinator = coordinator
    }

    func onAppear() {
        Task { await coordinator.startIfNeeded() }
    }

    func retry() {
        Task { await coordinator.retry() }
    }

    func openBook() {
        coordinator.openBook()
    }

    func openFlatReader() {
        coordinator.openFlatReader()
    }

    func openExport() {
        coordinator.openExport()
    }
}
