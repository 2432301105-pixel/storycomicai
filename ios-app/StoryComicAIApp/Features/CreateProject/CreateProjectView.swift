import SwiftUI

struct CreateProjectView: View {
    @StateObject var viewModel: CreateProjectViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToStoryInput: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            CardContainer {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Project Name")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)

                    TextField("Example: Shadow of Istanbul", text: $flowStore.projectName)
                        .textFieldStyle(.roundedBorder)
                }
            }

            if let validationMessage = viewModel.validationMessage {
                Text(validationMessage)
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColor.warning)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

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

            Spacer()
        }
        .padding(AppSpacing.lg)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
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
