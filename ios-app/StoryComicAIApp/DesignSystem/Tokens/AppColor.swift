import SwiftUI

enum AppColor {
    static let backgroundPrimary = Color(hex: "F8F2E9")
    static let backgroundSecondary = Color(hex: "F1E7D8")
    static let backgroundCanvas = Color(hex: "F6EFE5")
    static let backgroundInkWash = Color(hex: "EADBC6")
    static let surface = Color(hex: "FFFDF9")
    static let surfaceElevated = Color(hex: "FFFFFF")
    static let surfaceMuted = Color(hex: "F7EFE4")
    static let surfaceInset = Color(hex: "EFE4D4")
    static let pagePaper = Color(hex: "FEFBF5")
    static let border = Color(hex: "E3D7C7")
    static let borderStrong = Color(hex: "CDB798")
    static let borderFoil = Color(hex: "CFA25C")

    static let deskTopStart = Color(hex: "6B5343")
    static let deskTopMid = Color(hex: "8B6D58")
    static let deskTopEnd = Color(hex: "B89A80")
    static let bookShadow = Color.black.opacity(0.12)
    static let bookDepthShadow = Color.black.opacity(0.20)
    static let overlayScrim = Color.black.opacity(0.18)
    static let lockedOverlay = Color(hex: "1B1712").opacity(0.62)
    static let halftoneInk = Color(hex: "786B5B").opacity(0.08)
    static let spotlight = Color.white.opacity(0.68)

    static let textPrimary = Color(hex: "211B16")
    static let textSecondary = Color(hex: "61574D")
    static let textTertiary = Color(hex: "8A7E72")
    static let textOnDark = Color(hex: "F7F1E7")

    static let accent = Color(hex: "C28D38")
    static let accentSecondary = Color(hex: "E5C281")
    static let success = Color(hex: "2F7D57")
    static let warning = Color(hex: "A56C22")
    static let error = Color(hex: "A64646")

    static let tabBarBackground = Color(hex: "FCF8F1")
    static let tabBarShadow = Color.black.opacity(0.06)
    static let tabBarBorder = Color(hex: "E2D5C5")

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
