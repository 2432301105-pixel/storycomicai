import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @EnvironmentObject private var sessionStore: AppSessionStore

    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.accent, showsDeskBand: false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(L10n.string("settings.title"))
                            .font(AppTypography.title)
                            .foregroundStyle(AppColor.textPrimary)
                        Text(L10n.string("settings.subtitle"))
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    CardContainer(emphasize: true) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text(L10n.string("settings.session"))
                                .font(AppTypography.meta)
                                .foregroundStyle(AppColor.textTertiary)
                                .textCase(.uppercase)
                            Text(sessionStore.isAuthenticated ? L10n.string("settings.signed_in") : L10n.string("settings.signed_out"))
                                .font(AppTypography.section)
                                .foregroundStyle(AppColor.textPrimary)
                            Text(L10n.string("settings.ready"))
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PrimaryButton(title: L10n.string("action.sign_out"), isLoading: viewModel.isSigningOut) {
                        viewModel.signOut(using: sessionStore)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, AppSpacing.section)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(L10n.string("settings.nav"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel())
    }
    .previewContainer()
}
#endif
