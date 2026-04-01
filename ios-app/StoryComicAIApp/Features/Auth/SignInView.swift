import SwiftUI

struct SignInView: View {
    @StateObject var viewModel: SignInViewModel
    @EnvironmentObject private var sessionStore: AppSessionStore

    var body: some View {
        FloatingPanelScreen(accent: AppColor.accent) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Personal Comic Studio")
                    .font(AppTypography.eyebrow)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(1.4)
                    .textCase(.uppercase)

                Text("StoryComicAI")
                    .font(AppTypography.display)
                    .foregroundStyle(AppColor.textPrimary)
                    .minimumScaleFactor(0.8)

                Text("Create a premium comic edition where you are the main character, then open it like a finished book.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } content: {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                ComicCoverCard(
                    title: "Your Story,\nBound As A Book",
                    subtitle: "Hero preview, premium reveal and export-ready pages.",
                    accent: AppColor.accent(for: .cinematic),
                    style: .cinematic,
                    eyebrow: "Prestige Edition",
                    badge: "Made For You",
                    emphasize: true
                )
                .frame(maxWidth: 280)
                .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Developer Sign In")
                        .font(AppTypography.section)
                        .foregroundStyle(AppColor.textPrimary)

                    Text("Use a local Apple token handoff to enter the live comic flow.")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)

                    VStack(spacing: AppSpacing.sm) {
                        Text("Apple Identity Token")
                            .font(AppTypography.meta)
                            .foregroundStyle(AppColor.textTertiary)
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField("identity token", text: $viewModel.identityTokenInput, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3)
                    }
                }

                if let authError = sessionStore.authErrorMessage {
                    Text(authError)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.error)
                }
            }
        } footer: {
            PrimaryButton(title: "Enter Studio", isLoading: sessionStore.isSigningIn) {
                Task { await viewModel.signIn() }
            }
        }
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    let container = AppContainer.preview()
    let sessionStore = AppSessionStore(
        authService: container.authService,
        tokenStore: container.tokenStore,
        configuration: container.configuration
    )
    SignInView(
        viewModel: SignInViewModel(
            sessionStore: sessionStore
        )
    )
    .environmentObject(sessionStore)
}
#endif
