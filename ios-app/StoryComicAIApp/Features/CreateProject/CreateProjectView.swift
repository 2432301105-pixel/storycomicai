import SwiftUI

struct CreateProjectView: View {
    @StateObject var viewModel: CreateProjectViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToStoryInput: Bool = false

    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.accent, showsDeskBand: false)

            VStack(alignment: .leading, spacing: AppSpacing.xl) {
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

                CardContainer(emphasize: true) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Project Name")
                            .font(AppTypography.meta)
                            .foregroundStyle(AppColor.textTertiary)
                            .textCase(.uppercase)

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
