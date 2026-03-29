import Foundation

@MainActor
final class PhotoUploadViewModel: ObservableObject {
    @Published private(set) var isUploading: Bool = false
    @Published private(set) var uploadErrorMessage: String?

    private let uploadService: any UploadService

    init(uploadService: any UploadService) {
        self.uploadService = uploadService
    }

    func uploadSelectedPhotos(for flowStore: CreateProjectFlowStore) async -> Bool {
        guard let projectID = flowStore.createdProject?.id else {
            uploadErrorMessage = "Project is missing."
            return false
        }
        guard !flowStore.selectedLocalPhotos.isEmpty else {
            uploadErrorMessage = "Please add at least one photo."
            return false
        }

        isUploading = true
        uploadErrorMessage = nil
        defer { isUploading = false }

        do {
            let uploadedIDs = try await uploadService.uploadAssets(
                projectID: projectID,
                assets: flowStore.selectedLocalPhotos
            )
            flowStore.uploadedPhotoIDs = uploadedIDs
            return true
        } catch {
            uploadErrorMessage = error.userFacingMessage
            return false
        }
    }

    func addMockPhoto(to flowStore: CreateProjectFlowStore) {
        let currentCount = flowStore.selectedLocalPhotos.count + 1
        let photo = LocalPhotoAsset(
            filename: "hero_\(currentCount).jpg",
            data: Data(repeating: UInt8(120 + currentCount), count: 100_000)
        )
        flowStore.selectedLocalPhotos.append(photo)
    }
}
