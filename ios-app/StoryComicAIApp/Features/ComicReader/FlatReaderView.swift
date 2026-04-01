import SwiftUI

struct FlatReaderView: View {
    @ObservedObject var coordinator: ComicPresentationCoordinator
    @StateObject private var viewModel: FlatReaderViewModel
    @State private var chromeVisible: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(coordinator: ComicPresentationCoordinator) {
        self.coordinator = coordinator
        _viewModel = StateObject(wrappedValue: FlatReaderViewModel(coordinator: coordinator))
    }

    var body: some View {
        ZStack {
            AppColor.backgroundPrimary.ignoresSafeArea()

            switch coordinator.packageState {
            case .idle, .loading:
                LoadingStateView(title: "Loading reader", subtitle: "Preparing your pages")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case let .failed(message):
                ErrorStateView(title: "Reader could not open", message: message) {
                    Task { await coordinator.retry() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case let .loaded(package):
                loadedView(package: package)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }

    private func loadedView(package: ComicBookPackage) -> some View {
        let style = StoryStyle(displayLabel: package.styleLabel) ?? .cinematic
        let accent = AppColor.accent(for: style)

        return ZStack(alignment: .top) {
            TabView(selection: selectionBinding(pageCount: package.pages.count)) {
                ForEach(Array(package.pages.enumerated()), id: \.element.id) { index, page in
                    readerPage(
                        page: page,
                        index: index,
                        currentPage: coordinator.currentPageIndex,
                        accent: accent
                    )
                        .tag(index)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, 88)
                        .padding(.bottom, package.isPaywallLocked ? 140 : 104)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(AppMotion.modeSwitch(reduceMotion: reduceMotion)) {
                                chromeVisible.toggle()
                            }
                        }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            if chromeVisible {
                VStack(spacing: AppSpacing.md) {
                    ComicPresentationModePicker(
                        selectedMode: coordinator.mode,
                        onSelect: viewModel.switchMode
                    )

                    HStack {
                        Text(package.title)
                            .font(AppTypography.heading)
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        Text("\(coordinator.currentPageIndex + 1) / \(package.pages.count)")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
                .transition(.opacity)
            }

            VStack {
                Spacer()

                if package.isPaywallLocked {
                    CardContainer(emphasize: true) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(package.paywallLockReasonText)
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColor.warning)
                            Text("Unlock to export the finished edition.")
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }

                if chromeVisible {
                    HStack(spacing: AppSpacing.sm) {
                        Button {
                            viewModel.openExport()
                        } label: {
                            Label(package.ctaMetadata.exportLabel, systemImage: "square.and.arrow.up")
                                .font(AppTypography.footnote)
                                .foregroundStyle(package.isPaywallLocked ? AppColor.textTertiary : AppColor.textPrimary)
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
                        .disabled(package.isPaywallLocked)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.lg)
                    .transition(.opacity)
                }
            }
        }
    }

    @ViewBuilder
    private func readerPage(
        page: ComicPresentationPage,
        index: Int,
        currentPage: Int,
        accent: Color
    ) -> some View {
        if shouldRenderContent(for: index, currentPage: currentPage) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text(page.title)
                        .font(AppTypography.section)
                        .foregroundStyle(AppColor.textPrimary)

                    ZStack {
                        OptimizedComicImageView(
                            thumbnailURL: page.thumbnailURL,
                            fullImageURL: page.fullImageURL,
                            strategy: .thumbnailThenFull,
                            contentMode: .fit,
                            thumbnailMaxPixelSize: 1_000,
                            fullMaxPixelSize: 2_200
                        )
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        ComicPageOverlayLayer(overlays: page.overlays, accent: accent)
                            .padding(10)
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppColor.surfaceMuted.opacity(0.45))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if let caption = page.caption {
                        Text(caption)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColor.pagePaper)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppColor.border.opacity(0.85), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: AppColor.bookShadow, radius: 14, x: 0, y: 8)
            }
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColor.surfaceMuted)
                .overlay {
                    ProgressView()
                        .tint(AppColor.accent)
                }
        }
    }

    private func selectionBinding(pageCount: Int) -> Binding<Int> {
        Binding(
            get: { max(0, min(coordinator.currentPageIndex, max(pageCount - 1, 0))) },
            set: { coordinator.setCurrentPageIndex($0) }
        )
    }

    private func shouldRenderContent(for index: Int, currentPage: Int) -> Bool {
        let radius = 1
        return index >= (currentPage - radius) && index <= (currentPage + radius)
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        FlatReaderView(
            coordinator: ComicPresentationCoordinator(
                projectID: UUID(),
                comicPackageService: MockComicPackageService(),
                analyticsService: ConsoleAnalyticsService(),
                hapticProvider: NoopHapticProvider(),
                initialMode: .flatReader
            )
        )
    }
    .previewContainer()
}
#endif
