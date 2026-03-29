import Foundation

@MainActor
final class FlatReaderViewModel: ObservableObject {
    private let coordinator: ComicPresentationCoordinator

    init(coordinator: ComicPresentationCoordinator) {
        self.coordinator = coordinator
    }

    func switchMode(_ mode: ComicPresentationMode) {
        coordinator.switchMode(mode)
    }

    func openExport() {
        coordinator.openExport()
    }
}
