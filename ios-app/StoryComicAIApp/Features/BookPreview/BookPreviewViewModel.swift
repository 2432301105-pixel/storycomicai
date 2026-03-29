import SwiftUI

@MainActor
final class BookPreviewViewModel: ObservableObject {
    @Published private(set) var dragOffset: CGFloat = 0

    private let coordinator: ComicPresentationCoordinator
    private var tapTurnTask: Task<Void, Never>?

    private enum Constants {
        static let commitThresholdRatio: CGFloat = 0.12
        static let tapTurnOffset: CGFloat = 120
        static let tapTurnDurationNanos: UInt64 = 120_000_000
    }

    init(coordinator: ComicPresentationCoordinator) {
        self.coordinator = coordinator
    }

    var turnProgress: CGFloat {
        min(max(abs(dragOffset) / 280, 0), 1)
    }

    var turnDirection: PageTurnDirection {
        dragOffset < 0 ? .forward : .backward
    }

    func onDragChanged(_ value: DragGesture.Value) {
        dragOffset = value.translation.width
    }

    func onDragEnded(_ value: DragGesture.Value, containerWidth: CGFloat, reduceMotion: Bool) {
        defer {
            withAnimation(AppMotion.pageTurn(reduceMotion: reduceMotion)) {
                dragOffset = 0
            }
        }

        let width = max(containerWidth, 1)
        let normalized = value.translation.width / width

        if normalized < -Constants.commitThresholdRatio {
            coordinator.goToNextPage()
        } else if normalized > Constants.commitThresholdRatio {
            coordinator.goToPreviousPage()
        }
    }

    func onTap(locationX: CGFloat, containerWidth: CGFloat, reduceMotion: Bool) {
        let width = max(containerWidth, 1)
        let isForward = locationX > (width * 0.5)

        guard (isForward && coordinator.canGoNext) || (!isForward && coordinator.canGoPrevious) else {
            return
        }

        tapTurnTask?.cancel()
        let directionOffset: CGFloat = isForward ? -Constants.tapTurnOffset : Constants.tapTurnOffset

        withAnimation(AppMotion.pageTurn(reduceMotion: reduceMotion)) {
            dragOffset = directionOffset
        }

        tapTurnTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: Constants.tapTurnDurationNanos)
            if Task.isCancelled { return }

            if isForward {
                coordinator.goToNextPage()
            } else {
                coordinator.goToPreviousPage()
            }

            withAnimation(AppMotion.pageTurn(reduceMotion: reduceMotion)) {
                self.dragOffset = 0
            }
        }
    }

    func openFlatReader() {
        coordinator.openFlatReader()
    }

    func openExport() {
        coordinator.openExport()
    }

    func switchMode(_ mode: ComicPresentationMode) {
        coordinator.switchMode(mode)
    }

    deinit {
        tapTurnTask?.cancel()
    }
}
