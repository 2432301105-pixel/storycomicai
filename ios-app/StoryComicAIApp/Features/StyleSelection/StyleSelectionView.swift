import SwiftUI

struct StyleSelectionView: View {
    @StateObject var viewModel: StyleSelectionViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToPresentation: Bool = false
    @State private var presentationProjectID: UUID?

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                ForEach(StoryStyle.allCases) { style in
                    Button {
                        flowStore.selectedStyle = style
                    } label: {
                        CardContainer {
                            HStack {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text(style.displayName)
                                        .font(AppTypography.body)
                                        .foregroundStyle(AppColor.textPrimary)
                                    Text("Selected visual language for rendering.")
                                        .font(AppTypography.footnote)
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                                Spacer()
                                Image(systemName: flowStore.selectedStyle == style ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(flowStore.selectedStyle == style ? AppColor.success : AppColor.border)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomActionBar
        }
        .navigationDestination(isPresented: $navigateToPresentation) {
            if let projectID = presentationProjectID {
                ComicPresentationCoordinatorView(
                    projectID: projectID,
                    container: container,
                    initialMode: .reveal,
                    storyPrompt: flowStore.storyText
                )
            } else {
                ErrorStateView(
                    title: "Presentation Not Ready",
                    message: "Project could not be prepared. Please retry."
                ) {}
            }
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Style")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var bottomActionBar: some View {
        VStack(spacing: AppSpacing.sm) {
            PrimaryButton(title: "Generate & Reveal", isLoading: viewModel.isCreatingProject) {
                Task {
                    let success = await viewModel.ensureProjectExists(for: flowStore)
                    if success, let projectID = flowStore.createdProject?.id {
                        presentationProjectID = projectID
                        navigateToPresentation = true
                    }
                }
            }
            .disabled(viewModel.isCreatingProject)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.sm)
        .background(AppColor.backgroundPrimary)
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    StyleSelectionView(
        viewModel: StyleSelectionViewModel(projectService: AppContainer.preview().projectService),
        flowStore: CreateProjectFlowStore(),
        container: .preview()
    )
    .previewContainer()
}
#endif
