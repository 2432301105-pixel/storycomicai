import SwiftUI

enum PageTurnDirection {
    case forward
    case backward
}

struct PageTurnView: View {
    let leftPage: ComicPresentationPage?
    let rightPage: ComicPresentationPage?
    let accent: Color
    let progress: CGFloat
    let direction: PageTurnDirection
    let reduceMotion: Bool

    var body: some View {
        let clampedProgress = min(max(progress, 0), 1)

        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColor.surfaceMuted)
                .shadow(
                    color: AppColor.bookDepthShadow,
                    radius: AppElevation.Book.pageRadius,
                    x: 0,
                    y: AppElevation.Book.pageYOffset
                )

            HStack(spacing: 0) {
                SpreadPage(page: leftPage, accent: accent, placeholderTitle: "Left page")
                spine
                SpreadPage(page: rightPage, accent: accent, placeholderTitle: "Right page")
            }
            .padding(18)
        }
        .rotation3DEffect(
            .degrees(rotationDegrees),
            axis: (x: 0, y: 1, z: 0),
            anchor: direction == .forward ? .trailing : .leading,
            perspective: 0.78
        )
        .scaleEffect(1 - (clampedProgress * (reduceMotion ? 0.01 : 0.02)))
        .offset(x: direction == .forward ? -(clampedProgress * 12) : (clampedProgress * 12))
    }

    private var rotationDegrees: Double {
        if reduceMotion { return 0 }
        let maxRotation: Double = 14
        switch direction {
        case .forward:
            return -maxRotation * Double(progress)
        case .backward:
            return maxRotation * Double(progress)
        }
    }

    private var spine: some View {
        LinearGradient(
            colors: [Color.black.opacity(0.16), Color.white.opacity(0.08), Color.black.opacity(0.16)],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: 16)
        .padding(.vertical, 14)
    }
}

private struct SpreadPage: View {
    let page: ComicPresentationPage?
    let accent: Color
    let placeholderTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let page {
                Text("Page \(page.pageNumber)")
                    .font(AppTypography.meta)
                    .foregroundStyle(AppColor.textTertiary)
                    .textCase(.uppercase)

                ZStack {
                    OptimizedComicImageView(
                        thumbnailURL: page.thumbnailURL,
                        fullImageURL: page.fullImageURL,
                        strategy: .thumbnailThenFull,
                        contentMode: .fill,
                        thumbnailMaxPixelSize: 920,
                        fullMaxPixelSize: 1_800
                    )
                    .frame(maxWidth: .infinity, maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    ComicPageOverlayLayer(overlays: page.overlays, accent: accent)
                        .padding(8)
                }
                .frame(maxWidth: .infinity, maxHeight: 320)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColor.surfaceMuted.opacity(0.45))
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(page.title)
                    .font(AppTypography.section)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)

                if let caption = page.caption {
                    Text(caption)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(3)
                }
            } else {
                Spacer()
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 34))
                        .foregroundStyle(AppColor.textTertiary)
                    Text(placeholderTitle)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColor.pagePaper)
        .overlay {
            RoundedRectangle(cornerRadius: AppElevation.Book.pageCorner, style: .continuous)
                .stroke(AppColor.border.opacity(0.7), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppElevation.Book.pageCorner, style: .continuous))
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    let package = MockFixtures.sampleComicBookPackage(projectID: UUID(), source: .mock)
    PageTurnView(
        leftPage: package.pages.first,
        rightPage: package.pages.dropFirst().first,
        accent: AppColor.accent,
        progress: 0.24,
        direction: .forward,
        reduceMotion: false
    )
    .padding()
    .background(AppColor.backgroundPrimary)
}
#endif
