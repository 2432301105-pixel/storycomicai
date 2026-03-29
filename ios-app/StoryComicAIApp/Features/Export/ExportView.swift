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
        VStack(spacing: AppSpacing.md) {
            ComicPresentationModePicker(
                selectedMode: coordinator.mode,
                onSelect: viewModel.switchMode
            )

            switch coordinator.packageState {
            case .idle, .loading:
                LoadingStateView(title: "Preparing Export")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case let .failed(message):
                ErrorStateView(title: "Export Not Available", message: message) {
                    Task { await coordinator.retry() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case let .loaded(package):
                loadedContent(package: package)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
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
    }

    @ViewBuilder
    private func loadedContent(package: ComicBookPackage) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Export & Share")
                    .font(AppTypography.heading)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Generate a shareable file for your personalized comic.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)

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

                actionButton(package: package)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        Spacer()
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
