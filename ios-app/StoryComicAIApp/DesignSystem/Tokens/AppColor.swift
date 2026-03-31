import SwiftUI

enum AppColor {
    static let backgroundPrimary = Color(hex: "F5F0E8")
    static let backgroundSecondary = Color(hex: "ECE3D6")
    static let surface = Color(hex: "FBF7F0")
    static let surfaceElevated = Color(hex: "FFFDFC")
    static let surfaceMuted = Color(hex: "F0E8DC")
    static let pagePaper = Color(hex: "FCF8F2")
    static let border = Color(hex: "D8CDBC")
    static let borderStrong = Color(hex: "BFAE93")

    static let deskTopStart = Color(hex: "6B5343")
    static let deskTopMid = Color(hex: "8B6D58")
    static let deskTopEnd = Color(hex: "B89A80")
    static let bookShadow = Color.black.opacity(0.18)
    static let bookDepthShadow = Color.black.opacity(0.28)
    static let overlayScrim = Color.black.opacity(0.24)
    static let lockedOverlay = Color(hex: "1B1712").opacity(0.62)

    static let textPrimary = Color(hex: "1F1A15")
    static let textSecondary = Color(hex: "5E544A")
    static let textTertiary = Color(hex: "83786E")
    static let textOnDark = Color(hex: "F7F1E7")

    static let accent = Color(hex: "B4873A")
    static let accentSecondary = Color(hex: "E0C28B")
    static let success = Color(hex: "2F7D57")
    static let warning = Color(hex: "A56C22")
    static let error = Color(hex: "A64646")

    static let tabBarBackground = Color(hex: "FBF7F1")
    static let tabBarShadow = Color.black.opacity(0.08)

    static func accent(for style: StoryStyle) -> Color {
        switch style {
        case .manga:
            return Color(hex: "B44645")
        case .western:
            return Color(hex: "8F4A2B")
        case .cartoon:
            return Color(hex: "C98F2A")
        case .cinematic:
            return Color(hex: "B4873A")
        case .childrensBook:
            return Color(hex: "5F9E9D")
        }
    }

    static func accent(for styleLabel: String?) -> Color {
        guard let styleLabel else { return accent }
        switch styleLabel.lowercased() {
        case let value where value.contains("manga"):
            return accent(for: .manga)
        case let value where value.contains("western"):
            return accent(for: .western)
        case let value where value.contains("cartoon"):
            return accent(for: .cartoon)
        case let value where value.contains("child"):
            return accent(for: .childrensBook)
        default:
            return accent(for: .cinematic)
        }
    }
}
