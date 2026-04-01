import SwiftUI

struct AppCoordinatorView: View {
    let container: AppContainer
    @EnvironmentObject private var sessionStore: AppSessionStore

    var body: some View {
        ZStack {
            AppColor.backgroundPrimary.ignoresSafeArea()

            Group {
                if sessionStore.shouldBypassEntryFlow {
                    if sessionStore.isBootstrappingLaunchSession && !sessionStore.isAuthenticated {
                        LaunchBootView()
                    } else {
                        MainTabView(container: container)
                    }
                } else if !sessionStore.hasCompletedOnboarding {
                    OnboardingView(viewModel: OnboardingViewModel()) {
                        sessionStore.completeOnboarding()
                    }
                } else if !sessionStore.isAuthenticated {
                    SignInView(viewModel: SignInViewModel(sessionStore: sessionStore))
                } else {
                    MainTabView(container: container)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await sessionStore.bootstrapLaunchSessionIfNeeded()
        }
        .animation(.easeInOut(duration: 0.25), value: sessionStore.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.25), value: sessionStore.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: sessionStore.isBootstrappingLaunchSession)
    }
}

private struct LaunchBootView: View {
    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.accent, showsDeskBand: false)

            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("StoryComicAI")
                    .font(AppTypography.eyebrow)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(1.4)
                    .textCase(.uppercase)

                Text("Opening your comic studio")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Preparing your library and loading the latest edition.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)

                LoadingStateView(title: "Loading your library", subtitle: "Connecting the comic studio")
            }
            .frame(maxWidth: 640)
            .padding(.horizontal, AppSpacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    let container = AppContainer.preview()
    let store = AppSessionStore(
        authService: container.authService,
        tokenStore: container.tokenStore,
        configuration: container.configuration
    )
    AppCoordinatorView(container: container)
        .environmentObject(store)
}
#endif
