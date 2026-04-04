import SwiftUI

struct SignInView: View {
    @StateObject var viewModel: SignInViewModel
    @EnvironmentObject private var sessionStore: AppSessionStore

    var body: some View {
        FloatingPanelScreen(accent: AppColor.accent) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(L10n.string("signin.eyebrow"))
                    .font(AppTypography.eyebrow)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(1.4)
                    .textCase(.uppercase)

                Text(L10n.string("signin.title"))
                    .font(AppTypography.display)
                    .foregroundStyle(AppColor.textPrimary)
                    .minimumScaleFactor(0.8)

                Text(L10n.string("signin.subtitle"))
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } content: {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                ComicCoverCard(
                    title: L10n.string("signin.cover_title"),
                    subtitle: L10n.string("signin.cover_subtitle"),
                    accent: AppColor.accent(for: .cinematic),
                    style: .cinematic,
                    eyebrow: L10n.string("signin.cover_eyebrow"),
                    badge: L10n.string("signin.cover_badge"),
                    emphasize: true
                )
                .frame(maxWidth: 280)
                .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text(L10n.string("signin.section_title"))
                        .font(AppTypography.section)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(L10n.string("signin.section_subtitle"))
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)

                    VStack(spacing: AppSpacing.sm) {
                        Text(L10n.string("signin.token_label"))
                            .font(AppTypography.meta)
                            .foregroundStyle(AppColor.textTertiary)
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField(L10n.string("signin.token_placeholder"), text: $viewModel.identityTokenInput, axis: .vertical)
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
            PrimaryButton(title: L10n.string("action.enter_studio"), isLoading: sessionStore.isSigningIn) {
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
