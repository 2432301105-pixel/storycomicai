import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @EnvironmentObject private var sessionStore: AppSessionStore

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            CardContainer {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Session")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(sessionStore.isAuthenticated ? "Signed In" : "Signed Out")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(title: "Sign Out", isLoading: viewModel.isSigningOut) {
                viewModel.signOut(using: sessionStore)
            }

            Spacer()
        }
        .padding(AppSpacing.lg)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Settings")
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    SettingsView(viewModel: SettingsViewModel())
        .previewContainer()
}
#endif
