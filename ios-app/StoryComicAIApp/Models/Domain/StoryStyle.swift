import Foundation

enum StoryStyle: String, CaseIterable, Codable, Identifiable {
    case manga
    case western
    case cartoon
    case cinematic
    case childrensBook = "childrens_book"

    var id: String { rawValue }

    init?(displayLabel: String) {
        let normalized = displayLabel
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch normalized {
        case "manga":
            self = .manga
        case "western", "western comic":
            self = .western
        case "cartoon":
            self = .cartoon
        case "cinematic":
            self = .cinematic
        case "children's book", "childrens book", "childrens_book":
            self = .childrensBook
        default:
            return nil
        }
    }

    var displayName: String {
        switch self {
        case .manga: return L10n.string("style.manga.name")
        case .western: return L10n.string("style.western.name")
        case .cartoon: return L10n.string("style.cartoon.name")
        case .cinematic: return L10n.string("style.cinematic.name")
        case .childrensBook: return L10n.string("style.childrens.name")
        }
    }

    var editorialBlurb: String {
        switch self {
        case .manga:
            return L10n.string("style.manga.blurb")
        case .western:
            return L10n.string("style.western.blurb")
        case .cartoon:
            return L10n.string("style.cartoon.blurb")
        case .cinematic:
            return L10n.string("style.cinematic.blurb")
        case .childrensBook:
            return L10n.string("style.childrens.blurb")
        }
    }

    var moodLabel: String {
        switch self {
        case .manga: return L10n.string("style.manga.mood")
        case .western: return L10n.string("style.western.mood")
        case .cartoon: return L10n.string("style.cartoon.mood")
        case .cinematic: return L10n.string("style.cinematic.mood")
        case .childrensBook: return L10n.string("style.childrens.mood")
        }
    }

    var shortSignature: String {
        switch self {
        case .manga:
            return L10n.string("style.manga.signature")
        case .western:
            return L10n.string("style.western.signature")
        case .cartoon:
            return L10n.string("style.cartoon.signature")
        case .cinematic:
            return L10n.string("style.cinematic.signature")
        case .childrensBook:
            return L10n.string("style.childrens.signature")
        }
    }

    var coverTitle: String {
        switch self {
        case .manga: return L10n.string("style.manga.cover_title")
        case .western: return L10n.string("style.western.cover_title")
        case .cartoon: return L10n.string("style.cartoon.cover_title")
        case .cinematic: return L10n.string("style.cinematic.cover_title")
        case .childrensBook: return L10n.string("style.childrens.cover_title")
        }
    }

    var coverSubtitle: String {
        switch self {
        case .manga: return L10n.string("style.manga.cover_subtitle")
        case .western: return L10n.string("style.western.cover_subtitle")
        case .cartoon: return L10n.string("style.cartoon.cover_subtitle")
        case .cinematic: return L10n.string("style.cinematic.cover_subtitle")
        case .childrensBook: return L10n.string("style.childrens.cover_subtitle")
        }
    }

    var coverEyebrow: String {
        switch self {
        case .manga: return L10n.string("style.manga.cover_eyebrow")
        case .western: return L10n.string("style.western.cover_eyebrow")
        case .cartoon: return L10n.string("style.cartoon.cover_eyebrow")
        case .cinematic: return L10n.string("style.cinematic.cover_eyebrow")
        case .childrensBook: return L10n.string("style.childrens.cover_eyebrow")
        }
    }

    var accentHex: String {
        switch self {
        case .manga:
            return "E63946"
        case .western:
            return "D62828"
        case .cartoon:
            return "F4A261"
        case .cinematic:
            return "C9A84C"
        case .childrensBook:
            return "48CAE4"
        }
    }
}
