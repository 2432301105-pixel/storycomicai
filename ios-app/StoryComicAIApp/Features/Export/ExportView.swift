import SwiftUI

struct ExportView: View {
    @ObservedObject var coordinator: ComicPresentationCoordinator
    @StateObject private var viewModel: ExportViewModel

    init(coordinator: ComicPresentationCoordinator, exportService: any ExportService) {
        self.coordinator = coordinator
        _viewModel = StateObject(
            wrappedValue: ExportViewModel(
                coordinator: coordinator,
                exportService: exportService
            )
        )
    }

    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.accentSecondary, showsDeskBand: true)

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.lg) {
                    ComicPresentationModePicker(
                        selectedMode: coordinator.mode,
                        onSelect: viewModel.switchMode
                    )

                    switch coordinator.packageState {
                    case .idle, .loading:
                        LoadingStateView(title: "Preparing Export", subtitle: "Staging a collectible file package")
                            .frame(maxWidth: .infinity, minHeight: 420)

                    case let .failed(message):
                        ErrorStateView(title: "Export Not Available", message: message) {
                            Task { await coordinator.retry() }
                        }
                        .frame(maxWidth: .infinity, minHeight: 420)

                    case let .loaded(package):
                        loadedContent(package: package)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.section)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(
            isPresented: Binding(
                get: { viewModel.shareSheetURL != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.didDismissShareSheet()
                    }
                }
            )
        ) {
            if let shareURL = viewModel.shareSheetURL {
                ShareSheetView(items: [shareURL])
            }
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }

    @ViewBuilder
    private func loadedContent(package: ComicBookPackage) -> some View {
        let style = StoryStyle(displayLabel: package.styleLabel) ?? .cinematic

        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Export Studio")
                    .font(AppTypography.eyebrow)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(1.3)
                    .textCase(.uppercase)

                Text("Package your comic as a finished edition")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Prepare a shareable PDF or image bundle without losing the premium book presentation.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
            }

            ComicCoverCard(
                title: package.cover.titleText ?? package.title,
                subtitle: package.cover.subtitleText ?? package.subtitle ?? "Collector export ready",
                accent: AppColor.accent(for: style),
                style: style,
                eyebrow: package.styleLabel,
                badge: viewModel.selectedType.displayTitle,
                emphasize: true
            )

            CardContainer(emphasize: true) {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Export format")
                        .font(AppTypography.section)
                        .foregroundStyle(AppColor.textPrimary)

                    Picker("Export Type", selection: $viewModel.selectedType) {
                        ForEach(ComicExportType.allCases) { type in
                            Text(type.displayTitle).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(availabilityText(for: package))
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)

                    if package.isPaywallLocked {
                        paywallLockedSection(package: package)
                    }

                    statusPanel(for: package)
                    actionButton(package: package)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func actionButton(package: ComicBookPackage) -> some View {
        if package.isPaywallLocked {
            PrimaryButton(title: "Unlock Required") {}
                .disabled(true)
        } else {
            switch viewModel.state {
            case .idle:
                PrimaryButton(title: package.ctaMetadata.exportLabel) {
                    viewModel.startExport()
                }

            case .creating:
                PrimaryButton(title: "Creating Export", isLoading: true) {}
                    .disabled(true)

            case .queued:
                PrimaryButton(title: "Queued", isLoading: true) {}
                    .disabled(true)

            case let .running(_, progress):
                let percent = Int((progress ?? 0) * 100)
                PrimaryButton(title: "Processing \(percent)%", isLoading: true) {}
                    .disabled(true)

            case .ready:
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    PrimaryButton(title: "Share Export") {
                        viewModel.prepareShare()
                    }
                    Text("Export ready. Tap to download and open share sheet.")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                }

            case .downloading:
                PrimaryButton(title: "Downloading", isLoading: true) {}
                    .disabled(true)

            case .sharing:
                PrimaryButton(title: "Opening Share Sheet", isLoading: true) {}
                    .disabled(true)

            case let .failed(message, retryable):
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(message)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.error)

                    if retryable {
                        PrimaryButton(title: "Retry Export") {
                            viewModel.retry()
                        }
                    } else {
                        PrimaryButton(title: "Unavailable", isLoading: false) {
                            // Intentionally no-op for non-retryable failures.
                        }
                        .disabled(true)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func paywallLockedSection(package: ComicBookPackage) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(package.paywallLockReasonText)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.warning)
            if let offer = package.primaryPaywallOffer {
                Text("Current offer: \(offer.formattedPriceText)")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .padding(AppSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.backgroundSecondary.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func statusPanel(for package: ComicBookPackage) -> some View {
        switch viewModel.state {
        case .idle:
            CardContainer {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Collector delivery")
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Generate a polished file package that keeps the book feeling intact when shared.")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .creating:
            LoadingStateView(title: "Creating export", subtitle: "Binding pages into a finished delivery")
                .frame(height: 180)

        case .queued:
            LoadingStateView(title: "Queued for export", subtitle: "The edition is waiting for packaging")
                .frame(height: 180)

        case let .running(_, progress):
            CardContainer(emphasize: true) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Preparing your file")
                        .font(AppTypography.section)
                        .foregroundStyle(AppColor.textPrimary)
                    ProgressView(value: progress ?? 0.2)
                        .tint(AppColor.accent(for: StoryStyle(displayLabel: package.styleLabel) ?? .cinematic))
                    Text("We are assembling a premium \(viewModel.selectedType.displayTitle.lowercased()) package for sharing or printing.")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .ready:
            CardContainer(emphasize: true) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Export ready")
                        .font(AppTypography.section)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Download the finished package and open the share sheet to send or archive it.")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .downloading:
            LoadingStateView(title: "Downloading file", subtitle: "Pulling the finished artifact to your device")
                .frame(height: 180)

        case .sharing:
            LoadingStateView(title: "Opening share sheet", subtitle: "Handing off the finished edition")
                .frame(height: 180)

        case let .failed(message, _):
            ErrorStateView(title: "Export failed", message: message) {
                viewModel.retry()
            }
            .frame(height: 180)
        }
    }

    private func availabilityText(for package: ComicBookPackage) -> String {
        if package.isPaywallLocked {
            return "Export is currently locked by paywall."
        }

        switch viewModel.selectedType {
        case .pdf:
            return package.exportAvailability.isPDFAvailable ? "PDF export available." : "PDF export is not available for this project."
        case .imageBundle:
            return package.exportAvailability.isImagePackAvailable ? "Image bundle export available." : "Image bundle export is not available for this project."
        }
    }
}

#if !CI_DISABLE_PREVIEWS
struct ExportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ExportView(
                coordinator: ComicPresentationCoordinator(
                    projectID: UUID(),
                    comicPackageService: MockComicPackageService(),
                    analyticsService: ConsoleAnalyticsService(),
                    hapticProvider: NoopHapticProvider(),
                    initialMode: .export
                ),
                exportService: DefaultExportService(apiClient: MockAPIClient())
            )
        }
        .previewContainer()
    }
}
#endif
