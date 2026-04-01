import SwiftUI

struct CreateProjectView: View {
    @StateObject var viewModel: CreateProjectViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToStoryInput: Bool = false

    var body: some View {
        FloatingPanelScreen(accent: AppColor.accent) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Edition Setup")
                        .font(AppTypography.eyebrow)
                        .foregroundStyle(AppColor.textTertiary)
                        .tracking(1.4)
                        .textCase(.uppercase)

                    Text("Name your comic")
                        .font(AppTypography.title)
                        .foregroundStyle(AppColor.textPrimary)

                    Text("Give this edition a strong title before you build the story world around it.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
            }
        } content: {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Project Name")
                    .font(AppTypography.meta)
                    .foregroundStyle(AppColor.textTertiary)
                    .textCase(.uppercase)

                TextField("Example: Shadow of Istanbul", text: $flowStore.projectName)
                    .textFieldStyle(.roundedBorder)

                Text("This title becomes the cover headline of the comic book edition.")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColor.textSecondary)

                if let validationMessage = viewModel.validationMessage {
                    Text(validationMessage)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.warning)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } footer: {
            NavigationLink(
                destination: StoryInputView(
                    viewModel: StoryInputViewModel(),
                    flowStore: flowStore,
                    container: container
                ),
                isActive: $navigateToStoryInput
            ) {
                EmptyView()
            }

            PrimaryButton(title: "Continue") {
                if viewModel.validateProjectName(flowStore.projectName) {
                    navigateToStoryInput = true
                }
            }
        }
        .navigationTitle("Create Project")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    CreateProjectView(
        viewModel: CreateProjectViewModel(),
        flowStore: CreateProjectFlowStore(),
        container: .preview()
    )
    .previewContainer()
}
#endif
