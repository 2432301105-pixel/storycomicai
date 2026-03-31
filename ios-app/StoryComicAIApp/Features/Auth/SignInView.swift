import SwiftUI

struct SignInView: View {
    @StateObject var viewModel: SignInViewModel
    @EnvironmentObject private var sessionStore: AppSessionStore

    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.accent, showsDeskBand: false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
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

                    ComicCoverCard(
                        title: "Your Story,\nBound As A Book",
                        subtitle: "Hero preview, premium reveal and export-ready pages.",
                        accent: AppColor.accent(for: .cinematic),
                        eyebrow: "Prestige Edition",
                        badge: "Made For You",
                        emphasize: true
                    )

                    CardContainer(emphasize: true) {
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let authError = sessionStore.authErrorMessage {
                        Text(authError)
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.error)
                    }

                    PrimaryButton(title: "Enter Studio", isLoading: sessionStore.isSigningIn) {
                        Task { await viewModel.signIn() }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xxl)
                .padding(.bottom, AppSpacing.section)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
