import Foundation

struct ExportPollingPolicy {
    let intervalSeconds: TimeInterval
    let maxAttempts: Int
    let maxTransientFailures: Int
    let baseRetryDelaySeconds: TimeInterval
    let maxRetryDelaySeconds: TimeInterval

    static func standard() -> ExportPollingPolicy {
        ExportPollingPolicy(
            intervalSeconds: 2,
            maxAttempts: 45,
            maxTransientFailures: 5,
            baseRetryDelaySeconds: 1,
            maxRetryDelaySeconds: 10
        )
    }
}

final class ExportPoller {
    private let exportService: any ExportService

    init(exportService: any ExportService) {
        self.exportService = exportService
    }

    func poll(
        projectID: UUID,
        jobID: UUID,
        policy: ExportPollingPolicy = .standard(),
        onUpdate: @escaping @MainActor (ComicExportJob) -> Void
    ) async throws -> ComicExportJob {
        var latest: ComicExportJob?
        var attempts = 0
        var transientFailures = 0

        while !Task.isCancelled {
            attempts += 1
            do {
                let status = try await exportService.getExportStatus(projectID: projectID, jobID: jobID)
                latest = status
                transientFailures = 0
                await onUpdate(status)

                if status.status.isTerminal {
                    break
                }
                if attempts >= policy.maxAttempts {
                    throw ExportServiceError.generationNotReady
                }

                try await sleep(seconds: policy.intervalSeconds)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                if isTransient(error), transientFailures < policy.maxTransientFailures {
                    transientFailures += 1
                    let retryDelay = min(
                        policy.maxRetryDelaySeconds,
                        policy.baseRetryDelaySeconds * pow(2, Double(transientFailures - 1))
                    )
                    try await sleep(seconds: retryDelay)
                    continue
                }
                throw error
            }
        }

        if let latest {
            return latest
        }

        throw ExportServiceError.temporarilyUnavailable
    }

    private func sleep(seconds: TimeInterval) async throws {
        let nanos = UInt64(max(0, seconds) * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanos)
    }

    private func isTransient(_ error: Error) -> Bool {
        if let exportError = error as? ExportServiceError {
            return exportError.isRetryable
        }
        return false
    }
}
