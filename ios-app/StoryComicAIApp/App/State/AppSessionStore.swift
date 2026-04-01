import Foundation

@MainActor
final class AppSessionStore: ObservableObject {
    @Published private(set) var hasCompletedOnboarding: Bool
    @Published private(set) var userSession: UserSession?
    @Published private(set) var isSigningIn: Bool = false
    @Published private(set) var isBootstrappingLaunchSession: Bool = false
    @Published private(set) var authErrorMessage: String?

    var isAuthenticated: Bool {
        userSession != nil
    }

    var shouldBypassEntryFlow: Bool {
        configuration.launchesDirectlyIntoApp
    }

    private let authService: any AuthService
    private let tokenStore: AccessTokenStore
    private let configuration: AppConfiguration
    private let onboardingFlagKey = "storycomicai.onboarding.completed"

    init(
        authService: any AuthService,
        tokenStore: AccessTokenStore,
        configuration: AppConfiguration,
        defaults: UserDefaults = .standard
    ) {
        self.authService = authService
        self.tokenStore = tokenStore
        self.configuration = configuration
        let hasCompletedStoredOnboarding = defaults.bool(forKey: onboardingFlagKey)
        self.hasCompletedOnboarding = configuration.launchesDirectlyIntoApp ? true : hasCompletedStoredOnboarding
        self.defaults = defaults

        if configuration.launchesDirectlyIntoApp {
            defaults.set(true, forKey: onboardingFlagKey)
        }
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

    func bootstrapLaunchSessionIfNeeded() async {
        guard configuration.launchesDirectlyIntoApp else { return }
        guard userSession == nil else { return }
        guard !isBootstrappingLaunchSession else { return }

        isBootstrappingLaunchSession = true
        defer { isBootstrappingLaunchSession = false }

        let normalizedToken = SignInViewModel.normalizedIdentityToken(
            from: configuration.launchIdentityTokenSeed,
            clientID: configuration.appleClientID
        )

        do {
            let session = try await authService.verifyApple(identityToken: normalizedToken)
            userSession = session
            authErrorMessage = nil
            await tokenStore.writeToken(session.accessToken)
        } catch {
            authErrorMessage = nil
        }
    }
}
