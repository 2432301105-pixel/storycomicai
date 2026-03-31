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
        ZStack {
            EditorialBackground(accent: AppColor.accentSecondary, showsDeskBand: true)

            VStack(spacing: AppSpacing.lg) {
                ComicPresentationModePicker(
                    selectedMode: coordinator.mode,
                    onSelect: viewModel.switchMode
                )

                switch coordinator.packageState {
                case .idle, .loading:
                    LoadingStateView(title: "Opening the book", subtitle: "Preparing the first spread")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case let .failed(message):
                    ErrorStateView(title: "Book preview failed", message: message) {
                        Task { await coordinator.retry() }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case let .loaded(package):
                    loadedView(package: package)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
    }

    @ViewBuilder
    private func loadedView(package: ComicBookPackage) -> some View {
        let spread = pageSpread(for: package)

        VStack(spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(package.title)
                    .font(AppTypography.heading)
                    .foregroundStyle(AppColor.textPrimary)
                Text(currentSpreadLabel(package: package, spread: spread))
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GeometryReader { proxy in
                PageTurnView(
                    leftPage: spread.left,
                    rightPage: spread.right,
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
            .frame(height: 540)

            CardContainer {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text("Tap page edges or drag to turn")
                            .font(AppTypography.bodyStrong)
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        Text("\(coordinator.currentPageIndex + 1) / \(package.pages.count)")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    if package.isPaywallLocked {
                        Text(package.paywallLockReasonText)
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.warning)
                    }

                    HStack(spacing: AppSpacing.sm) {
                        compactButton(title: "Previous", systemImage: "chevron.left", disabled: !coordinator.canGoPrevious) {
                            coordinator.goToPreviousPage()
                        }
                        compactButton(title: "Flat Reader", systemImage: "doc.text.image") {
                            viewModel.openFlatReader()
                        }
                        compactButton(title: package.ctaMetadata.exportLabel, systemImage: "square.and.arrow.up", disabled: package.isPaywallLocked) {
                            viewModel.openExport()
                        }
                        compactButton(title: "Next", systemImage: "chevron.right", disabled: !coordinator.canGoNext) {
                            coordinator.goToNextPage()
                        }
                    }
                }
            }
        }
    }

    private func compactButton(
        title: String,
        systemImage: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AppTypography.footnote)
                .foregroundStyle(disabled ? AppColor.textTertiary : AppColor.textPrimary)
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
        .disabled(disabled)
    }

    private func pageSpread(for package: ComicBookPackage) -> (left: ComicPresentationPage?, right: ComicPresentationPage?) {
        guard !package.pages.isEmpty else { return (nil, nil) }
        let currentIndex = min(max(coordinator.currentPageIndex, 0), package.pages.count - 1)
        let nextIndex = min(currentIndex + 1, package.pages.count - 1)
        let rightPage: ComicPresentationPage? = nextIndex == currentIndex ? nil : package.pages[nextIndex]
        return (package.pages[currentIndex], rightPage)
    }

    private func currentSpreadLabel(
        package: ComicBookPackage,
        spread: (left: ComicPresentationPage?, right: ComicPresentationPage?)
    ) -> String {
        let leftValue = spread.left?.pageNumber ?? 0
        if let rightValue = spread.right?.pageNumber {
            return "Spread \(leftValue)-\(rightValue) of \(package.pages.count)"
        }
        return "Page \(leftValue) of \(package.pages.count)"
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
