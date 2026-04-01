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
                        ? [AppColor.surfaceElevated, AppColor.surface, AppColor.surfaceMuted.opacity(0.92)]
                        : [AppColor.surface, AppColor.surfaceMuted, AppColor.surfaceInset.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .topLeading) {
                LinearGradient(
                    colors: [Color.white.opacity(0.42), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: AppElevation.Surface.radius, style: .continuous))
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
            LinearGradient(
                colors: [AppColor.backgroundPrimary, AppColor.backgroundCanvas, AppColor.backgroundInkWash.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [AppColor.spotlight, .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 420
            )
            .blendMode(.screen)

            RadialGradient(
                colors: [accent.opacity(0.16), .clear],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 380
            )

            HalftoneWash()
                .blendMode(.multiply)
                .opacity(0.32)

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
                let step: CGFloat = 18
                let radius: CGFloat = 1.1
                var path = Path()

                stride(from: CGFloat(0), through: size.height, by: step).forEach { y in
                    stride(from: CGFloat(0), through: size.width, by: step).forEach { x in
                        let normalizedY = y / max(size.height, 1)
                        let normalizedX = x / max(size.width, 1)
                        let intensity = (1 - normalizedY) * 0.55 + normalizedX * 0.12
                        guard intensity > 0.16 else { return }
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

struct ComicCoverCard: View {
    let title: String
    let subtitle: String?
    let accent: Color
    let style: StoryStyle?
    let eyebrow: String
    let badge: String?
    let emphasize: Bool

    init(
        title: String,
        subtitle: String? = nil,
        accent: Color,
        style: StoryStyle? = nil,
        eyebrow: String,
        badge: String? = nil,
        emphasize: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
        self.style = style
        self.eyebrow = eyebrow
        self.badge = badge
        self.emphasize = emphasize
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: AppElevation.Cover.radius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.94), AppColor.textPrimary, AppColor.textPrimary.opacity(0.92)],
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
                        .opacity(0.35)
                }
                .shadow(
                    color: AppColor.bookDepthShadow.opacity(emphasize ? 1 : 0.8),
                    radius: emphasize ? AppElevation.Cover.shadowRadius + 6 : AppElevation.Cover.shadowRadius,
                    x: 0,
                    y: emphasize ? AppElevation.Cover.shadowYOffset + 4 : AppElevation.Cover.shadowYOffset
                )

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(eyebrow)
                    .font(AppTypography.coverMeta)
                    .foregroundStyle(AppColor.textOnDark.opacity(0.82))
                    .tracking(1.6)
                    .textCase(.uppercase)

                Spacer(minLength: 0)

                Text(title)
                    .font(AppTypography.coverTitle)
                    .foregroundStyle(AppColor.textOnDark)
                    .lineLimit(3)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textOnDark.opacity(0.82))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(AppSpacing.lg)
        }
        .aspectRatio(2 / 3, contentMode: .fit)
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

    private var resolvedStyle: StoryStyle {
        style ?? .cinematic
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
