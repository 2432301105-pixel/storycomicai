import Foundation

enum ComicExportType: String, CaseIterable, Identifiable, Codable {
    case pdf
    case imageBundle = "image_bundle"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .pdf:
            return "PDF Export"
        case .imageBundle:
            return "Image Pack"
        }
    }
}

enum ComicExportPreset: String, CaseIterable, Codable {
    case screen
    case print
}

enum ComicExportJobStatus: String, Codable {
    case queued
    case running
    case succeeded
    case failed

    var isTerminal: Bool {
        self == .succeeded || self == .failed
    }
}

struct ComicExportJob: Equatable {
    let jobID: UUID
    let projectID: UUID
    let type: ComicExportType
    let status: ComicExportJobStatus
    let progressPct: Int?
    let artifactURL: URL?
    let errorCode: String?
    let errorMessage: String?
    let retryable: Bool
}
