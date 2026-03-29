import Foundation

struct CreateExportRequestBody: Codable {
    let type: ComicExportType
    let preset: ComicExportPreset
    let includeCover: Bool

    enum CodingKeys: String, CodingKey {
        case type
        case preset
        case includeCover
    }
}
