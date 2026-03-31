import SwiftUI

struct PaywallView: View {
    @StateObject var viewModel: PaywallViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToViewer: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                switch viewModel.state {
                case .idle, .loading:
                    LoadingStateView(title: "Preparing unlock options", subtitle: "Staging the rest of your story")
                        .frame(height: 420)

                case let .failed(message):
                    ErrorStateView(title: "Paywall not available", message: message) {
                        viewModel.retry(projectID: presentationProjectID)
                    }
                    .frame(height: 420)

                case let .loaded(content):
                    loadedContent(content: content)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.xl)
            .padding(.bottom, AppSpacing.section)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Unlock")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.onAppear(projectID: presentationProjectID)
        }
    }

    @ViewBuilder
    private func loadedContent(content: PaywallViewModel.Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            lockedPreview

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(content.headline)
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)
                Text(content.subheadline)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
            }

            CardContainer {
                Text(content.lockReasonText)
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColor.warning)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: AppSpacing.md) {
                ForEach(content.plans) { plan in
                    Button {
                        viewModel.selectedPlanID = plan.id
                    } label: {
                        CardContainer(emphasize: viewModel.selectedPlanID == plan.id || plan.isRecommended) {
                            HStack(alignment: .top, spacing: AppSpacing.md) {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    if plan.isRecommended {
                                        Text(plan.badgeLabel ?? "Best Value")
                                            .font(AppTypography.meta)
                                            .foregroundStyle(AppColor.accent)
                                            .padding(.horizontal, AppSpacing.xs)
                                            .padding(.vertical, AppSpacing.xxs)
                                            .background(AppColor.surfaceMuted)
                                            .clipShape(Capsule())
                                    }
                                    Text(plan.title)
                                        .font(AppTypography.section)
                                        .foregroundStyle(AppColor.textPrimary)
                                    Text(plan.priceText)
                                        .font(AppTypography.body)
                                        .foregroundStyle(AppColor.textSecondary)
                                }

                                Spacer()

                                Image(systemName: viewModel.selectedPlanID == plan.id ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(viewModel.selectedPlanID == plan.id ? AppColor.accent : AppColor.borderStrong)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
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
        }
    }

    private var lockedPreview: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [AppColor.accent(for: flowStore.selectedStyle).opacity(0.94), AppColor.textPrimary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 260)
            .overlay {
                AppColor.lockedOverlay
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(flowStore.projectName.isEmpty ? "Your comic continues here" : flowStore.projectName)
                        .font(AppTypography.heading)
                        .foregroundStyle(AppColor.textOnDark)
                    Text("Read the rest of the story, unlock export and keep the finished edition.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textOnDark.opacity(0.82))
                }
                .padding(AppSpacing.lg)
            }
            .overlay(alignment: .topLeading) {
                Text("Preview locked")
                    .font(AppTypography.meta)
                    .foregroundStyle(AppColor.textOnDark)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(Color.black.opacity(0.22))
                    .clipShape(Capsule())
                    .padding(AppSpacing.lg)
            }
            .shadow(color: AppColor.bookShadow, radius: 24, x: 0, y: 14)
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
