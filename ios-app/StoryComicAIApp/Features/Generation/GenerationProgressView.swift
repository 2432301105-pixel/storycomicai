import SwiftUI

struct GenerationProgressView: View {
    @StateObject var viewModel: GenerationProgressViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToPaywall: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            CardContainer {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Generating Free Preview")
                        .font(AppTypography.heading)
                        .foregroundStyle(AppColor.textPrimary)

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

            PrimaryButton(title: viewModel.isComplete ? "Continue" : "Generating", isLoading: !viewModel.isComplete) {
                if viewModel.isComplete {
                    navigateToPaywall = true
                }
            }
            .disabled(!viewModel.isComplete)

            Spacer()
        }
        .padding(AppSpacing.lg)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Generation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { viewModel.startIfNeeded() }
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
