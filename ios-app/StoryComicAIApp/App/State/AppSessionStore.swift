import Foundation

@MainActor
final class AppSessionStore: ObservableObject {
    @Published private(set) var hasCompletedOnboarding: Bool
    @Published private(set) var userSession: UserSession?
    @Published private(set) var isSigningIn: Bool = false
    @Published private(set) var authErrorMessage: String?

    var isAuthenticated: Bool {
        userSession != nil
    }

    private let authService: any AuthService
    private let tokenStore: AccessTokenStore
    private let onboardingFlagKey = "storycomicai.onboarding.completed"

    init(authService: any AuthService, tokenStore: AccessTokenStore, defaults: UserDefaults = .standard) {
        self.authService = authService
        self.tokenStore = tokenStore
        self.hasCompletedOnboarding = defaults.bool(forKey: onboardingFlagKey)
        self.defaults = defaults
    }

    private let defaults: UserDefaults

    func completeOnboarding() {
        hasCompletedOnboarding = true
        defaults.set(true, forKey: onboardingFlagKey)
    }

    func signInWithApple(identityToken: String) async {
        isSigningIn = true
        authErrorMessage = nil
        defer { isSigningIn = false }

        do {
            let session = try await authService.verifyApple(identityToken: identityToken)
            userSession = session
            await tokenStore.writeToken(session.accessToken)
        } catch {
            authErrorMessage = error.userFacingMessage
        }
    }

    func signOut() async {
        userSession = nil
        authErrorMessage = nil
        await tokenStore.writeToken(nil)
    }
}
