import SwiftUI

struct AppCoordinatorView: View {
    let container: AppContainer
    @EnvironmentObject private var sessionStore: AppSessionStore

    var body: some View {
        Group {
            if !sessionStore.hasCompletedOnboarding {
                OnboardingView(viewModel: OnboardingViewModel()) {
                    sessionStore.completeOnboarding()
                }
            } else if !sessionStore.isAuthenticated {
                SignInView(viewModel: SignInViewModel(sessionStore: sessionStore))
            } else {
                MainTabView(container: container)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.25), value: sessionStore.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.25), value: sessionStore.isAuthenticated)
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    let container = AppContainer.preview()
    let store = AppSessionStore(authService: container.authService, tokenStore: container.tokenStore)
    AppCoordinatorView(container: container)
        .environmentObject(store)
}
#endif
