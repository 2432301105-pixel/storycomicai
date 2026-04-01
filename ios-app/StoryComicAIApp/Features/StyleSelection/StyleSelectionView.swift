import SwiftUI

struct StyleSelectionView: View {
    @StateObject var viewModel: StyleSelectionViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToPresentation: Bool = false
    @State private var presentationProjectID: UUID?

    var body: some View {
        FloatingPanelScreen(accent: AppColor.accentSecondary) {
            header
        } content: {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
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
        } footer: {
            PrimaryButton(title: "Generate Comic", isLoading: viewModel.isCreatingProject) {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationDestination(isPresented: $navigateToPresentation) {
            if let projectID = presentationProjectID {
                ComicPresentationCoordinatorView(
                    projectID: projectID,
                    container: container,
                    initialMode: .reveal,
                    storyText: flowStore.storyText
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
}

private struct StyleOptionCard: View {
    let style: StoryStyle
    let isSelected: Bool

    var body: some View {
        CardContainer(emphasize: isSelected) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                ComicCoverCard(
                    title: style.coverTitle,
                    subtitle: style.coverSubtitle,
                    accent: AppColor.accent(for: style),
                    style: style,
                    eyebrow: style.coverEyebrow,
                    badge: isSelected ? "Selected" : nil,
                    emphasize: isSelected
                )
                .frame(width: 94)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(style.displayName)
                        .font(AppTypography.heading)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(style.editorialBlurb)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? AppColor.accent(for: style) : AppColor.borderStrong)
                        Text(isSelected ? "Selected for render" : "Tap to choose")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .padding(.top, AppSpacing.xs)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
