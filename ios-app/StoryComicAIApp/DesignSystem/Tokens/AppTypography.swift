import SwiftUI

enum AppTypography {
    // ─── Display — comic cover titling ────────────────────────────────────────
    /// 64pt — hero / splash screens
    static let display           = Font.system(size: 64, weight: .black, design: .serif)
    /// 48pt — section hero
    static let displayMid        = Font.system(size: 48, weight: .black, design: .serif)
    /// 36pt — page title
    static let title             = Font.system(size: 36, weight: .bold, design: .serif)
    /// 28pt — card heading
    static let heading           = Font.system(size: 28, weight: .bold, design: .serif)
    /// 22pt — section header
    static let section           = Font.system(size: 22, weight: .semibold, design: .serif)

    // ─── Body ─────────────────────────────────────────────────────────────────
    static let body              = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyStrong        = Font.system(size: 16, weight: .semibold, design: .default)
    static let footnote          = Font.system(size: 14, weight: .regular, design: .default)

    // ─── UI micro ─────────────────────────────────────────────────────────────
    static let button            = Font.system(size: 16, weight: .bold, design: .default)
    static let caption           = Font.system(size: 13, weight: .medium, design: .default)
    static let meta              = Font.system(size: 11, weight: .semibold, design: .default)
    /// ALL CAPS label — tracking 2.0
    static let eyebrow           = Font.system(size: 11, weight: .bold, design: .default)
    static let badge             = Font.system(size: 10, weight: .black, design: .default)

    // ─── Cover cards ──────────────────────────────────────────────────────────
    static let coverTitle        = Font.system(size: 40, weight: .black, design: .serif)
    static let coverCompactTitle = Font.system(size: 18, weight: .black, design: .serif)
    static let coverCompactDisplay = Font.system(size: 16, weight: .black, design: .serif)
    static let coverCompactLabel = Font.system(size: 9, weight: .bold, design: .default)
    static let coverCompactMeta  = Font.system(size: 9, weight: .semibold, design: .default)
    static let coverMeta         = Font.system(size: 12, weight: .semibold, design: .default)
}
