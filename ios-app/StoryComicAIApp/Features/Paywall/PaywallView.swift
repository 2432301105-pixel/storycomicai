import SwiftUI

struct PaywallView: View {
    @StateObject var viewModel: PaywallViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToViewer: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            switch viewModel.state {
            case .idle, .loading:
                LoadingStateView(title: "Preparing Unlock Options")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case let .failed(message):
                ErrorStateView(title: "Paywall Not Available", message: message) {
                    viewModel.retry(projectID: presentationProjectID)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case let .loaded(content):
                loadedContent(content: content)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Paywall")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.onAppear(projectID: presentationProjectID)
        }
    }

    @ViewBuilder
    private func loadedContent(content: PaywallViewModel.Content) -> some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(content.headline)
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(content.subheadline)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            CardContainer {
                Text(content.lockReasonText)
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColor.warning)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach(content.plans) { plan in
                Button {
                    viewModel.selectedPlanID = plan.id
                } label: {
                    CardContainer {
                        HStack {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(plan.title)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColor.textPrimary)
                                Text(plan.priceText)
                                    .font(AppTypography.footnote)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                            Spacer()
                            if plan.isRecommended {
                                Text(plan.badgeLabel ?? "Best")
                                    .font(AppTypography.footnote)
                                    .foregroundStyle(AppColor.accent)
                                    .padding(.horizontal, AppSpacing.xs)
                            }
                            Image(systemName: viewModel.selectedPlanID == plan.id ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(viewModel.selectedPlanID == plan.id ? AppColor.success : AppColor.border)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            if let projectID = presentationProjectID {
                NavigationLink(
                    destination: ComicPresentationCoordinatorView(
                        projectID: projectID,
                        container: container,
                        storyPrompt: flowStore.storyText
                    ),
                    isActive: $navigateToViewer
                ) {
                    EmptyView()
                }
            } else {
                CardContainer {
                    Text("Project context is missing. Please return and recreate this flow.")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.warning)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            PrimaryButton(
                title: content.primaryButtonTitle,
                isLoading: viewModel.isUnlocking
            ) {
                guard let projectID = presentationProjectID else { return }
                viewModel.unlock(projectID: projectID) {
                    navigateToViewer = true
                }
            }
            .disabled(
                viewModel.selectedPlanID == nil
                    || viewModel.isUnlocking
                    || presentationProjectID == nil
            )

            Spacer()
        }
    }

    private var presentationProjectID: UUID? {
        flowStore.createdProject?.id
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    PaywallView(
        viewModel: PaywallViewModel(
            comicPackageService: AppContainer.preview().comicPackageService,
            analyticsService: AppContainer.preview().analyticsService
        ),
        flowStore: CreateProjectFlowStore(),
        container: .preview()
    )
    .previewContainer()
}
#endif
