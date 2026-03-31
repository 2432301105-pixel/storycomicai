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
}
