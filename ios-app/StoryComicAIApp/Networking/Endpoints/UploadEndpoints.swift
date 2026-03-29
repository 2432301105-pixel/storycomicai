import Foundation

enum UploadEndpoints {
    static func presign(
        projectID: UUID,
        filename: String,
        mimeType: String,
        sizeBytes: Int
    ) throws -> APIEndpoint {
        APIEndpoint(
            path: "/v1/projects/\(projectID.uuidString)/photos/presign",
            method: .post,
            body: try APIEndpoint.encodeBody(
                PhotoPresignRequestBody(
                    filename: filename,
                    mimeType: mimeType,
                    sizeBytes: sizeBytes
                )
            ),
            requiresAuth: true
        )
    }

    static func complete(
        projectID: UUID,
        photoID: UUID,
        width: Int,
        height: Int,
        isPrimary: Bool
    ) throws -> APIEndpoint {
        APIEndpoint(
            path: "/v1/projects/\(projectID.uuidString)/photos/complete",
            method: .post,
            body: try APIEndpoint.encodeBody(
                PhotoCompleteRequestBody(
                    photoID: photoID,
                    width: width,
                    height: height,
                    isPrimary: isPrimary
                )
            ),
            requiresAuth: true
        )
    }
}
