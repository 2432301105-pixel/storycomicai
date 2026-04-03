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
        case .manga: return "Manga"
        case .western: return "Western Comic"
        case .cartoon: return "Cartoon"
        case .cinematic: return "Cinematic"
        case .childrensBook: return "Children's Book"
        }
    }

    var editorialBlurb: String {
        switch self {
        case .manga:
            return "Ink-forward, dramatic framing and high-contrast momentum."
        case .western:
            return "Vintage pulp energy with bold color and collector-print charm."
        case .cartoon:
            return "Stylized character acting with playful shapes and clean rhythm."
        case .cinematic:
            return "Prestige-cover storytelling with dramatic light and polished pacing."
        case .childrensBook:
            return "Warm storybook softness built for giftable keepsake moments."
        }
    }

    var moodLabel: String {
        switch self {
        case .manga: return "Ink Edition"
        case .western: return "Collector Issue"
        case .cartoon: return "Animated Edition"
        case .cinematic: return "Prestige Edition"
        case .childrensBook: return "Storybook Edition"
        }
    }

    var shortSignature: String {
        switch self {
        case .manga:
            return "High-contrast speed lines and ink-forward drama."
        case .western:
            return "Vintage pulp color with bold collector energy."
        case .cartoon:
            return "Expressive shapes and clean animated rhythm."
        case .cinematic:
            return "Prestige framing, dramatic light and premium pacing."
        case .childrensBook:
            return "Warm storybook softness for giftable keepsakes."
        }
    }

    var coverTitle: String {
        switch self {
        case .manga:
            return "Manga"
        case .western:
            return "Western"
        case .cartoon:
            return "Cartoon"
        case .cinematic:
            return "Cinema"
        case .childrensBook:
            return "Storybook"
        }
    }

    var coverSubtitle: String {
        switch self {
        case .manga:
            return "Ink drama"
        case .western:
            return "Collector pulp"
        case .cartoon:
            return "Clean shapes"
        case .cinematic:
            return "Prestige pace"
        case .childrensBook:
            return "Warm keepsake"
        }
    }

    var coverEyebrow: String {
        switch self {
        case .manga:
            return "Ink"
        case .western:
            return "Issue"
        case .cartoon:
            return "Edition"
        case .cinematic:
            return "Prestige"
        case .childrensBook:
            return "Story"
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
