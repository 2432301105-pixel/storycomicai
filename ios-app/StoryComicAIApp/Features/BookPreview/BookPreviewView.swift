import SwiftUI

struct BookPreviewView: View {
    @ObservedObject var coordinator: ComicPresentationCoordinator
    @StateObject private var viewModel: BookPreviewViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(coordinator: ComicPresentationCoordinator) {
        self.coordinator = coordinator
        _viewModel = StateObject(wrappedValue: BookPreviewViewModel(coordinator: coordinator))
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ComicPresentationModePicker(
                selectedMode: coordinator.mode,
                onSelect: viewModel.switchMode
            )

            switch coordinator.packageState {
            case .idle, .loading:
                LoadingStateView(title: "Opening Book", subtitle: "Preparing pages")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case let .failed(message):
                ErrorStateView(title: "Book Preview Failed", message: message) {
                    Task { await coordinator.retry() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case let .loaded(package):
                loadedView(package: package)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }

    @ViewBuilder
    private func loadedView(package: ComicBookPackage) -> some View {
        VStack(spacing: AppSpacing.md) {
            GeometryReader { proxy in
                PageTurnView(
                    page: coordinator.currentPage,
                    progress: viewModel.turnProgress,
                    direction: viewModel.turnDirection,
                    reduceMotion: reduceMotion
                )
                .gesture(
                    DragGesture(minimumDistance: 6)
                        .onChanged { value in
                            viewModel.onDragChanged(value)
                        }
                        .onEnded { value in
                            viewModel.onDragEnded(
                                value,
                                containerWidth: proxy.size.width,
                                reduceMotion: reduceMotion
                            )
                        }
                )
                .simultaneousGesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            viewModel.onTap(
                                locationX: value.location.x,
                                containerWidth: proxy.size.width,
                                reduceMotion: reduceMotion
                            )
                        }
                )
                .animation(AppMotion.pageTurn(reduceMotion: reduceMotion), value: coordinator.currentPageIndex)
            }
            .frame(height: 520)

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

            HStack(spacing: AppSpacing.sm) {
                Button {
                    coordinator.goToPreviousPage()
                } label: {
                    Label("Previous", systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)
                .tint(AppColor.accent)
                .disabled(!coordinator.canGoPrevious)

                Spacer()

                Text("\(coordinator.currentPageIndex + 1) / \(package.pages.count)")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColor.textSecondary)

                Spacer()

                Button {
                    coordinator.goToNextPage()
                } label: {
                    Label("Next", systemImage: "chevron.right")
                }
                .buttonStyle(.bordered)
                .tint(AppColor.accent)
                .disabled(!coordinator.canGoNext)
            }

            HStack(spacing: AppSpacing.sm) {
                Button("Flat Reader") {
                    viewModel.openFlatReader()
                }
                .buttonStyle(.bordered)
                .tint(AppColor.accent)

                Button(package.ctaMetadata.exportLabel) {
                    viewModel.openExport()
                }
                .buttonStyle(.bordered)
                .tint(AppColor.accent)
                .disabled(package.isPaywallLocked)
            }

            Text("Sağa dokun veya sola kaydır: sonraki sayfa. Sola dokun veya sağa kaydır: önceki sayfa.")
                .font(AppTypography.footnote)
                .foregroundStyle(AppColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if coordinator.isPrefetchingAssets {
                Text("Optimizing next pages…")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        BookPreviewView(
            coordinator: ComicPresentationCoordinator(
                projectID: UUID(),
                comicPackageService: MockComicPackageService(),
                analyticsService: ConsoleAnalyticsService(),
                hapticProvider: NoopHapticProvider(),
                initialMode: .preview
            )
        )
    }
    .previewContainer()
}
#endif
