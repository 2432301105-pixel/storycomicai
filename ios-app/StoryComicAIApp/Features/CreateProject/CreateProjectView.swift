import SwiftUI

struct CreateProjectView: View {
    @StateObject var viewModel: CreateProjectViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToStoryInput: Bool = false

    var body: some View {
        FloatingPanelScreen(accent: AppColor.accent) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(L10n.string("create.eyebrow"))
                        .font(AppTypography.eyebrow)
                        .foregroundStyle(AppColor.textTertiary)
                        .tracking(1.4)
                        .textCase(.uppercase)

                    Text(L10n.string("create.title"))
                        .font(AppTypography.title)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(L10n.string("create.subtitle"))
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
            }
        } content: {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text(L10n.string("create.field"))
                    .font(AppTypography.meta)
                    .foregroundStyle(AppColor.textTertiary)
                    .textCase(.uppercase)

                TextField(L10n.string("create.placeholder"), text: $flowStore.projectName)
                    .textFieldStyle(.roundedBorder)

                Text(L10n.string("create.help"))
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

            PrimaryButton(title: L10n.string("action.continue")) {
                if viewModel.validateProjectName(flowStore.projectName) {
                    navigateToStoryInput = true
                }
            }
        }
        .navigationTitle(L10n.string("create.nav"))
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
