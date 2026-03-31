import SwiftUI

struct BookRevealView: View {
    @ObservedObject var coordinator: ComicPresentationCoordinator
    @StateObject private var viewModel: BookRevealViewModel
    @State private var hasAnimatedIn: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(coordinator: ComicPresentationCoordinator) {
        self.coordinator = coordinator
        _viewModel = StateObject(wrappedValue: BookRevealViewModel(coordinator: coordinator))
    }

    var body: some View {
        ZStack {
            revealBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    switch coordinator.packageState {
                    case .idle, .loading:
                        LoadingStateView(
                            title: "Preparing your comic book",
                            subtitle: "Setting the desk and staging the finished edition."
                        )
                        .frame(height: 420)
                        .clipShape(RoundedRectangle(cornerRadius: AppElevation.Surface.radius, style: .continuous))

                    case let .failed(message):
                        ErrorStateView(
                            title: "Reveal could not be prepared",
                            message: message
                        ) {
                            viewModel.retry()
                        }
                        .frame(height: 420)
                        .clipShape(RoundedRectangle(cornerRadius: AppElevation.Surface.radius, style: .continuous))

                    case let .loaded(package):
                        loadedView(package: package)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, AppSpacing.section)
            }
        }
        .onAppear {
            viewModel.onAppear()
            withAnimation(AppMotion.revealEntry(reduceMotion: reduceMotion)) {
                hasAnimatedIn = true
            }
        }
    }

    private var revealBackground: some View {
        LinearGradient(
            colors: [AppColor.backgroundPrimary, AppColor.surfaceMuted],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [AppColor.deskTopStart, AppColor.deskTopMid, AppColor.deskTopEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 360)
            .blur(radius: 0.8)
        }
    }

    private func loadedView(package: ComicBookPackage) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(package.legacyRevealMetadata?.personalizationTag ?? "Personal Edition")
                    .font(AppTypography.eyebrow)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(1.2)
                    .textCase(.uppercase)

                Text(revealHeadline(for: package))
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)

                if let subheadline = revealSubheadline(for: package) {
                    Text(subheadline)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.black.opacity(0.06))
                    .frame(height: 240)
                    .blur(radius: 18)
                    .offset(y: 36)

                bookObject(package: package)
                    .scaleEffect(hasAnimatedIn ? 1 : 0.95)
                    .rotationEffect(.degrees(hasAnimatedIn ? -4 : -8))
                    .offset(y: hasAnimatedIn ? 0 : 20)
                    .opacity(hasAnimatedIn ? 1 : 0.55)
                    .animation(AppMotion.revealContent(reduceMotion: reduceMotion), value: hasAnimatedIn)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 420)

            if package.isPaywallLocked {
                CardContainer {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(package.paywallLockReasonText)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.warning)
                        if let offer = package.primaryPaywallOffer {
                            Text("Primary offer | \(offer.formattedPriceText)")
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            PrimaryButton(title: package.ctaMetadata.revealPrimaryLabel) {
                viewModel.openBook()
            }

            HStack(spacing: AppSpacing.sm) {
                secondaryAction(title: package.ctaMetadata.revealSecondaryLabel) {
                    viewModel.openFlatReader()
                }
                secondaryAction(title: package.ctaMetadata.exportLabel) {
                    viewModel.openExport()
                }
                .disabled(
                    (!package.exportAvailability.isPDFAvailable && !package.exportAvailability.isImagePackAvailable)
                        || package.exportAvailability.lockedByPaywall
                )
            }
        }
    }

    private func bookObject(package: ComicBookPackage) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: AppElevation.Book.coverCorner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColor.accent(for: package.styleLabel).opacity(0.95), AppColor.textPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: AppColor.bookDepthShadow,
                    radius: AppElevation.Book.revealRadius,
                    x: 0,
                    y: AppElevation.Book.revealYOffset
                )

            RoundedRectangle(cornerRadius: AppElevation.Book.coverCorner, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 20)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: AppElevation.Book.coverCorner,
                        bottomLeadingRadius: AppElevation.Book.coverCorner,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                )

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                coverImage(url: package.cover.imageURL)
                    .frame(height: 230)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(package.cover.titleText ?? package.title)
                        .font(AppTypography.coverTitle)
                        .foregroundStyle(AppColor.textOnDark)
                        .lineLimit(2)

                    if let subtitle = package.cover.subtitleText ?? package.subtitle {
                        Text(subtitle)
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.textOnDark.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .frame(maxWidth: 340)
        .frame(height: 380)
    }

    private func secondaryAction(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.footnote)
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(AppColor.surfaceElevated)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColor.border.opacity(0.9), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func revealHeadline(for package: ComicBookPackage) -> String {
        if let headline = package.ctaMetadata.revealHeadline {
            return headline
        }
        if let legacyHeadline = package.legacyRevealMetadata?.headline {
            return legacyHeadline
        }
        return "Your personalized comic is ready"
    }

    private func revealSubheadline(for package: ComicBookPackage) -> String? {
        if let subheadline = package.ctaMetadata.revealSubheadline {
            return subheadline
        }
        return package.legacyRevealMetadata?.subheadline ?? package.subtitle
    }

    private func coverImage(url: URL?) -> some View {
        OptimizedComicImageView(
            thumbnailURL: url,
            fullImageURL: url,
            strategy: .thumbnailThenFull,
            contentMode: .fill,
            thumbnailMaxPixelSize: 520,
            fullMaxPixelSize: 1_100,
            placeholderSystemImageName: "book.closed.fill"
        )
    }
}

#if !CI_DISABLE_PREVIEWS
struct BookRevealView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BookRevealView(
                coordinator: ComicPresentationCoordinator(
                    projectID: UUID(),
                    comicPackageService: MockComicPackageService(),
                    analyticsService: ConsoleAnalyticsService(),
                    hapticProvider: NoopHapticProvider()
                )
            )
        }
        .previewContainer()
    }
}
#endif
