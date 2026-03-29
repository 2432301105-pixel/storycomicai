import Foundation

@MainActor
final class PollingTaskController {
    private var task: Task<Void, Never>?

    func start(_ operation: @escaping @MainActor () async -> Void) {
        stop()
        task = Task { @MainActor in
            await operation()
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    deinit {
        task?.cancel()
    }
}
