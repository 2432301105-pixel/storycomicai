import Foundation

struct PhotoPresignResult: Equatable {
    let photoID: UUID
    let uploadURL: URL
    let storageKey: String
    let expiresInSeconds: Int
}

struct PhotoCompleteResult: Equatable {
    let photoID: UUID
    let status: String
    let qualityScore: Double?
}

struct LocalPhotoAsset: Identifiable, Hashable {
    let id: UUID
    let filename: String
    let mimeType: String
    let width: Int
    let height: Int
    let data: Data

    init(
        id: UUID = UUID(),
        filename: String,
        mimeType: String = "image/jpeg",
        width: Int = 1024,
        height: Int = 1024,
        data: Data
    ) {
        self.id = id
        self.filename = filename
        self.mimeType = mimeType
        self.width = width
        self.height = height
        self.data = data
    }
}
