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
        VStack(spacing: AppSpacing.lg) {
            switch coordinator.packageState {
            case .idle, .loading:
                LoadingStateView(
                    title: "Preparing Your Comic Book",
                    subtitle: "We are staging your personalized reveal."
                )
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            case let .failed(message):
                ErrorStateView(
                    title: "Reveal Could Not Be Prepared",
                    message: message
                ) {
                    viewModel.retry()
                }
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            case let .loaded(package):
                revealCard(package: package)
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            LinearGradient(
                colors: [AppColor.deskTopStart, AppColor.deskTopEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            viewModel.onAppear()
            withAnimation(AppMotion.revealEntry(reduceMotion: reduceMotion)) {
                hasAnimatedIn = true
            }
        }
    }

    private func revealCard(package: ComicBookPackage) -> some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(revealHeadline(for: package))
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)
                if let subheadline = revealSubheadline(for: package) {
                    Text(subheadline)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if package.isPaywallLocked {
                CardContainer {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(package.paywallLockReasonText)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.warning)
                        if let offer = package.primaryPaywallOffer {
                            Text("Unlock offer: \(offer.formattedPriceText)")
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(AppColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(AppColor.border, lineWidth: 1)
                    )
                    .shadow(
                        color: AppColor.bookShadow,
                        radius: AppElevation.Book.revealRadius,
                        x: 0,
                        y: AppElevation.Book.revealYOffset
                    )

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    coverImage(url: package.cover.imageURL)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    Text(package.cover.titleText ?? package.title)
                        .font(AppTypography.heading)
                        .foregroundStyle(AppColor.textPrimary)

                    if let subtitle = package.cover.subtitleText ?? package.subtitle {
                        Text(subtitle)
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                .padding(AppSpacing.md)
            }
            .frame(maxWidth: 360)
            .scaleEffect(hasAnimatedIn ? 1 : 0.94)
            .opacity(hasAnimatedIn ? 1 : 0.6)
            .animation(AppMotion.revealContent(reduceMotion: reduceMotion), value: hasAnimatedIn)

            PrimaryButton(title: package.ctaMetadata.revealPrimaryLabel) {
                viewModel.openBook()
            }

            HStack(spacing: AppSpacing.sm) {
                Button(package.ctaMetadata.revealSecondaryLabel) {
                    viewModel.openFlatReader()
                }
                .buttonStyle(.bordered)
                .tint(AppColor.accent)

                Button(package.ctaMetadata.exportLabel) {
                    viewModel.openExport()
                }
                .buttonStyle(.bordered)
                .tint(AppColor.accent)
                .disabled(
                    (!package.exportAvailability.isPDFAvailable && !package.exportAvailability.isImagePackAvailable)
                        || package.exportAvailability.lockedByPaywall
                )
            }
            .font(AppTypography.footnote)
            .foregroundStyle(AppColor.textSecondary)
        }
    }

    private func revealHeadline(for package: ComicBookPackage) -> String {
        if let headline = package.ctaMetadata.revealHeadline {
            return headline
        }
        if let legacyHeadline = package.legacyRevealMetadata?.headline {
            return legacyHeadline
        }
        return "Your Personalized Comic Is Ready"
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
