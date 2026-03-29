import SwiftUI

enum PageTurnDirection {
    case forward
    case backward
}

struct PageTurnView: View {
    let page: ComicPresentationPage?
    let progress: CGFloat
    let direction: PageTurnDirection
    let reduceMotion: Bool

    var body: some View {
        let clampedProgress = min(max(progress, 0), 1)
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(AppColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppColor.border, lineWidth: 1)
                )
                .shadow(
                    color: AppColor.bookShadow,
                    radius: AppElevation.Book.pageRadius,
                    x: 0,
                    y: AppElevation.Book.pageYOffset
                )

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if let page {
                    HStack {
                        Text("Page \(page.pageNumber)")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.textSecondary)
                        Spacer()
                    }

                    pageImage(page: page)
                        .frame(maxWidth: .infinity, maxHeight: 360)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text(page.title)
                        .font(AppTypography.heading)
                        .foregroundStyle(AppColor.textPrimary)

                    if let caption = page.caption {
                        Text(caption)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                } else {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 42))
                            .foregroundStyle(AppColor.textSecondary)
                        Text("No page available")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(AppSpacing.md)
        }
        .rotation3DEffect(
            .degrees(rotationDegrees),
            axis: (x: 0, y: 1, z: 0),
            anchor: direction == .forward ? .trailing : .leading,
            perspective: 0.75
        )
        .scaleEffect(1 - (clampedProgress * (reduceMotion ? 0.01 : 0.03)))
    }

    private var rotationDegrees: Double {
        if reduceMotion {
            return 0
        }
        let maxRotation: Double = 26
        switch direction {
        case .forward:
            return -maxRotation * Double(progress)
        case .backward:
            return maxRotation * Double(progress)
        }
    }

    @ViewBuilder
    private func pageImage(page: ComicPresentationPage) -> some View {
        OptimizedComicImageView(
            thumbnailURL: page.thumbnailURL,
            fullImageURL: page.fullImageURL,
            strategy: .thumbnailThenFull,
            contentMode: .fill,
            thumbnailMaxPixelSize: 760,
            fullMaxPixelSize: 1_600
        )
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    let package = MockFixtures.sampleComicBookPackage(projectID: UUID(), source: .mock)
    PageTurnView(page: package.pages.first, progress: 0.32, direction: .forward, reduceMotion: false)
        .padding()
        .background(AppColor.backgroundPrimary)
}
#endif
