import SwiftUI

struct StyleSelectionView: View {
    @StateObject var viewModel: StyleSelectionViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToPresentation: Bool = false
    @State private var presentationProjectID: UUID?

    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.accentSecondary, showsDeskBand: false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    header

                    ForEach(StoryStyle.allCases) { style in
                        Button {
                            flowStore.selectedStyle = style
                        } label: {
                            StyleOptionCard(style: style, isSelected: flowStore.selectedStyle == style)
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
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, AppSpacing.section)
            }
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
        .navigationTitle("Style")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Choose The Edition")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)
            Text("Each style changes the cover language, page tone and final collectible feel of your comic.")
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
        }
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
        .background(AppColor.tabBarBackground)
        .overlay(alignment: .top) {
            Divider()
                .overlay(AppColor.border)
        }
    }
}

private struct StyleOptionCard: View {
    let style: StoryStyle
    let isSelected: Bool

    var body: some View {
        CardContainer(emphasize: isSelected) {
            HStack(spacing: AppSpacing.md) {
                ComicCoverCard(
                    title: style.displayName,
                    subtitle: style.shortSignature,
                    accent: AppColor.accent(for: style),
                    style: style,
                    eyebrow: style.moodLabel,
                    badge: isSelected ? "Selected" : "Edition",
                    emphasize: isSelected
                )
                .frame(width: 112)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(style.displayName)
                        .font(AppTypography.section)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(style.editorialBlurb)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? AppColor.accent(for: style) : AppColor.borderStrong)
                        Text(isSelected ? "Selected for rendering" : "Tap to choose this edition")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
