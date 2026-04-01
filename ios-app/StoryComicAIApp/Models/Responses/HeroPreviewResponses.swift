import Foundation

struct HeroPreviewStartResponseDTO: Codable {
    let jobID: UUID
    let status: String
    let currentStage: String

    init(jobID: UUID, status: String, currentStage: String) {
        self.jobID = jobID
        self.status = status
        self.currentStage = currentStage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        jobID = try container.decode(UUID.self, forAnyKey: ["jobId", "job_id"])
        status = try container.decode(String.self, forAnyKey: ["status"])
        currentStage = try container.decode(String.self, forAnyKey: ["currentStage", "current_stage"])
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        try container.encode(jobID, forKey: AnyCodingKey("jobId"))
        try container.encode(status, forKey: AnyCodingKey("status"))
        try container.encode(currentStage, forKey: AnyCodingKey("currentStage"))
    }
}

struct HeroPreviewStatusResponseDTO: Codable {
    let jobID: UUID
    let projectID: UUID
    let status: String
    let currentStage: String
    let progressPct: Int
    let result: HeroPreviewResultDTO?
    let errorMessage: String?

    init(
        jobID: UUID,
        projectID: UUID,
        status: String,
        currentStage: String,
        progressPct: Int,
        result: HeroPreviewResultDTO?,
        errorMessage: String?
    ) {
        self.jobID = jobID
        self.projectID = projectID
        self.status = status
        self.currentStage = currentStage
        self.progressPct = progressPct
        self.result = result
        self.errorMessage = errorMessage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        jobID = try container.decode(UUID.self, forAnyKey: ["jobId", "job_id"])
        projectID = try container.decode(UUID.self, forAnyKey: ["projectId", "project_id"])
        status = try container.decode(String.self, forAnyKey: ["status"])
        currentStage = try container.decode(String.self, forAnyKey: ["currentStage", "current_stage"])
        progressPct = try container.decodeIfPresent(Int.self, forAnyKey: ["progressPct", "progress_pct"]) ?? 0
        result = try container.decodeIfPresent(HeroPreviewResultDTO.self, forAnyKey: ["result"])
        errorMessage = try container.decodeIfPresent(String.self, forAnyKey: ["errorMessage", "error_message"])
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        try container.encode(jobID, forKey: AnyCodingKey("jobId"))
        try container.encode(projectID, forKey: AnyCodingKey("projectId"))
        try container.encode(status, forKey: AnyCodingKey("status"))
        try container.encode(currentStage, forKey: AnyCodingKey("currentStage"))
        try container.encode(progressPct, forKey: AnyCodingKey("progressPct"))
        try container.encodeIfPresent(result, forKey: AnyCodingKey("result"))
        try container.encodeIfPresent(errorMessage, forKey: AnyCodingKey("errorMessage"))
    }
}

struct HeroPreviewResultDTO: Codable {
    let heroSheetVersion: Int
    let style: String
    let previewAssets: HeroPreviewAssetURLsDTO
    let consistencySeed: String
}

struct HeroPreviewAssetURLsDTO: Codable {
    let front: URL?
    let threeQuarter: URL?
    let side: URL?
}
