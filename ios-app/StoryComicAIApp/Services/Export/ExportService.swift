import Foundation

protocol ExportService: AnyObject {
    func createExport(
        projectID: UUID,
        type: ComicExportType,
        preset: ComicExportPreset,
        includeCover: Bool
    ) async throws -> ComicExportJob

    func getExportStatus(projectID: UUID, jobID: UUID) async throws -> ComicExportJob

    func downloadArtifact(
        from remoteURL: URL,
        projectID: UUID,
        jobID: UUID,
        type: ComicExportType
    ) async throws -> URL
}

enum ExportServiceError: Error, Equatable {
    case featureUnavailable
    case unauthorized
    case paywallLocked
    case generationNotReady
    case temporarilyUnavailable
    case invalidArtifact
    case downloadFailed
    case backend(message: String, retryable: Bool)
}

extension ExportServiceError {
    static func == (lhs: ExportServiceError, rhs: ExportServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.featureUnavailable, .featureUnavailable),
             (.unauthorized, .unauthorized),
             (.paywallLocked, .paywallLocked),
             (.generationNotReady, .generationNotReady),
             (.temporarilyUnavailable, .temporarilyUnavailable),
             (.invalidArtifact, .invalidArtifact),
             (.downloadFailed, .downloadFailed):
            return true
        case let (.backend(lhsMessage, lhsRetryable), .backend(rhsMessage, rhsRetryable)):
            return lhsMessage == rhsMessage && lhsRetryable == rhsRetryable
        default:
            return false
        }
    }
}

extension ExportServiceError {
    var userMessage: String {
        switch self {
        case .featureUnavailable:
            return "Export is not available yet for this project."
        case .unauthorized:
            return "Your session expired. Please sign in again."
        case .paywallLocked:
            return "Unlock full story to export this comic."
        case .generationNotReady:
            return "Comic rendering is still in progress. Try again shortly."
        case .temporarilyUnavailable:
            return "Export service is temporarily unavailable. Please retry."
        case .invalidArtifact:
            return "Export file is invalid. Please regenerate export."
        case .downloadFailed:
            return "Could not download export file. Check your network and retry."
        case let .backend(message, _):
            return message
        }
    }

    var isRetryable: Bool {
        switch self {
        case .featureUnavailable, .unauthorized, .paywallLocked, .invalidArtifact:
            return false
        case .generationNotReady, .temporarilyUnavailable, .downloadFailed:
            return true
        case let .backend(_, retryable):
            return retryable
        }
    }
}

final class DefaultExportService: ExportService {
    private enum Constants {
        static let temporaryDirectoryName = "storycomicai-exports"
        static let defaultRetentionSeconds: TimeInterval = 24 * 60 * 60
        static let downloadRequestTimeoutSeconds: TimeInterval = 45
        static let downloadResourceTimeoutSeconds: TimeInterval = 180
    }

    private let apiClient: any APIClient
    private let fileManager: FileManager
    private let urlSession: URLSession

    init(
        apiClient: any APIClient,
        fileManager: FileManager = .default,
        urlSession: URLSession = DefaultExportService.makeDownloadSession()
    ) {
        self.apiClient = apiClient
        self.fileManager = fileManager
        self.urlSession = urlSession
        cleanupExpiredTemporaryFiles(olderThan: Constants.defaultRetentionSeconds)
    }

    func createExport(
        projectID: UUID,
        type: ComicExportType,
        preset: ComicExportPreset,
        includeCover: Bool = true
    ) async throws -> ComicExportJob {
        do {
            let endpoint = try ExportEndpoints.createExport(
                projectID: projectID,
                type: type,
                preset: preset,
                includeCover: includeCover
            )
            let dto = try await apiClient.request(endpoint, decode: ExportJobCreateResponseDTO.self)
            return ComicExportJob(
                jobID: dto.jobID,
                projectID: dto.projectID ?? projectID,
                type: dto.type ?? type,
                status: dto.status,
                progressPct: nil,
                artifactURL: nil,
                errorCode: nil,
                errorMessage: nil,
                retryable: true
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw map(error)
        }
    }

    func getExportStatus(projectID: UUID, jobID: UUID) async throws -> ComicExportJob {
        do {
            let endpoint = ExportEndpoints.exportStatus(projectID: projectID, jobID: jobID)
            let dto = try await apiClient.request(endpoint, decode: ExportJobStatusResponseDTO.self)
            return ComicExportJob(
                jobID: dto.jobID,
                projectID: dto.projectID,
                type: dto.type,
                status: dto.status,
                progressPct: dto.progressPct,
                artifactURL: dto.artifactURL,
                errorCode: dto.errorCode,
                errorMessage: dto.errorMessage,
                retryable: dto.retryable ?? true
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw map(error)
        }
    }

    func downloadArtifact(
        from remoteURL: URL,
        projectID: UUID,
        jobID: UUID,
        type: ComicExportType
    ) async throws -> URL {
        cleanupExpiredTemporaryFiles(olderThan: Constants.defaultRetentionSeconds)
        let destination = try makeDestinationURL(projectID: projectID, jobID: jobID, type: type, preferredURL: remoteURL)

        if remoteURL.host == "mock.storycomicai.local" {
            let mockData = mockArtifactData(type: type)
            try mockData.write(to: destination, options: .atomic)
            return destination
        }

        do {
            let (temporaryURL, response) = try await urlSession.download(from: remoteURL)
            if let response = response as? HTTPURLResponse {
                guard (200..<300).contains(response.statusCode) else {
                    throw mapDownloadStatusCode(response.statusCode)
                }
            }
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.moveItem(at: temporaryURL, to: destination)
            try validateArtifact(at: destination)
            return destination
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as ExportServiceError {
            throw error
        } catch {
            throw ExportServiceError.downloadFailed
        }
    }

    private func map(_ error: Error) -> ExportServiceError {
        if let serviceError = error as? ExportServiceError {
            return serviceError
        }

        guard let apiError = error as? APIError else {
            return .temporarilyUnavailable
        }

        switch apiError {
        case .unauthorized:
            return .unauthorized

        case let .backend(code, message):
            let fallbackMessage = message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Export request failed."
                : message
            switch code {
            case "PAYWALL_REQUIRED":
                return .paywallLocked
            case "GENERATION_NOT_READY", "EXPORT_NOT_READY":
                return .generationNotReady
            case "EXPORT_NOT_SUPPORTED", "ENDPOINT_NOT_IMPLEMENTED":
                return .featureUnavailable
            case "INVALID_ARTIFACT":
                return .invalidArtifact
            case "RATE_LIMITED":
                return .backend(message: fallbackMessage, retryable: true)
            case "EXPORT_CONFIG_INVALID":
                return .backend(message: fallbackMessage, retryable: false)
            default:
                return .backend(message: fallbackMessage, retryable: true)
            }

        case let .server(statusCode, _):
            if statusCode == 403 {
                return .paywallLocked
            }
            if statusCode == 410 {
                return .invalidArtifact
            }
            if statusCode == 404 || statusCode == 501 {
                return .featureUnavailable
            }
            if statusCode == 409 || statusCode == 422 {
                return .generationNotReady
            }
            if statusCode == 429 {
                return .backend(message: "Export rate limit reached. Please retry shortly.", retryable: true)
            }
            return .temporarilyUnavailable

        case .transport:
            return .temporarilyUnavailable

        case .decoding, .invalidResponse, .emptyResponseData, .invalidURL:
            return .temporarilyUnavailable
        }
    }

    private func cleanupExpiredTemporaryFiles(olderThan retention: TimeInterval) {
        guard let directory = try? temporaryDirectoryURL(createIfNeeded: true) else { return }
        guard let fileURLs = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let threshold = Date().addingTimeInterval(-retention)
        for url in fileURLs {
            guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                  let modifiedDate = values.contentModificationDate,
                  values.isRegularFile == true else { continue }
            if modifiedDate < threshold, fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    private func makeDestinationURL(
        projectID: UUID,
        jobID: UUID,
        type: ComicExportType,
        preferredURL: URL
    ) throws -> URL {
        let directory = try temporaryDirectoryURL(createIfNeeded: true)
        let ext = preferredURL.pathExtension.isEmpty ? defaultExtension(for: type) : preferredURL.pathExtension
        let filename = "project-\(projectID.uuidString)-export-\(jobID.uuidString).\(ext)"
        return directory.appendingPathComponent(filename)
    }

    private func temporaryDirectoryURL(createIfNeeded: Bool) throws -> URL {
        let base = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent(Constants.temporaryDirectoryName, isDirectory: true)
        if createIfNeeded, !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    private func defaultExtension(for type: ComicExportType) -> String {
        switch type {
        case .pdf:
            return "pdf"
        case .imageBundle:
            return "zip"
        }
    }

    private func mockArtifactData(type: ComicExportType) -> Data {
        switch type {
        case .pdf:
            let text = """
            %PDF-1.4
            1 0 obj
            << /Type /Catalog /Pages 2 0 R >>
            endobj
            2 0 obj
            << /Type /Pages /Count 1 /Kids [3 0 R] >>
            endobj
            trailer
            << /Root 1 0 R >>
            %%EOF
            """
            return Data(text.utf8)
        case .imageBundle:
            let text = "Mock image bundle for StoryComicAI export."
            return Data(text.utf8)
        }
    }

    private func validateArtifact(at url: URL) throws {
        let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile == true else {
            throw ExportServiceError.invalidArtifact
        }
        if let fileSize = values.fileSize, fileSize <= 0 {
            throw ExportServiceError.invalidArtifact
        }
    }

    private func mapDownloadStatusCode(_ statusCode: Int) -> ExportServiceError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .paywallLocked
        case 404, 410:
            return .invalidArtifact
        case 409, 422, 425:
            return .generationNotReady
        case 429:
            return .backend(message: "Export rate limit reached. Please retry shortly.", retryable: true)
        case 500...599:
            return .temporarilyUnavailable
        default:
            return .downloadFailed
        }
    }

    private static func makeDownloadSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = Constants.downloadRequestTimeoutSeconds
        configuration.timeoutIntervalForResource = Constants.downloadResourceTimeoutSeconds
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }
}
