import Foundation

protocol UploadService: AnyObject {
    func presignPhoto(
        projectID: UUID,
        filename: String,
        mimeType: String,
        sizeBytes: Int
    ) async throws -> PhotoPresignResult

    func completePhoto(
        projectID: UUID,
        photoID: UUID,
        width: Int,
        height: Int,
        isPrimary: Bool
    ) async throws -> PhotoCompleteResult

    func uploadAssets(projectID: UUID, assets: [LocalPhotoAsset]) async throws -> [UUID]
}

final class DefaultUploadService: UploadService {
    private let apiClient: any APIClient
    private let transferClient: any UploadTransferClient

    init(apiClient: any APIClient, transferClient: any UploadTransferClient) {
        self.apiClient = apiClient
        self.transferClient = transferClient
    }

    func presignPhoto(
        projectID: UUID,
        filename: String,
        mimeType: String,
        sizeBytes: Int
    ) async throws -> PhotoPresignResult {
        let endpoint = try UploadEndpoints.presign(
            projectID: projectID,
            filename: filename,
            mimeType: mimeType,
            sizeBytes: sizeBytes
        )
        let dto = try await apiClient.request(endpoint, decode: PhotoPresignResponseDTO.self)
        return PhotoPresignResult(
            photoID: dto.photoID,
            uploadURL: dto.uploadURL,
            storageKey: dto.storageKey,
            expiresInSeconds: dto.expiresInSeconds
        )
    }

    func completePhoto(
        projectID: UUID,
        photoID: UUID,
        width: Int,
        height: Int,
        isPrimary: Bool
    ) async throws -> PhotoCompleteResult {
        let endpoint = try UploadEndpoints.complete(
            projectID: projectID,
            photoID: photoID,
            width: width,
            height: height,
            isPrimary: isPrimary
        )
        let dto = try await apiClient.request(endpoint, decode: PhotoCompleteResponseDTO.self)
        return PhotoCompleteResult(photoID: dto.photoID, status: dto.status, qualityScore: dto.qualityScore)
    }

    func uploadAssets(projectID: UUID, assets: [LocalPhotoAsset]) async throws -> [UUID] {
        var uploadedIDs: [UUID] = []

        for (index, asset) in assets.enumerated() {
            let presigned = try await presignPhoto(
                projectID: projectID,
                filename: asset.filename,
                mimeType: asset.mimeType,
                sizeBytes: asset.data.count
            )

            try await transferClient.upload(data: asset.data, to: presigned.uploadURL, mimeType: asset.mimeType)

            _ = try await completePhoto(
                projectID: projectID,
                photoID: presigned.photoID,
                width: asset.width,
                height: asset.height,
                isPrimary: index == 0
            )
            uploadedIDs.append(presigned.photoID)
        }

        return uploadedIDs
    }
}
