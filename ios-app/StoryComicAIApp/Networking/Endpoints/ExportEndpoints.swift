import Foundation

enum ExportEndpoints {
    static func createExport(
        projectID: UUID,
        type: ComicExportType,
        preset: ComicExportPreset,
        includeCover: Bool
    ) throws -> APIEndpoint {
        APIEndpoint(
            path: "/v1/projects/\(projectID.uuidString)/exports",
            method: .post,
            body: try APIEndpoint.encodeBody(
                CreateExportRequestBody(
                    type: type,
                    preset: preset,
                    includeCover: includeCover
                )
            ),
            requiresAuth: true
        )
    }

    static func exportStatus(projectID: UUID, jobID: UUID) -> APIEndpoint {
        APIEndpoint(
            path: "/v1/projects/\(projectID.uuidString)/exports/\(jobID.uuidString)",
            method: .get,
            requiresAuth: true
        )
    }
}
