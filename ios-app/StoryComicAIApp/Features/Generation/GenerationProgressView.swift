import SwiftUI

struct GenerationProgressView: View {
    @StateObject var viewModel: GenerationProgressViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToReveal: Bool = false

    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.accentSecondary, showsDeskBand: false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    HStack(alignment: .top, spacing: AppSpacing.md) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text(L10n.string("generation.title"))
                                .font(AppTypography.title)
                                .foregroundStyle(AppColor.textPrimary)

                            Text(L10n.string("generation.subtitle"))
                                .font(AppTypography.body)
                                .foregroundStyle(AppColor.textSecondary)
                        }

                        Spacer(minLength: 0)

                        ComicCoverCard(
                            title: flowStore.projectName.isEmpty ? flowStore.selectedStyle.coverTitle : flowStore.projectName,
                            subtitle: flowStore.selectedStyle.shortSignature,
                            accent: AppColor.accent(for: flowStore.selectedStyle),
                            style: flowStore.selectedStyle,
                            eyebrow: flowStore.selectedStyle.coverEyebrow,
                            badge: viewModel.isComplete ? "READY" : "RENDER",
                            emphasize: false,
                            presentation: .compact,
                            compactVariant: CompactCoverVariant.productDefault(for: flowStore.selectedStyle)
                        )
                        .frame(width: 106)
                    }

                    CardContainer(emphasize: true) {
                        VStack(alignment: .leading, spacing: AppSpacing.lg) {
                            generationBoard

                            ProgressView(value: viewModel.progress, total: 1)
                                .tint(AppColor.accent)

                            Text(viewModel.currentStageTitle)
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColor.textSecondary)

                            ProgressStepListView(steps: viewModel.steps)

                            if let errorMessage = viewModel.errorMessage {
                                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                    Text(errorMessage)
                                        .font(AppTypography.footnote)
                                        .foregroundStyle(AppColor.error)

                                    if viewModel.canRetry {
                                        Button {
                                            viewModel.retry(flowStore: flowStore)
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "arrow.clockwise")
                                                    .font(.system(size: 12, weight: .bold))
                                                Text(L10n.string("action.retry"))
                                                    .font(AppTypography.badge)
                                                    .tracking(1.2)
                                            }
                                            .foregroundStyle(AppColor.textPrimary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(AppColor.surfaceMuted)
                                            .clipShape(Capsule())
                                        }
                                        .disabled(viewModel.isRetrying)
                                    }
                                }
                            }
                        }
                    }

                    if !viewModel.sceneBreakdown.isEmpty {
                        CardContainer {
                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                Text(L10n.string("generation.scene_breakdown"))
                                    .font(AppTypography.eyebrow)
                                    .foregroundStyle(AppColor.textTertiary)
                                    .tracking(1.1)
                                    .textCase(.uppercase)

                                ForEach(Array(viewModel.sceneBreakdown.enumerated()), id: \.offset) { index, item in
                                    Text("\(index + 1). \(item)")
                                        .font(AppTypography.body)
                                        .foregroundStyle(AppColor.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }

                    CardContainer {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text(L10n.string("generation.rendered_pages"))
                                .font(AppTypography.eyebrow)
                                .foregroundStyle(AppColor.textTertiary)
                                .tracking(1.1)
                                .textCase(.uppercase)

                            if viewModel.renderedPageSummary.isEmpty {
                                Text(L10n.string("generation.rendered_pages_preparing"))
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColor.textSecondary)
                            } else {
                                ForEach(Array(viewModel.renderedPageSummary.enumerated()), id: \.offset) { _, item in
                                    Text(item)
                                        .font(AppTypography.body)
                                        .foregroundStyle(AppColor.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }

                    NavigationLink(
                        destination: ComicPresentationCoordinatorView(
                            projectID: flowStore.createdProject?.id ?? UUID(),
                            container: container,
                            initialMode: .reveal,
                            storyText: flowStore.storyText
                        ),
                        isActive: $navigateToReveal
                    ) { EmptyView() }

                    PrimaryButton(title: viewModel.isComplete ? L10n.string("action.continue_reveal") : L10n.string("action.rendering_comic"), isLoading: !viewModel.isComplete) {
                        if viewModel.isComplete {
                            navigateToReveal = true
                        }
                    }
                    .disabled(!viewModel.isComplete)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, AppSpacing.section)
            }
        }
        .navigationTitle(L10n.string("generation.nav"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { viewModel.startIfNeeded(flowStore: flowStore) }
    }

    private var generationBoard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(L10n.string("generation.preview_panels"))
                .font(AppTypography.eyebrow)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(1.1)
                .textCase(.uppercase)

            HStack(spacing: AppSpacing.sm) {
                ForEach(Array(viewModel.steps.enumerated()), id: \.offset) { index, step in
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(color(for: step.status))
                        .frame(maxWidth: .infinity)
                        .frame(height: index == 1 ? 148 : 128)
                        .overlay(alignment: .bottomLeading) {
                            Text(step.title)
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColor.textPrimary)
                                .padding(AppSpacing.sm)
                        }
                }
            }
        }
    }

    private func color(for status: GenerationPipelineStep.StepStatus) -> Color {
        switch status {
        case .pending:
            return AppColor.surfaceMuted
        case .active:
            return AppColor.accentSecondary.opacity(0.8)
        case .completed:
            return AppColor.accentSecondary
        case .failed:
            return AppColor.error.opacity(0.35)
        }
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    GenerationProgressView(
        viewModel: GenerationProgressViewModel(
            comicGenerationService: DefaultComicGenerationService(apiClient: MockAPIClient()),
            comicPackageService: AppContainer.preview().comicPackageService,
            pollingIntervalSeconds: 1,
            projectID: UUID()
        ),
        flowStore: CreateProjectFlowStore(),
        container: .preview()
    )
    .previewContainer()
}
#endif
