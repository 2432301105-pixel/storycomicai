import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @EnvironmentObject private var sessionStore: AppSessionStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Settings")
                        .font(AppTypography.title)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Account and product preferences for your comic studio.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                }

                CardContainer {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Session")
                            .font(AppTypography.meta)
                            .foregroundStyle(AppColor.textTertiary)
                            .textCase(.uppercase)
                        Text(sessionStore.isAuthenticated ? "Signed In" : "Signed Out")
                            .font(AppTypography.section)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryButton(title: "Sign Out", isLoading: viewModel.isSigningOut) {
                    viewModel.signOut(using: sessionStore)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.xl)
            .padding(.bottom, AppSpacing.section)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Settings")
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
