import SwiftUI

struct SignInView: View {
    @StateObject var viewModel: SignInViewModel
    @EnvironmentObject private var sessionStore: AppSessionStore

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            VStack(spacing: AppSpacing.sm) {
                Text("StoryComicAI")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Sign in to start creating premium personal comics.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.lg)

            CardContainer {
                VStack(spacing: AppSpacing.sm) {
                    Text("Apple Identity Token (Dev Input)")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("identity token", text: $viewModel.identityTokenInput, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3)
                }
            }
            .padding(.horizontal, AppSpacing.lg)

            if let authError = sessionStore.authErrorMessage {
                Text(authError)
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColor.error)
                    .padding(.horizontal, AppSpacing.lg)
            }

            PrimaryButton(title: "Sign In", isLoading: sessionStore.isSigningIn) {
                Task { await viewModel.signIn() }
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    let container = AppContainer.preview()
    SignInView(
        viewModel: SignInViewModel(
            sessionStore: AppSessionStore(authService: container.authService, tokenStore: container.tokenStore)
        )
    )
    .previewContainer()
}
#endif
