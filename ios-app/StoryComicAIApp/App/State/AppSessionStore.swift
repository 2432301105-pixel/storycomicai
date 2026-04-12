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

        // When any API call gets a 401 the stored token is stale (backend
        // restarted, user deleted, secret rotated).  Auto-sign-out so the
        // user lands on the sign-in screen instead of being stuck.
        NotificationCenter.default.addObserver(
            forName: .storyComicAISessionUnauthorized,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                await self?.signOut()
            }
        }
    }

    private let defaults: UserDefaults

    func completeOnboarding() {
        hasCompletedOnboarding = true
        defaults.set(true, forKey: onboardingFlagKey)
    }

    // MARK: - Session restore from Keychain

    /// Called on launch. Reads a persisted JWT from the Keychain, validates
    /// its expiry (without signature verification) and, if valid, restores the
    /// session so the user does not have to sign in again.
    func restoreSessionIfNeeded() async {
        guard userSession == nil else { return }
        guard let token = await tokenStore.readToken() else { return }

        guard let restored = UserSession(restoringFrom: token) else {
            // Token expired or malformed — clear it so the sign-in screen appears.
            await tokenStore.writeToken(nil)
            return
        }
        userSession = restored
    }

    // MARK: - Sign-in

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

    // MARK: - Dev bootstrap (DEBUG direct-launch only)

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

// MARK: - JWT payload decode (no signature verification)

private extension UserSession {
    /// Reconstructs a UserSession from a stored JWT without verifying the
    /// signature — we only need to check expiry and extract the user ID.
    init?(restoringFrom token: String) {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }

        // Pad the base64url payload segment before decoding.
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder != 0 { base64 += String(repeating: "=", count: 4 - remainder) }

        guard let data = Data(base64Encoded: base64),
              let payload = try? JSONDecoder().decode(JWTMinimalPayload.self, from: data) else {
            return nil
        }

        let expDate = Date(timeIntervalSince1970: TimeInterval(payload.exp))
        // Require at least 5 minutes remaining before we consider the token valid.
        guard expDate > Date().addingTimeInterval(300) else { return nil }

        guard let userID = UUID(uuidString: payload.sub) else { return nil }

        self.init(
            userID: userID,
            accessToken: token,
            tokenType: "bearer",
            expiresInSeconds: max(0, Int(expDate.timeIntervalSinceNow)),
            issuedAtUTC: Date()
        )
    }

    private struct JWTMinimalPayload: Codable {
        let sub: String
        let exp: Int
    }
}
