import SwiftUI

enum AppColor {
    // ─── Canvas ───────────────────────────────────────────────────────────────
    /// Deep ink black — primary background
    static let inkBlack      = Color(hex: "0C0B09")
    /// Warm near-black — elevated surfaces
    static let inkDeep       = Color(hex: "141210")
    /// Panel surface — card backgrounds
    static let inkPanel      = Color(hex: "1C1A16")
    /// Subtle panel border
    static let inkMuted      = Color(hex: "2A2722")

    // ─── Paper ────────────────────────────────────────────────────────────────
    /// Aged comic paper — primary light surface
    static let paper         = Color(hex: "F4EDD8")
    /// Bright panel white
    static let panelWhite    = Color(hex: "FAFAF6")
    /// Paper shadow / inset
    static let paperDim      = Color(hex: "E8DFC8")

    // ─── Ink text ─────────────────────────────────────────────────────────────
    static let textPrimary   = Color(hex: "F4EDD8")   // cream on dark
    static let textSecondary = Color(hex: "9B9284")
    static let textTertiary  = Color(hex: "5E5A52")
    static let textOnLight   = Color(hex: "0C0B09")   // ink on paper

    // ─── Accent ───────────────────────────────────────────────────────────────
    /// Comic action red
    static let comicRed      = Color(hex: "E8351D")
    /// Comic yellow highlight
    static let comicYellow   = Color(hex: "F7C948")
    /// Comic blue
    static let comicBlue     = Color(hex: "2D5BFF")
    /// Default accent (yellow)
    static let accent        = Color(hex: "F7C948")
    static let accentSecondary = Color(hex: "E8351D")

    // ─── Semantic ─────────────────────────────────────────────────────────────
    static let success       = Color(hex: "2FA86E")
    static let warning       = Color(hex: "F7C948")
    static let error         = Color(hex: "E8351D")

    // ─── Halftone / texture ───────────────────────────────────────────────────
    static let halftoneDot   = Color(hex: "F4EDD8").opacity(0.04)
    static let panelBorder   = Color(hex: "F4EDD8").opacity(0.10)
    static let panelBorderStrong = Color(hex: "F4EDD8").opacity(0.20)

    // ─── Legacy aliases (for untouched views) ─────────────────────────────────
    static let backgroundPrimary    = inkBlack
    static let backgroundSecondary  = inkDeep
    static let backgroundCanvas     = inkBlack
    static let backgroundInkWash    = inkPanel
    static let surface              = inkPanel
    static let surfaceElevated      = inkDeep
    static let surfaceMuted         = inkPanel
    static let surfaceInset         = inkMuted
    static let pagePaper            = paper
    static let border               = panelBorder
    static let borderStrong         = panelBorderStrong
    static let borderFoil           = comicYellow.opacity(0.6)
    static let deskTopStart         = Color(hex: "141210")
    static let deskTopMid           = Color(hex: "1C1A16")
    static let deskTopEnd           = Color(hex: "2A2722")
    static let bookShadow           = Color.black.opacity(0.4)
    static let bookDepthShadow      = Color.black.opacity(0.6)
    static let overlayScrim         = Color.black.opacity(0.5)
    static let lockedOverlay        = Color.black.opacity(0.72)
    static let halftoneInk          = halftoneDot
    static let spotlight            = Color.white.opacity(0.06)
    static let tabBarBackground     = inkDeep
    static let tabBarShadow         = Color.black.opacity(0.3)
    static let tabBarBorder         = panelBorder
    static let comicInk             = inkBlack
    static let comicCream           = paper
    static let comicTeal            = Color(hex: "2FA8A0")
    static let comicBerry           = Color(hex: "E24A76")
    static let comicViolet          = Color(hex: "7B5CF0")
    static let comicOrange          = Color(hex: "F07840")

    // ─── Style accents ────────────────────────────────────────────────────────
    static func accent(for style: StoryStyle) -> Color {
        switch style {
        case .manga:         return Color(hex: "E8351D")
        case .western:       return Color(hex: "C97A3A")
        case .cartoon:       return Color(hex: "F7C948")
        case .cinematic:     return Color(hex: "2D5BFF")
        case .childrensBook: return Color(hex: "2FA8A0")
        }
    }

    static func accent(for styleLabel: String?) -> Color {
        guard let styleLabel else { return accent }
        switch styleLabel.lowercased() {
        case let v where v.contains("manga"):   return accent(for: .manga)
        case let v where v.contains("western"): return accent(for: .western)
        case let v where v.contains("cartoon"): return accent(for: .cartoon)
        case let v where v.contains("child"):   return accent(for: .childrensBook)
        default:                                return accent(for: .cinematic)
        }
    }
}
