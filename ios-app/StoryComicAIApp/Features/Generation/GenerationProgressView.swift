import SwiftUI

struct GenerationProgressView: View {
    @StateObject var viewModel: GenerationProgressViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToPaywall: Bool = false

    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.accentSecondary, showsDeskBand: false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    Text("Building your preview edition")
                        .font(AppTypography.title)
                        .foregroundStyle(AppColor.textPrimary)

                    Text("We are planning the first pages, laying out the panels and preparing the book reveal.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)

                    CardContainer(emphasize: true) {
                        VStack(alignment: .leading, spacing: AppSpacing.lg) {
                            generationBoard

                            ProgressView(value: viewModel.progress, total: 1)
                                .tint(AppColor.accent)

                            ProgressStepListView(steps: viewModel.steps)
                        }
                    }

                    NavigationLink(
                        destination: PaywallView(
                            viewModel: PaywallViewModel(
                                comicPackageService: container.comicPackageService,
                                analyticsService: container.analyticsService
                            ),
                            flowStore: flowStore,
                            container: container
                        ),
                        isActive: $navigateToPaywall
                    ) { EmptyView() }

                    PrimaryButton(title: viewModel.isComplete ? "Continue to reveal" : "Preparing preview", isLoading: !viewModel.isComplete) {
                        if viewModel.isComplete {
                            navigateToPaywall = true
                        }
                    }
                    .disabled(!viewModel.isComplete)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, AppSpacing.section)
            }
        }
        .navigationTitle("Generation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { viewModel.startIfNeeded() }
    }

    private var generationBoard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Preview panels")
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
        viewModel: GenerationProgressViewModel(),
        flowStore: CreateProjectFlowStore(),
        container: .preview()
    )
    .previewContainer()
}
#endif
