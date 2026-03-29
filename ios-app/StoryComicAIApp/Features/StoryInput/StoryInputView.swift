import SwiftUI

struct StoryInputView: View {
    @StateObject var viewModel: StoryInputViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToStyleSelection: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            CardContainer {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Story Prompt")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)

                    TextEditor(text: $flowStore.storyText)
                        .frame(minHeight: 180)
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
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
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
