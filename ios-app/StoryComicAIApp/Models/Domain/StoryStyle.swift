import Foundation

enum StoryStyle: String, CaseIterable, Codable, Identifiable {
    case manga
    case western
    case cartoon
    case cinematic
    case childrensBook = "childrens_book"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .manga: return "Manga"
        case .western: return "Western Comic"
        case .cartoon: return "Cartoon"
        case .cinematic: return "Cinematic"
        case .childrensBook: return "Children's Book"
        }
    }
}
