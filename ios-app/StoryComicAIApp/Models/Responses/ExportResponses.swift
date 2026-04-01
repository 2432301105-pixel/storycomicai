import Foundation

struct ExportJobCreateResponseDTO: Codable {
    let jobID: UUID
    let projectID: UUID?
    let type: ComicExportType?
    let status: ComicExportJobStatus

    init(jobID: UUID, projectID: UUID?, type: ComicExportType?, status: ComicExportJobStatus) {
        self.jobID = jobID
        self.projectID = projectID
        self.type = type
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        jobID = try container.decode(UUID.self, forAnyKey: ["jobId", "job_id"])
        projectID = try container.decodeIfPresent(UUID.self, forAnyKey: ["projectId", "project_id"])
        type = try container.decodeIfPresent(ComicExportType.self, forAnyKey: ["type"])
        status = try container.decode(ComicExportJobStatus.self, forAnyKey: ["status"])
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        try container.encode(jobID, forKey: AnyCodingKey("jobId"))
        try container.encodeIfPresent(projectID, forKey: AnyCodingKey("projectId"))
        try container.encodeIfPresent(type, forKey: AnyCodingKey("type"))
        try container.encode(status, forKey: AnyCodingKey("status"))
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

    init(
        jobID: UUID,
        projectID: UUID,
        type: ComicExportType,
        status: ComicExportJobStatus,
        progressPct: Int?,
        artifactURL: URL?,
        errorCode: String?,
        errorMessage: String?,
        retryable: Bool?
    ) {
        self.jobID = jobID
        self.projectID = projectID
        self.type = type
        self.status = status
        self.progressPct = progressPct
        self.artifactURL = artifactURL
        self.errorCode = errorCode
        self.errorMessage = errorMessage
        self.retryable = retryable
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        jobID = try container.decode(UUID.self, forAnyKey: ["jobId", "job_id"])
        projectID = try container.decode(UUID.self, forAnyKey: ["projectId", "project_id"])
        type = try container.decode(ComicExportType.self, forAnyKey: ["type"])
        status = try container.decode(ComicExportJobStatus.self, forAnyKey: ["status"])
        progressPct = try container.decodeIfPresent(Int.self, forAnyKey: ["progressPct", "progress_pct"])
        artifactURL = try container.decodeIfPresent(URL.self, forAnyKey: ["artifactUrl", "artifact_url"])
        errorCode = try container.decodeIfPresent(String.self, forAnyKey: ["errorCode", "error_code"])
        errorMessage = try container.decodeIfPresent(String.self, forAnyKey: ["errorMessage", "error_message"])
        retryable = try container.decodeIfPresent(Bool.self, forAnyKey: ["retryable"])
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        try container.encode(jobID, forKey: AnyCodingKey("jobId"))
        try container.encode(projectID, forKey: AnyCodingKey("projectId"))
        try container.encode(type, forKey: AnyCodingKey("type"))
        try container.encode(status, forKey: AnyCodingKey("status"))
        try container.encodeIfPresent(progressPct, forKey: AnyCodingKey("progressPct"))
        try container.encodeIfPresent(artifactURL, forKey: AnyCodingKey("artifactUrl"))
        try container.encodeIfPresent(errorCode, forKey: AnyCodingKey("errorCode"))
        try container.encodeIfPresent(errorMessage, forKey: AnyCodingKey("errorMessage"))
        try container.encodeIfPresent(retryable, forKey: AnyCodingKey("retryable"))
    }
}
