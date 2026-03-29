import Foundation

@MainActor
final class SignInViewModel: ObservableObject {
    @Published var identityTokenInput: String = "mock_identity_token_12345678901234567890"

    private weak var sessionStore: AppSessionStore?

    init(sessionStore: AppSessionStore) {
        self.sessionStore = sessionStore
    }

    func signIn() async {
        guard let sessionStore else { return }
        await sessionStore.signInWithApple(identityToken: identityTokenInput)
    }
}
