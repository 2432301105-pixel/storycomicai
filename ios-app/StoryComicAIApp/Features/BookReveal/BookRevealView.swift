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
            EditorialBackground(accent: AppColor.accentSecondary, showsDeskBand: true)

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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }

    private func loadedView(package: ComicBookPackage) -> some View {
        let style = StoryStyle(displayLabel: package.styleLabel) ?? .cinematic

        return VStack(alignment: .leading, spacing: AppSpacing.xl) {
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

                bookObject(package: package, style: style)
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

    private func bookObject(package: ComicBookPackage, style: StoryStyle) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: AppElevation.Book.coverCorner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColor.accent(for: style).opacity(0.95), AppColor.textPrimary],
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

            styleCoverPattern(style: style)
                .opacity(0.36)
                .clipShape(RoundedRectangle(cornerRadius: AppElevation.Book.coverCorner, style: .continuous))

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
                HStack {
                    Text(style.moodLabel)
                        .font(AppTypography.badge)
                        .foregroundStyle(AppColor.textOnDark.opacity(0.84))
                        .tracking(1.0)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(Color.black.opacity(0.18))
                        .clipShape(Capsule())
                    Spacer()
                    Text("NO. 0042")
                        .font(AppTypography.badge)
                        .foregroundStyle(AppColor.textOnDark.opacity(0.72))
                        .tracking(1.1)
                }

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

    @ViewBuilder
    private func styleCoverPattern(style: StoryStyle) -> some View {
        GeometryReader { proxy in
            ZStack {
                switch style {
                case .manga:
                    ForEach(0..<7, id: \.self) { index in
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.08 : 0.14))
                            .frame(width: proxy.size.width * 0.92, height: 12)
                            .rotationEffect(.degrees(-34))
                            .offset(x: proxy.size.width * 0.18, y: proxy.size.height * (0.14 + Double(index) * 0.08))
                    }
                case .western:
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: proxy.size.width * 0.6)
                        .offset(x: proxy.size.width * 0.12, y: -proxy.size.height * 0.08)
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: proxy.size.width * 0.82, height: proxy.size.height * 0.26)
                        .rotationEffect(.degrees(-10))
                        .offset(y: proxy.size.height * 0.44)
                case .cartoon:
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: proxy.size.width * 0.42)
                        .offset(x: proxy.size.width * 0.14, y: -proxy.size.height * 0.06)
                    Circle()
                        .fill(Color.white.opacity(0.09))
                        .frame(width: proxy.size.width * 0.24)
                        .offset(x: -proxy.size.width * 0.08, y: proxy.size.height * 0.18)
                case .cinematic:
                    Circle()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: proxy.size.width * 0.64)
                        .offset(x: proxy.size.width * 0.16, y: -proxy.size.height * 0.16)
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: proxy.size.width * 0.86, height: 28)
                        .rotationEffect(.degrees(-28))
                        .offset(x: proxy.size.width * 0.16, y: proxy.size.height * 0.22)
                case .childrensBook:
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: proxy.size.width * 0.36)
                        .offset(x: proxy.size.width * 0.16, y: -proxy.size.height * 0.08)
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: proxy.size.width * 0.62, height: 24)
                        .offset(x: proxy.size.width * 0.12, y: proxy.size.height * 0.52)
                }
            }
        }
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
