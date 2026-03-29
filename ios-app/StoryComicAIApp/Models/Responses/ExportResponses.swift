import Foundation

struct ExportJobCreateResponseDTO: Codable {
    let jobID: UUID
    let projectID: UUID?
    let type: ComicExportType?
    let status: ComicExportJobStatus

    enum CodingKeys: String, CodingKey {
        case jobID = "jobId"
        case projectID = "projectId"
        case type
        case status
    }
}

struct ExportJobStatusResponseDTO: Codable {
    let jobID: UUID
    let projectID: UUID
    let type: ComicExportType
    let status: ComicExportJobStatus
    let progressPct: Int?
    let artifactURL: URL?
    let errorCode: String?
    let errorMessage: String?
    let retryable: Bool?

    enum CodingKeys: String, CodingKey {
        case jobID = "jobId"
        case projectID = "projectId"
        case type
        case status
        case progressPct
        case artifactURL = "artifactUrl"
        case errorCode
        case errorMessage
        case retryable
    }
}
