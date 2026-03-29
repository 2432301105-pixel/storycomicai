import SwiftUI

struct FlatReaderView: View {
    @ObservedObject var coordinator: ComicPresentationCoordinator
    @StateObject private var viewModel: FlatReaderViewModel

    init(coordinator: ComicPresentationCoordinator) {
        self.coordinator = coordinator
        _viewModel = StateObject(wrappedValue: FlatReaderViewModel(coordinator: coordinator))
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ComicPresentationModePicker(
                selectedMode: coordinator.mode,
                onSelect: viewModel.switchMode
            )

            switch coordinator.packageState {
            case .idle, .loading:
                LoadingStateView(title: "Loading Reader")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case let .failed(message):
                ErrorStateView(title: "Reader Could Not Open", message: message) {
                    Task { await coordinator.retry() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case let .loaded(package):
                TabView(selection: selectionBinding(pageCount: package.pages.count)) {
                    ForEach(Array(package.pages.enumerated()), id: \.element.id) { index, page in
                        CardContainer {
                            if shouldRenderContent(for: index, currentPage: coordinator.currentPageIndex) {
                                VStack(alignment: .leading, spacing: AppSpacing.md) {
                                    Text("Page \(page.pageNumber)")
                                        .font(AppTypography.footnote)
                                        .foregroundStyle(AppColor.textSecondary)

                                    Text(page.title)
                                        .font(AppTypography.heading)
                                        .foregroundStyle(AppColor.textPrimary)

                                    pageImage(page: page)
                                        .frame(maxWidth: .infinity, maxHeight: 420)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                    if let caption = page.caption {
                                        Text(caption)
                                            .font(AppTypography.body)
                                            .foregroundStyle(AppColor.textSecondary)
                                    }
                                }
                            } else {
                                VStack(spacing: AppSpacing.sm) {
                                    Text("Page \(page.pageNumber)")
                                        .font(AppTypography.footnote)
                                        .foregroundStyle(AppColor.textSecondary)
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColor.backgroundSecondary)
                                        .frame(maxWidth: .infinity, maxHeight: 420)
                                        .overlay {
                                            ProgressView().tint(AppColor.accent)
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.xs)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                if package.isPaywallLocked {
                    Text(package.paywallLockReasonText)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.warning)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(package.ctaMetadata.exportLabel) {
                    viewModel.openExport()
                }
                .buttonStyle(.bordered)
                .tint(AppColor.accent)
                .disabled(package.isPaywallLocked)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }

    private func selectionBinding(pageCount: Int) -> Binding<Int> {
        Binding(
            get: { max(0, min(coordinator.currentPageIndex, max(pageCount - 1, 0))) },
            set: { coordinator.setCurrentPageIndex($0) }
        )
    }

    @ViewBuilder
    private func pageImage(page: ComicPresentationPage) -> some View {
        OptimizedComicImageView(
            thumbnailURL: page.thumbnailURL,
            fullImageURL: page.fullImageURL,
            strategy: .thumbnailThenFull,
            contentMode: .fill,
            thumbnailMaxPixelSize: 900,
            fullMaxPixelSize: 2_200
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
