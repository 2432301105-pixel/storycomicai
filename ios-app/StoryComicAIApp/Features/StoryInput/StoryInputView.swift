import SwiftUI

struct StoryInputView: View {
    @StateObject var viewModel: StoryInputViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToStyleSelection: Bool = false

    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.accentSecondary, showsDeskBand: false)

            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Story Draft")
                        .font(AppTypography.eyebrow)
                        .foregroundStyle(AppColor.textTertiary)
                        .tracking(1.4)
                        .textCase(.uppercase)

                    Text("Write the premise")
                        .font(AppTypography.title)
                        .foregroundStyle(AppColor.textPrimary)

                    Text("Give the comic its conflict, tone and emotional center. The story planner will turn this into pages and panels.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                }

                CardContainer(emphasize: true) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Story Prompt")
                            .font(AppTypography.meta)
                            .foregroundStyle(AppColor.textTertiary)
                            .textCase(.uppercase)

                        TextEditor(text: $flowStore.storyText)
                            .frame(minHeight: 220)
                            .padding(8)
                            .background(AppColor.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

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

                PrimaryButton(title: "Continue") {
                    if viewModel.isStoryValid(flowStore.storyText) {
                        navigateToStyleSelection = true
                    }
                }

                Spacer()
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle("Story")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
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
