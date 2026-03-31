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
    let eyebrow: String
    let badge: String?
    let emphasize: Bool

    init(
        title: String,
        subtitle: String? = nil,
        accent: Color,
        eyebrow: String,
        badge: String? = nil,
        emphasize: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
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
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
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
