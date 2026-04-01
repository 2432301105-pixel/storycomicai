import SwiftUI

struct StoryInputView: View {
    @StateObject var viewModel: StoryInputViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToStyleSelection: Bool = false
    @FocusState private var storyFieldFocused: Bool

    var body: some View {
        FloatingPanelScreen(accent: AppColor.accentSecondary) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Story Source")
                    .font(AppTypography.eyebrow)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(1.4)
                    .textCase(.uppercase)

                Text("Tell the story")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Write the actual story you want turned into a comic book. We use this text to shape scenes, captions, dialogue beats and page flow.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
        } content: {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                CardContainer {
                    HStack(spacing: AppSpacing.sm) {
                        storyStep(title: "Story")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColor.textTertiary)
                        storyStep(title: "Scenes")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColor.textTertiary)
                        storyStep(title: "Panels")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColor.textTertiary)
                        storyStep(title: "Comic")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Your Story")
                        .font(AppTypography.meta)
                        .foregroundStyle(AppColor.textTertiary)
                        .textCase(.uppercase)

                    TextEditor(text: $flowStore.storyText)
                        .focused($storyFieldFocused)
                        .frame(minHeight: 260)
                        .padding(8)
                        .background(AppColor.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text("Write events, conflict, emotional turns and key moments. This text becomes the comic’s narrative backbone.")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } footer: {
            NavigationLink(
                destination: StyleSelectionView(
                    viewModel: StyleSelectionViewModel(projectService: container.projectService),
                    flowStore: flowStore,
                    container: container
                ),
                isActive: $navigateToStyleSelection
            ) {
                EmptyView()
            }

            PrimaryButton(title: "Turn this into a comic") {
                storyFieldFocused = false
                if viewModel.isStoryValid(flowStore.storyText) {
                    navigateToStyleSelection = true
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private func storyStep(title: String) -> some View {
        Text(title)
            .font(AppTypography.badge)
            .foregroundStyle(AppColor.textPrimary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColor.surfaceInset.opacity(0.9))
            .clipShape(Capsule())
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    StoryInputPreviewFactory.make()
}
#endif

private enum StoryInputPreviewFactory {
    @MainActor
    static func make() -> some View {
        let flowStore = CreateProjectFlowStore()
        flowStore.storyText = "A hero discovers a hidden city conspiracy while protecting loved ones."
        return StoryInputView(
            viewModel: StoryInputViewModel(),
            flowStore: flowStore,
            container: .preview()
        )
        .previewContainer()
    }
}
