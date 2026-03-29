import Foundation

@MainActor
final class ExportViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case creating
        case queued(jobID: UUID)
        case running(jobID: UUID, progress: Double?)
        case ready(job: ComicExportJob)
        case downloading
        case sharing(localURL: URL)
        case failed(message: String, retryable: Bool)
    }

    private enum Constants {
        static let operationRetryAttempts = 3
        static let operationRetryBaseDelaySeconds: TimeInterval = 0.8
        static let operationRetryMaxDelaySeconds: TimeInterval = 4
    }

    private enum RetryableOperation {
        case createExport
        case downloadArtifact
    }

    @Published private(set) var state: State = .idle
    @Published var selectedType: ComicExportType = .pdf {
        didSet { handleSelectedTypeChanged() }
    }
    @Published private(set) var shareSheetURL: URL?

    private let coordinator: ComicPresentationCoordinator
    private let exportService: any ExportService
    private let poller: ExportPoller
    private let fileManager: FileManager

    private var runningTask: Task<Void, Never>?
    private var activeOperationID: UUID?
    private var lastRequestedType: ComicExportType?
    private var lastReadyJob: ComicExportJob?
    private var downloadedArtifactURL: URL?

    init(
        coordinator: ComicPresentationCoordinator,
        exportService: any ExportService,
        fileManager: FileManager = .default
    ) {
        self.coordinator = coordinator
        self.exportService = exportService
        self.poller = ExportPoller(exportService: exportService)
        self.fileManager = fileManager
    }

    deinit {
        runningTask?.cancel()
    }

    func switchMode(_ mode: ComicPresentationMode) {
        coordinator.switchMode(mode)
    }

    func startExport() {
        guard canStartExport else { return }
        guard case let .loaded(package) = coordinator.packageState else {
            state = .failed(message: "Comic package is not loaded yet.", retryable: true)
            return
        }

        if package.paywallMetadata.isUnlocked == false || package.exportAvailability.lockedByPaywall {
            state = .failed(message: ExportServiceError.paywallLocked.userMessage, retryable: false)
            return
        }

        let isTypeAvailable: Bool = {
            switch selectedType {
            case .pdf:
                return package.exportAvailability.isPDFAvailable
            case .imageBundle:
                return package.exportAvailability.isImagePackAvailable
            }
        }()

        guard isTypeAvailable else {
            state = .failed(message: ExportServiceError.featureUnavailable.userMessage, retryable: false)
            return
        }

        lastReadyJob = nil
        shareSheetURL = nil
        cleanupDownloadedArtifact()
        lastRequestedType = selectedType
        coordinator.trackExportTap(action: "start_\(selectedType.rawValue)")

        let operationID = beginOperation()
        let type = selectedType
        runningTask = Task { [weak self] in
            guard let self else { return }
            await self.runCreateAndPollFlow(type: type, operationID: operationID)
        }
    }

    func retry() {
        guard let lastRequestedType else { return }
        selectedType = lastRequestedType
        startExport()
    }

    func prepareShare() {
        guard canStartShare else { return }
        guard case let .ready(job) = state else { return }
        guard let artifactURL = job.artifactURL else {
            state = .failed(
                message: ExportServiceError.invalidArtifact.userMessage,
                retryable: ExportServiceError.invalidArtifact.isRetryable
            )
            return
        }

        let operationID = beginOperation()
        runningTask = Task { [weak self] in
            guard let self else { return }
            await self.runDownloadAndShare(job: job, artifactURL: artifactURL, operationID: operationID)
        }
    }

    func didDismissShareSheet() {
        let shouldRestoreReadyState: Bool
        if case .sharing = state {
            shouldRestoreReadyState = true
        } else {
            shouldRestoreReadyState = false
        }
        shareSheetURL = nil
        cleanupDownloadedArtifact()
        if shouldRestoreReadyState, let lastReadyJob {
            state = .ready(job: lastReadyJob)
        }
    }

    private func runCreateAndPollFlow(type: ComicExportType, operationID: UUID) async {
        guard isOperationActive(operationID) else { return }
        state = .creating

        do {
            let created = try await performWithRetry(
                operation: .createExport,
                maxAttempts: Constants.operationRetryAttempts
            ) { [exportService, coordinator] in
                try await exportService.createExport(
                    projectID: coordinator.projectID,
                    type: type,
                    preset: .screen,
                    includeCover: true
                )
            }
            guard isOperationActive(operationID) else { return }
            applyPollingUpdate(created)

            let terminalJob = try await poller.poll(
                projectID: coordinator.projectID,
                jobID: created.jobID,
                policy: .standard()
            ) { [weak self] status in
                guard let self, self.isOperationActive(operationID) else { return }
                self.applyPollingUpdate(status)
            }
            guard isOperationActive(operationID) else { return }

            applyTerminalState(job: terminalJob)
        } catch is CancellationError {
            return
        } catch {
            let mapped = map(error)
            state = .failed(message: mapped.userMessage, retryable: mapped.isRetryable)
        }
    }

    private func runDownloadAndShare(job: ComicExportJob, artifactURL: URL, operationID: UUID) async {
        guard isOperationActive(operationID) else { return }
        state = .downloading
        do {
            let localURL = try await performWithRetry(
                operation: .downloadArtifact,
                maxAttempts: Constants.operationRetryAttempts
            ) { [exportService, coordinator] in
                try await exportService.downloadArtifact(
                    from: artifactURL,
                    projectID: coordinator.projectID,
                    jobID: job.jobID,
                    type: job.type
                )
            }
            guard isOperationActive(operationID) else { return }
            if let existingURL = downloadedArtifactURL, existingURL != localURL {
                removeFileIfNeeded(at: existingURL)
            }
            downloadedArtifactURL = localURL
            shareSheetURL = localURL
            state = .sharing(localURL: localURL)
        } catch is CancellationError {
            return
        } catch {
            let mapped = map(error)
            state = .failed(message: mapped.userMessage, retryable: mapped.isRetryable)
        }
    }

    private func applyPollingUpdate(_ status: ComicExportJob) {
        switch status.status {
        case .queued:
            state = .queued(jobID: status.jobID)
        case .running:
            let progress = status.progressPct.map { Double($0) / 100.0 }
            state = .running(jobID: status.jobID, progress: progress)
        case .succeeded, .failed:
            break
        }
    }

    private func map(_ error: Error) -> ExportServiceError {
        if let mapped = error as? ExportServiceError {
            return mapped
        }
        return .temporarilyUnavailable
    }

    private func performWithRetry<T>(
        operation: RetryableOperation,
        maxAttempts: Int,
        _ block: () async throws -> T
    ) async throws -> T {
        var attempt = 0
        var lastError: Error?

        while attempt < maxAttempts {
            attempt += 1
            do {
                return try await block()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                let mapped = map(error)
                lastError = mapped
                if !mapped.isRetryable || attempt >= maxAttempts {
                    throw mapped
                }

                coordinator.trackExportTap(action: "\(operationActionPrefix(operation))_retry_\(attempt)")
                let delay = min(
                    Constants.operationRetryMaxDelaySeconds,
                    Constants.operationRetryBaseDelaySeconds * pow(2, Double(max(0, attempt - 1)))
                )
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw map(lastError ?? ExportServiceError.temporarilyUnavailable)
    }

    private func operationActionPrefix(_ operation: RetryableOperation) -> String {
        switch operation {
        case .createExport:
            return "create_export"
        case .downloadArtifact:
            return "download_export"
        }
    }

    private var canStartExport: Bool {
        switch state {
        case .creating, .queued, .running, .downloading, .sharing:
            return false
        case .idle, .ready, .failed:
            return true
        }
    }

    private var canStartShare: Bool {
        switch state {
        case .ready:
            return true
        default:
            return false
        }
    }

    private func beginOperation() -> UUID {
        runningTask?.cancel()
        let operationID = UUID()
        activeOperationID = operationID
        return operationID
    }

    private func isOperationActive(_ operationID: UUID) -> Bool {
        activeOperationID == operationID
    }

    private func handleSelectedTypeChanged() {
        guard let readyJob = lastReadyJob else { return }
        guard readyJob.type != selectedType else { return }
        if case .ready = state {
            state = .idle
        }
    }

    private func applyTerminalState(job: ComicExportJob) {
        switch job.status {
        case .succeeded:
            guard job.artifactURL != nil else {
                state = .failed(
                    message: ExportServiceError.invalidArtifact.userMessage,
                    retryable: false
                )
                return
            }
            lastReadyJob = job
            state = .ready(job: job)
        case .failed:
            let message = job.errorMessage ?? ExportServiceError.temporarilyUnavailable.userMessage
            state = .failed(message: message, retryable: job.retryable)
        case .queued, .running:
            state = .failed(
                message: ExportServiceError.temporarilyUnavailable.userMessage,
                retryable: true
            )
        }
    }

    private func cleanupDownloadedArtifact() {
        guard let url = downloadedArtifactURL else { return }
        downloadedArtifactURL = nil
        removeFileIfNeeded(at: url)
    }

    private func removeFileIfNeeded(at url: URL) {
        guard url.isFileURL else { return }
        guard fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            // Best-effort cleanup only.
        }
    }
}
