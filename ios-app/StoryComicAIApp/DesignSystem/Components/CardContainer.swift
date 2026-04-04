import SwiftUI

struct CardContainer<Content: View>: View {
    let emphasize: Bool
    let content: Content

    init(emphasize: Bool = false, @ViewBuilder content: () -> Content) {
        self.emphasize = emphasize
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.md)
            .background(background)
            .overlay(border)
            .clipShape(RoundedRectangle(cornerRadius: AppElevation.Surface.radius, style: .continuous))
            .shadow(
                color: AppColor.bookShadow.opacity(emphasize ? 1 : 0.72),
                radius: emphasize ? 22 : AppElevation.Surface.shadowRadius,
                x: 0,
                y: emphasize ? 12 : AppElevation.Surface.shadowYOffset
            )
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: AppElevation.Surface.radius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: emphasize
                        ? [AppColor.surfaceElevated, AppColor.surface, AppColor.surfaceMuted.opacity(0.55)]
                        : [AppColor.surfaceElevated, AppColor.surface, AppColor.surfaceMuted.opacity(0.46)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .topLeading) {
                LinearGradient(
                    colors: [Color.white.opacity(0.58), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: AppElevation.Surface.radius, style: .continuous))
            }
            .overlay(alignment: .bottomTrailing) {
                RadialGradient(
                    colors: [AppColor.accentSecondary.opacity(emphasize ? 0.08 : 0.04), .clear],
                    center: .center,
                    startRadius: 4,
                    endRadius: 110
                )
                .frame(width: 180, height: 180)
                .offset(x: 26, y: 26)
            }
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: AppElevation.Surface.radius, style: .continuous)
            .stroke(
                emphasize ? AppColor.borderFoil.opacity(0.68) : AppColor.border.opacity(0.78),
                lineWidth: emphasize ? 1.1 : 1
            )
    }
}

struct EditorialBackground: View {
    let accent: Color
    let showsDeskBand: Bool

    init(accent: Color = AppColor.accent, showsDeskBand: Bool = false) {
        self.accent = accent
        self.showsDeskBand = showsDeskBand
    }

    var body: some View {
        ZStack {
            AppColor.backgroundPrimary

            LinearGradient(
                colors: [Color.white.opacity(0.44), .clear, AppColor.backgroundInkWash.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [AppColor.spotlight, .clear],
                center: .top,
                startRadius: 12,
                endRadius: 520
            )
            .blendMode(.screen)

            RadialGradient(
                colors: [accent.opacity(0.1), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 320
            )

            HalftoneWash()
                .blendMode(.multiply)
                .opacity(0.08)

            if showsDeskBand {
                LinearGradient(
                    colors: [AppColor.deskTopStart.opacity(0.92), AppColor.deskTopMid.opacity(0.88), AppColor.deskTopEnd.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(maxHeight: .infinity, alignment: .bottom)
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [AppColor.overlayScrim.opacity(0.14), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 84)
                }
                .mask(
                    LinearGradient(
                        colors: [.clear, .clear, .black.opacity(0.4), .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .ignoresSafeArea()
    }
}

private struct HalftoneWash: View {
    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let step: CGFloat = 22
                let radius: CGFloat = 0.9
                var path = Path()

                stride(from: CGFloat(0), through: size.height, by: step).forEach { y in
                    stride(from: CGFloat(0), through: size.width, by: step).forEach { x in
                        let normalizedY = y / max(size.height, 1)
                        let normalizedX = x / max(size.width, 1)
                        let intensity = (1 - normalizedY) * 0.44 + normalizedX * 0.08
                        guard intensity > 0.18 else { return }
                        let rect = CGRect(x: x, y: y, width: radius * 2, height: radius * 2)
                        path.addEllipse(in: rect)
                    }
                }

                context.fill(path, with: .color(AppColor.halftoneInk))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
    }
}

enum ComicCoverPresentation {
    case standard
    case compact
}

enum CompactCoverVariant: String, CaseIterable, Identifiable {
    case bamBurst
    case signalSlash
    case noirHalftone
    case popRibbon
    case skylineBeam
    case pulseFrame
    case emberStamp

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bamBurst: return "Bam Burst"
        case .signalSlash: return "Signal Slash"
        case .noirHalftone: return "Noir Halftone"
        case .popRibbon: return "Pop Ribbon"
        case .skylineBeam: return "Skyline Beam"
        case .pulseFrame: return "Pulse Frame"
        case .emberStamp: return "Ember Stamp"
        }
    }

    static func automatic(style: StoryStyle, title: String) -> CompactCoverVariant {
        let variants = CompactCoverVariant.allCases
        let seed = abs("\(style.rawValue)-\(title)".hashValue)
        return variants[seed % variants.count]
    }
}

private struct CompactComicPalette {
    let backdrop: [Color]
    let ink: Color
    let paper: Color
    let flash: Color
    let punch: Color
    let glow: Color
    let halftone: Color
}

struct ComicCoverCard: View {
    let title: String
    let subtitle: String?
    let accent: Color
    let style: StoryStyle?
    let eyebrow: String
    let badge: String?
    let emphasize: Bool
    let presentation: ComicCoverPresentation
    let compactVariant: CompactCoverVariant?

    init(
        title: String,
        subtitle: String? = nil,
        accent: Color,
        style: StoryStyle? = nil,
        eyebrow: String,
        badge: String? = nil,
        emphasize: Bool = false,
        presentation: ComicCoverPresentation = .standard,
        compactVariant: CompactCoverVariant? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
        self.style = style
        self.eyebrow = eyebrow
        self.badge = badge
        self.emphasize = emphasize
        self.presentation = presentation
        self.compactVariant = compactVariant
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompact = presentation == .compact || proxy.size.width < 132

            Group {
                if isCompact {
                    compactCard(in: proxy.size)
                } else {
                    standardCard
                }
            }
        }
        .aspectRatio(presentation == .compact ? 0.84 : 2 / 3, contentMode: .fit)
    }

    private var standardCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: AppElevation.Cover.radius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.9), AppColor.textPrimary, AppColor.textPrimary.opacity(0.96)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: AppElevation.Cover.radius - 5, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        .padding(6)
                }
                .overlay(alignment: .leading) {
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.04), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: AppElevation.Cover.spineWidth)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: AppElevation.Cover.radius,
                            bottomLeadingRadius: AppElevation.Cover.radius,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 0
                        )
                    )
                }
                .overlay(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.14))
                        .frame(width: 88, height: 40)
                        .overlay {
                            Text(styleStamp)
                                .font(AppTypography.badge)
                                .foregroundStyle(AppColor.textOnDark.opacity(0.88))
                                .tracking(1.0)
                        }
                        .padding(AppSpacing.md)
                }
                .overlay(alignment: .topTrailing) {
                    if let badge {
                        Text(badge)
                            .font(AppTypography.badge)
                            .foregroundStyle(AppColor.textOnDark.opacity(0.95))
                            .tracking(0.8)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xs)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                            .padding(AppSpacing.md)
                    }
                }
                .overlay {
                    coverPattern
                        .blendMode(.screen)
                        .opacity(0.28)
                }
                .shadow(
                    color: AppColor.bookDepthShadow.opacity(emphasize ? 1 : 0.76),
                    radius: emphasize ? AppElevation.Cover.shadowRadius + 6 : AppElevation.Cover.shadowRadius,
                    x: 0,
                    y: emphasize ? AppElevation.Cover.shadowYOffset + 4 : AppElevation.Cover.shadowYOffset
                )

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(eyebrow)
                    .font(AppTypography.coverMeta)
                    .foregroundStyle(AppColor.textOnDark.opacity(0.8))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 0)

                Text(title)
                    .font(AppTypography.coverTitle)
                    .foregroundStyle(AppColor.textOnDark)
                    .lineLimit(3)
                    .minimumScaleFactor(0.56)
                    .allowsTightening(true)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textOnDark.opacity(0.82))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.78)
                }
            }
            .padding(AppSpacing.lg)
        }
    }

    private func compactCard(in size: CGSize) -> some View {
        let variant = resolvedCompactVariant
        let palette = compactPalette(for: variant)

        return ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: palette.backdrop,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    compactBackgroundArt(variant: variant, palette: palette, size: size)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        .padding(5)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppColor.comicInk.opacity(0.18), lineWidth: 1.6)
                }
                .shadow(
                    color: AppColor.bookDepthShadow.opacity(emphasize ? 0.28 : 0.18),
                    radius: emphasize ? 22 : 18,
                    x: 0,
                    y: emphasize ? 14 : 10
                )

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(alignment: .top) {
                    Text(compactEyebrowText)
                        .font(AppTypography.coverCompactLabel)
                        .foregroundStyle(palette.ink)
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(palette.paper.opacity(0.94))
                        .clipShape(Capsule())

                    Spacer(minLength: 0)

                    Text(compactTokenText)
                        .font(AppTypography.coverCompactLabel)
                        .foregroundStyle(palette.paper)
                        .tracking(0.8)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(AppColor.comicInk.opacity(0.76))
                        .clipShape(Capsule())
                }

                Spacer(minLength: size.height * 0.08)

                Text(compactDisplayTitle)
                    .font(AppTypography.coverCompactDisplay)
                    .foregroundStyle(palette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)
                    .allowsTightening(true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background {
                        compactTitlePlate(variant: variant, palette: palette)
                    }

                Spacer(minLength: 0)

                Text(compactFooterText)
                    .font(AppTypography.coverCompactMeta)
                    .foregroundStyle(palette.paper)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(AppColor.comicInk.opacity(0.24))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(12)
        }
    }

    private var coverPattern: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
                switch resolvedStyle {
                case .manga:
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: proxy.size.width * 0.68)
                        .offset(x: proxy.size.width * 0.18, y: -proxy.size.width * 0.2)

                    ForEach(0..<6, id: \.self) { index in
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.07 : 0.12))
                            .frame(width: proxy.size.width * 0.9, height: 12)
                            .rotationEffect(.degrees(-36))
                            .offset(
                                x: proxy.size.width * 0.12,
                                y: proxy.size.height * (0.14 + (Double(index) * 0.095))
                            )
                    }

                case .western:
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: proxy.size.width * 0.72)
                        .offset(x: proxy.size.width * 0.14, y: -proxy.size.width * 0.12)

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: proxy.size.width * 0.86, height: 42)
                        .rotationEffect(.degrees(-24))
                        .offset(x: proxy.size.width * 0.18, y: proxy.size.height * 0.18)

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .stroke(Color.white.opacity(0.13), lineWidth: 1)
                        .frame(width: proxy.size.width * 0.76, height: proxy.size.height * 0.32)
                        .rotationEffect(.degrees(-12))
                        .offset(x: proxy.size.width * 0.08, y: proxy.size.height * 0.38)

                case .cartoon:
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: proxy.size.width * 0.54)
                        .offset(x: proxy.size.width * 0.16, y: -proxy.size.width * 0.18)

                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: proxy.size.width * 0.34)
                        .offset(x: -proxy.size.width * 0.08, y: proxy.size.height * 0.22)

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: proxy.size.width * 0.72, height: 34)
                        .rotationEffect(.degrees(-18))
                        .offset(x: proxy.size.width * 0.18, y: proxy.size.height * 0.42)

                case .cinematic:
                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: proxy.size.width * 0.72)
                        .offset(x: proxy.size.width * 0.18, y: -proxy.size.width * 0.22)
                        .blur(radius: 2)

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: proxy.size.width * 0.9, height: 34)
                        .rotationEffect(.degrees(-28))
                        .offset(x: proxy.size.width * 0.22, y: proxy.size.height * 0.18)

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .frame(width: proxy.size.width * 0.8, height: 28)
                        .rotationEffect(.degrees(-28))
                        .offset(x: proxy.size.width * 0.12, y: proxy.size.height * 0.34)

                case .childrensBook:
                    Circle()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: proxy.size.width * 0.58)
                        .offset(x: proxy.size.width * 0.14, y: -proxy.size.width * 0.16)

                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: proxy.size.width * 0.4)
                        .offset(x: -proxy.size.width * 0.05, y: proxy.size.height * 0.18)

                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.07))
                        .frame(width: proxy.size.width * 0.7, height: 30)
                        .offset(x: proxy.size.width * 0.12, y: proxy.size.height * 0.46)

                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: proxy.size.width * 0.54, height: 24)
                        .offset(x: -proxy.size.width * 0.06, y: proxy.size.height * 0.56)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    @ViewBuilder
    private func compactBackgroundArt(variant: CompactCoverVariant, palette: CompactComicPalette, size: CGSize) -> some View {
        ZStack {
            switch variant {
            case .bamBurst:
                ComicHalftoneDots(color: palette.halftone, dotSize: 2.2, spacing: 11)
                    .opacity(0.34)

                ComicBurstShape(points: 9, innerRatio: 0.56)
                    .fill(palette.flash)
                    .frame(width: size.width * 0.62, height: size.width * 0.62)
                    .offset(x: size.width * 0.22, y: -size.height * 0.24)

                ComicBurstShape(points: 9, innerRatio: 0.56)
                    .stroke(AppColor.comicInk, lineWidth: 5)
                    .frame(width: size.width * 0.62, height: size.width * 0.62)
                    .offset(x: size.width * 0.22, y: -size.height * 0.24)

            case .signalSlash:
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(index.isMultiple(of: 2) ? palette.flash.opacity(0.84) : palette.glow.opacity(0.86))
                        .frame(width: size.width * 1.1, height: size.height * 0.15)
                        .rotationEffect(.degrees(-28))
                        .offset(x: size.width * 0.08, y: size.height * (-0.16 + (Double(index) * 0.16)))
                }

            case .noirHalftone:
                Circle()
                    .fill(palette.glow.opacity(0.9))
                    .frame(width: size.width * 0.66)
                    .offset(x: size.width * 0.18, y: -size.height * 0.12)

                ComicHalftoneDots(color: palette.paper.opacity(0.32), dotSize: 2.4, spacing: 10)
                    .mask(
                        LinearGradient(
                            colors: [.clear, .white, .white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

            case .popRibbon:
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(palette.flash.opacity(0.92))
                    .frame(width: size.width * 0.92, height: size.height * 0.18)
                    .rotationEffect(.degrees(-18))
                    .offset(x: -size.width * 0.04, y: -size.height * 0.14)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(palette.glow.opacity(0.92))
                    .frame(width: size.width * 0.8, height: size.height * 0.18)
                    .rotationEffect(.degrees(14))
                    .offset(x: size.width * 0.1, y: size.height * 0.2)

            case .skylineBeam:
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(0..<6, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(index.isMultiple(of: 2) ? palette.flash.opacity(0.75) : palette.paper.opacity(0.42))
                            .frame(width: size.width * 0.08, height: size.height * (0.18 + (Double(index % 3) * 0.1)))
                    }
                }
                .offset(x: -size.width * 0.14, y: size.height * 0.16)

                Circle()
                    .fill(palette.glow.opacity(0.66))
                    .frame(width: size.width * 0.5)
                    .offset(x: size.width * 0.18, y: -size.height * 0.18)

            case .pulseFrame:
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(palette.flash.opacity(0.9), lineWidth: 12)
                    .frame(width: size.width * 0.9, height: size.height * 0.9)

                ComicHalftoneDots(color: palette.paper.opacity(0.26), dotSize: 2.1, spacing: 12)
                    .opacity(0.34)

            case .emberStamp:
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(palette.glow.opacity(0.92))
                    .frame(width: size.width * 0.7, height: size.height * 0.26)
                    .rotationEffect(.degrees(-16))
                    .offset(x: size.width * 0.16, y: -size.height * 0.14)

                ComicHalftoneDots(color: palette.flash.opacity(0.34), dotSize: 2.2, spacing: 11)
                    .mask(
                        LinearGradient(
                            colors: [.white, .white, .clear],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                    )
            }

            LinearGradient(
                colors: [Color.white.opacity(0.12), .clear, Color.black.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    @ViewBuilder
    private func compactTitlePlate(variant: CompactCoverVariant, palette: CompactComicPalette) -> some View {
        switch variant {
        case .bamBurst:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.paper)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppColor.comicInk, lineWidth: 1.8)
                }
        case .signalSlash:
            Capsule(style: .continuous)
                .fill(palette.paper)
                .rotationEffect(.degrees(-6))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(AppColor.comicInk.opacity(0.2), lineWidth: 1.5)
                        .rotationEffect(.degrees(-6))
                }
        case .noirHalftone:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.paper)
        case .popRibbon:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.paper)
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(palette.flash)
                        .frame(width: 10)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
        case .skylineBeam:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.paper)
                .overlay(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(palette.flash.opacity(0.86))
                        .frame(height: 8)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
        case .pulseFrame:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColor.comicInk.opacity(0.9))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(palette.flash, lineWidth: 2)
                }
        case .emberStamp:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.paper)
                .rotationEffect(.degrees(-3))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppColor.comicInk.opacity(0.16), lineWidth: 1.5)
                        .rotationEffect(.degrees(-3))
                }
        }
    }

    private func compactPalette(for variant: CompactCoverVariant) -> CompactComicPalette {
        switch variant {
        case .bamBurst:
            return CompactComicPalette(
                backdrop: [AppColor.comicOrange, AppColor.comicRed, AppColor.comicBerry],
                ink: AppColor.comicInk,
                paper: AppColor.comicCream,
                flash: AppColor.comicYellow,
                punch: AppColor.comicRed,
                glow: accent,
                halftone: AppColor.comicInk.opacity(0.18)
            )
        case .signalSlash:
            return CompactComicPalette(
                backdrop: [AppColor.comicCream, AppColor.comicYellow.opacity(0.86), AppColor.comicOrange],
                ink: AppColor.comicInk,
                paper: Color.white,
                flash: AppColor.comicBlue,
                punch: AppColor.comicRed,
                glow: AppColor.comicYellow,
                halftone: AppColor.comicInk.opacity(0.14)
            )
        case .noirHalftone:
            return CompactComicPalette(
                backdrop: [AppColor.comicInk, Color(hex: "2B2220"), accent.opacity(0.84)],
                ink: AppColor.comicInk,
                paper: AppColor.comicCream,
                flash: AppColor.comicRed,
                punch: AppColor.comicBerry,
                glow: AppColor.comicOrange,
                halftone: Color.white.opacity(0.24)
            )
        case .popRibbon:
            return CompactComicPalette(
                backdrop: [AppColor.comicYellow, AppColor.comicCream, accent.opacity(0.86)],
                ink: AppColor.comicInk,
                paper: Color.white,
                flash: AppColor.comicRed,
                punch: AppColor.comicBerry,
                glow: AppColor.comicBlue,
                halftone: AppColor.comicInk.opacity(0.12)
            )
        case .skylineBeam:
            return CompactComicPalette(
                backdrop: [accent.opacity(0.92), AppColor.comicBlue, AppColor.comicInk],
                ink: AppColor.comicInk,
                paper: AppColor.comicCream,
                flash: AppColor.comicYellow,
                punch: AppColor.comicTeal,
                glow: AppColor.comicTeal,
                halftone: Color.white.opacity(0.18)
            )
        case .pulseFrame:
            return CompactComicPalette(
                backdrop: [AppColor.comicCream, AppColor.comicYellow.opacity(0.88), AppColor.comicOrange],
                ink: AppColor.comicCream,
                paper: AppColor.comicCream,
                flash: AppColor.comicInk,
                punch: AppColor.comicRed,
                glow: accent,
                halftone: AppColor.comicInk.opacity(0.14)
            )
        case .emberStamp:
            return CompactComicPalette(
                backdrop: [Color(hex: "5B4234"), AppColor.comicInk, AppColor.comicOrange],
                ink: AppColor.comicInk,
                paper: AppColor.comicCream,
                flash: AppColor.comicOrange,
                punch: AppColor.comicYellow,
                glow: accent,
                halftone: Color.white.opacity(0.16)
            )
        }
    }

    private var compactDisplayTitle: String {
        let normalized = title
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let words = normalized.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return normalized }
        guard words.count > 1 else { return normalized }

        if words.count == 2 {
            return "\(words[0])\n\(words[1])"
        }

        let secondLineSeed = words[1...min(words.count - 1, 2)].joined(separator: " ")
        return "\(words[0])\n\(secondLineSeed)"
    }

    private var compactFooterText: String {
        let source = (badge?.isEmpty == false ? badge : subtitle) ?? resolvedStyle.shortSignature
        let normalized = source
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized.count > 26 {
            let index = normalized.index(normalized.startIndex, offsetBy: 23)
            return String(normalized[..<index]) + "..."
        }

        return normalized
    }

    private var compactEyebrowText: String {
        let value = eyebrow.isEmpty ? resolvedStyle.coverEyebrow : eyebrow
        return value
            .replacingOccurrences(of: "\n", with: " ")
            .uppercased()
    }

    private var compactTokenText: String {
        if let badge, !badge.isEmpty {
            return String(badge.uppercased().prefix(10))
        }

        return String(resolvedStyle.shortSignature.uppercased().prefix(10))
    }

    private var resolvedStyle: StoryStyle {
        style ?? .cinematic
    }

    private var resolvedCompactVariant: CompactCoverVariant {
        compactVariant ?? CompactCoverVariant.automatic(style: resolvedStyle, title: title)
    }

    private var styleStamp: String {
        switch resolvedStyle {
        case .manga:
            return "INK"
        case .western:
            return "ISSUE"
        case .cartoon:
            return "COLOR"
        case .cinematic:
            return "PRESTIGE"
        case .childrensBook:
            return "STORY"
        }
    }
}

struct CompactCoverGalleryView: View {
    private let variants = CompactCoverVariant.allCases

    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.comicRed, showsDeskBand: false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Compact Cover Explorations")
                            .font(AppTypography.title)
                            .foregroundStyle(AppColor.textPrimary)

                        Text("Seven comic-pop directions for the small cover tile, inspired by bold poster energy but aligned to StoryComicAI.")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 96, maximum: 128), spacing: AppSpacing.md)
                        ],
                        spacing: AppSpacing.md
                    ) {
                        ForEach(variants) { variant in
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                ComicCoverCard(
                                    title: sampleTitle(for: variant),
                                    subtitle: sampleSubtitle(for: variant),
                                    accent: sampleStyle(for: variant).map { AppColor.accent(for: $0) } ?? AppColor.accent,
                                    style: sampleStyle(for: variant),
                                    eyebrow: sampleStyle(for: variant)?.coverEyebrow ?? "Personal Edition",
                                    badge: sampleBadge(for: variant),
                                    emphasize: false,
                                    presentation: .compact,
                                    compactVariant: variant
                                )

                                Text(variant.displayName)
                                    .font(AppTypography.meta)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, AppSpacing.section)
            }
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }

    private func sampleStyle(for variant: CompactCoverVariant) -> StoryStyle? {
        switch variant {
        case .bamBurst: return .cartoon
        case .signalSlash: return .manga
        case .noirHalftone: return .cinematic
        case .popRibbon: return .childrensBook
        case .skylineBeam: return .cinematic
        case .pulseFrame: return .western
        case .emberStamp: return .western
        }
    }

    private func sampleTitle(for variant: CompactCoverVariant) -> String {
        switch variant {
        case .bamBurst: return "Hero Mode"
        case .signalSlash: return "Neon Chase"
        case .noirHalftone: return "Night Signal"
        case .popRibbon: return "Playbook"
        case .skylineBeam: return "City Pulse"
        case .pulseFrame: return "Impact File"
        case .emberStamp: return "Dust Issue"
        }
    }

    private func sampleSubtitle(for variant: CompactCoverVariant) -> String {
        switch variant {
        case .bamBurst: return "Personal comic studio"
        case .signalSlash: return "Bold scene composition"
        case .noirHalftone: return "Collector-ready"
        case .popRibbon: return "Friendly and graphic"
        case .skylineBeam: return "Wide-screen tension"
        case .pulseFrame: return "High-contrast energy"
        case .emberStamp: return "Prestige western cut"
        }
    }

    private func sampleBadge(for variant: CompactCoverVariant) -> String? {
        switch variant {
        case .bamBurst: return "NEW"
        case .signalSlash: return "FAST"
        case .noirHalftone: return "NOIR"
        case .popRibbon: return "PLAY"
        case .skylineBeam: return "CITY"
        case .pulseFrame: return "POW"
        case .emberStamp: return "DUST"
        }
    }
}

struct SingleCompactCoverPreviewView: View {
    let variant: CompactCoverVariant

    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.comicRed, showsDeskBand: false)

            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text(variant.displayName)
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Compact cover direction for StoryComicAI.")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColor.textSecondary)

                Spacer(minLength: 0)

                ComicCoverCard(
                    title: sampleTitle(for: variant),
                    subtitle: sampleSubtitle(for: variant),
                    accent: sampleStyle(for: variant).map { AppColor.accent(for: $0) } ?? AppColor.accent,
                    style: sampleStyle(for: variant),
                    eyebrow: sampleStyle(for: variant)?.coverEyebrow ?? "Personal Edition",
                    badge: sampleBadge(for: variant),
                    emphasize: true,
                    presentation: .compact,
                    compactVariant: variant
                )
                .frame(width: 260)
                .frame(maxWidth: .infinity)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.xl)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }

    private func sampleStyle(for variant: CompactCoverVariant) -> StoryStyle? {
        switch variant {
        case .bamBurst: return .cartoon
        case .signalSlash: return .manga
        case .noirHalftone: return .cinematic
        case .popRibbon: return .childrensBook
        case .skylineBeam: return .cinematic
        case .pulseFrame: return .western
        case .emberStamp: return .western
        }
    }

    private func sampleTitle(for variant: CompactCoverVariant) -> String {
        switch variant {
        case .bamBurst: return "Hero Mode"
        case .signalSlash: return "Neon Chase"
        case .noirHalftone: return "Night Signal"
        case .popRibbon: return "Playbook"
        case .skylineBeam: return "City Pulse"
        case .pulseFrame: return "Impact File"
        case .emberStamp: return "Dust Issue"
        }
    }

    private func sampleSubtitle(for variant: CompactCoverVariant) -> String {
        switch variant {
        case .bamBurst: return "Personal comic studio"
        case .signalSlash: return "Bold scene composition"
        case .noirHalftone: return "Collector-ready"
        case .popRibbon: return "Friendly and graphic"
        case .skylineBeam: return "Wide-screen tension"
        case .pulseFrame: return "High-contrast energy"
        case .emberStamp: return "Prestige western cut"
        }
    }

    private func sampleBadge(for variant: CompactCoverVariant) -> String? {
        switch variant {
        case .bamBurst: return "NEW"
        case .signalSlash: return "FAST"
        case .noirHalftone: return "NOIR"
        case .popRibbon: return "PLAY"
        case .skylineBeam: return "CITY"
        case .pulseFrame: return "POW"
        case .emberStamp: return "DUST"
        }
    }
}

private struct ComicBurstShape: Shape {
    let points: Int
    let innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let count = max(points, 4)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) * 0.5
        let innerRadius = outerRadius * innerRatio
        let step = .pi / CGFloat(count)

        var path = Path()

        for index in 0..<(count * 2) {
            let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = (CGFloat(index) * step) - (.pi / 2)
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

private struct ComicHalftoneDots: View {
    let color: Color
    let dotSize: CGFloat
    let spacing: CGFloat

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                var path = Path()

                stride(from: CGFloat(0), through: size.height + spacing, by: spacing).forEach { y in
                    stride(from: CGFloat(0), through: size.width + spacing, by: spacing).forEach { x in
                        let offset = Int(y / spacing).isMultiple(of: 2) ? 0 : spacing * 0.5
                        let rect = CGRect(x: x + offset, y: y, width: dotSize, height: dotSize)
                        path.addEllipse(in: rect)
                    }
                }

                context.fill(path, with: .color(color))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
    }
}

struct FloatingPanelScreen<Header: View, Content: View, Footer: View>: View {
    let accent: Color
    let showsDeskBand: Bool
    let header: Header
    let content: Content
    let footer: Footer

    init(
        accent: Color = AppColor.accent,
        showsDeskBand: Bool = false,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.accent = accent
        self.showsDeskBand = showsDeskBand
        self.header = header()
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                EditorialBackground(accent: accent, showsDeskBand: showsDeskBand)
                    .frame(width: proxy.size.width, height: proxy.size.height)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {
                        header

                        CardContainer(emphasize: true) {
                            content
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        footer
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: 620)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, max(proxy.safeAreaInsets.top + AppSpacing.lg, AppSpacing.section))
                    .padding(.bottom, proxy.safeAreaInsets.bottom + AppSpacing.section)
                    .padding(.horizontal, AppSpacing.lg)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .ignoresSafeArea(.container, edges: .all)
    }
}

struct ComicPageOverlayLayer: View {
    let overlays: [ComicPageTextOverlay]
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            ForEach(overlays) { overlay in
                overlayView(overlay)
                    .frame(width: max(84, proxy.size.width * overlay.normalizedWidth))
                    .scaleEffect(overlay.emphasisScale)
                    .rotationEffect(.degrees(overlay.rotationDegrees))
                    .position(
                        x: proxy.size.width * overlay.normalizedX,
                        y: proxy.size.height * overlay.normalizedY
                    )
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func overlayView(_ overlay: ComicPageTextOverlay) -> some View {
        switch overlay.kind {
        case .speech:
            ComicSpeechBubbleView(
                text: overlay.text,
                speaker: overlay.speaker,
                tailDirection: overlay.tailDirection ?? .left,
                tone: overlay.tone,
                accent: accent
            )
        case .narration:
            ComicNarrationBoxView(text: overlay.text, tone: overlay.tone, accent: accent)
        case .thought:
            ComicThoughtBubbleView(
                text: overlay.text,
                speaker: overlay.speaker,
                tone: overlay.tone,
                accent: accent
            )
        case .sfx:
            ComicSFXView(text: overlay.text, tone: overlay.tone, accent: accent)
        }
    }
}

private struct ComicSpeechBubbleView: View {
    let text: String
    let speaker: String?
    let tailDirection: ComicPageTextOverlay.TailDirection
    let tone: ComicPageTextOverlay.Tone
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let speaker, !speaker.isEmpty {
                Text(speaker)
                    .font(AppTypography.badge)
                    .foregroundStyle(AppColor.textSecondary)
                    .tracking(0.9)
                    .textCase(.uppercase)
            }

            Text(text)
                .font(AppTypography.caption)
                .foregroundStyle(foregroundColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(backgroundColor)
        .overlay(alignment: tailAlignment) {
            BubbleTailShape(direction: tailDirection)
                .fill(backgroundColor)
                .frame(width: 18, height: 12)
                .offset(x: tailOffsetX, y: 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor, lineWidth: 1.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppColor.bookShadow.opacity(0.55), radius: 8, x: 0, y: 4)
    }

    private var backgroundColor: Color {
        switch tone {
        case .paper:
            return AppColor.surfaceElevated
        case .ink:
            return AppColor.textPrimary.opacity(0.92)
        case .accent:
            return accent.opacity(0.92)
        case .inverse:
            return AppColor.textOnDark.opacity(0.96)
        }
    }

    private var foregroundColor: Color {
        switch tone {
        case .ink, .accent:
            return AppColor.textOnDark
        case .paper, .inverse:
            return AppColor.textPrimary
        }
    }

    private var borderColor: Color {
        switch tone {
        case .paper, .inverse:
            return AppColor.textPrimary.opacity(0.72)
        case .ink, .accent:
            return Color.white.opacity(0.18)
        }
    }

    private var tailAlignment: Alignment {
        switch tailDirection {
        case .left:
            return .bottomLeading
        case .right:
            return .bottomTrailing
        case .down:
            return .bottom
        }
    }

    private var tailOffsetX: CGFloat {
        switch tailDirection {
        case .left:
            return 12
        case .right:
            return -12
        case .down:
            return 0
        }
    }
}

private struct ComicNarrationBoxView: View {
    let text: String
    let tone: ComicPageTextOverlay.Tone
    let accent: Color

    var body: some View {
        Text(text)
            .font(AppTypography.meta)
            .foregroundStyle(foregroundColor)
            .tracking(0.5)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: AppColor.bookShadow.opacity(0.35), radius: 6, x: 0, y: 3)
    }

    private var backgroundColor: Color {
        switch tone {
        case .paper:
            return AppColor.surfaceElevated
        case .ink:
            return AppColor.textPrimary
        case .accent:
            return accent.opacity(0.86)
        case .inverse:
            return AppColor.textOnDark.opacity(0.94)
        }
    }

    private var foregroundColor: Color {
        switch tone {
        case .ink, .accent:
            return AppColor.textOnDark
        case .paper, .inverse:
            return AppColor.textPrimary
        }
    }

    private var borderColor: Color {
        switch tone {
        case .paper, .inverse:
            return AppColor.borderStrong.opacity(0.88)
        case .ink, .accent:
            return Color.white.opacity(0.15)
        }
    }
}

private struct ComicThoughtBubbleView: View {
    let text: String
    let speaker: String?
    let tone: ComicPageTextOverlay.Tone
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let speaker, !speaker.isEmpty {
                Text(speaker)
                    .font(AppTypography.badge)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.9)
                    .textCase(.uppercase)
            }

            Text(text)
                .font(AppTypography.caption)
                .foregroundStyle(foregroundColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(backgroundColor.opacity(0.92))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .foregroundStyle(borderColor)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(backgroundColor)
                .frame(width: 12, height: 12)
                .offset(x: 18, y: 16)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(backgroundColor.opacity(0.88))
                .frame(width: 8, height: 8)
                .offset(x: 10, y: 28)
        }
        .shadow(color: AppColor.bookShadow.opacity(0.42), radius: 8, x: 0, y: 4)
    }

    private var backgroundColor: Color {
        switch tone {
        case .paper:
            return AppColor.surface
        case .ink:
            return AppColor.textPrimary.opacity(0.96)
        case .accent:
            return accent.opacity(0.9)
        case .inverse:
            return AppColor.textOnDark
        }
    }

    private var foregroundColor: Color {
        switch tone {
        case .ink, .accent:
            return AppColor.textOnDark
        case .paper, .inverse:
            return AppColor.textPrimary
        }
    }

    private var borderColor: Color {
        switch tone {
        case .ink, .accent:
            return Color.white.opacity(0.24)
        case .paper, .inverse:
            return AppColor.textPrimary.opacity(0.54)
        }
    }
}

private struct ComicSFXView: View {
    let text: String
    let tone: ComicPageTextOverlay.Tone
    let accent: Color

    var body: some View {
        Text(text)
            .font(.system(size: 24, weight: .black, design: .rounded))
            .foregroundStyle(foregroundColor)
            .shadow(color: shadowColor, radius: 0, x: 2, y: 2)
            .padding(.horizontal, 2)
    }

    private var foregroundColor: Color {
        switch tone {
        case .paper:
            return AppColor.textPrimary
        case .ink:
            return AppColor.textOnDark
        case .accent:
            return accent
        case .inverse:
            return AppColor.textOnDark
        }
    }

    private var shadowColor: Color {
        switch tone {
        case .paper:
            return AppColor.surfaceElevated
        case .ink, .inverse:
            return AppColor.textPrimary.opacity(0.35)
        case .accent:
            return AppColor.textPrimary.opacity(0.4)
        }
    }
}

private struct BubbleTailShape: Shape {
    let direction: ComicPageTextOverlay.TailDirection

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch direction {
        case .left:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX + 3, y: rect.maxY))
        case .right:
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX - 3, y: rect.maxY))
        case .down:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        path.closeSubpath()
        return path
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    CardContainer(emphasize: true) {
        Text("Premium Card")
            .foregroundStyle(AppColor.textPrimary)
    }
    .padding()
    .background(AppColor.backgroundPrimary)
}
#endif
