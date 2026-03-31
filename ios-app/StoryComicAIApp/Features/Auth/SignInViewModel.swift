import Foundation

@MainActor
final class SignInViewModel: ObservableObject {
    @Published var identityTokenInput: String

    private weak var sessionStore: AppSessionStore?
    private let appleClientID: String

    init(
        sessionStore: AppSessionStore,
        initialIdentityToken: String? = nil,
        appleClientID: String? = nil
    ) {
        self.sessionStore = sessionStore
        let resolvedAppleClientID = appleClientID ?? Self.defaultAppleClientID
        self.appleClientID = resolvedAppleClientID
        self.identityTokenInput = Self.normalizedIdentityToken(
            from: initialIdentityToken ?? Self.legacyDevTokenSeed,
            clientID: resolvedAppleClientID
        )
    }

    func signIn() async {
        guard let sessionStore else { return }
        let normalizedToken = Self.normalizedIdentityToken(from: identityTokenInput, clientID: appleClientID)
        identityTokenInput = normalizedToken
        await sessionStore.signInWithApple(identityToken: normalizedToken)
    }
}

extension SignInViewModel {
    nonisolated static let defaultAppleClientID = ProcessInfo.processInfo.environment["STORYCOMICAI_APPLE_CLIENT_ID"] ?? "com.storycomicai.app"
    nonisolated static let appleIssuer = "https://appleid.apple.com"
    nonisolated static let legacyDevTokenSeed = "mock_identity_token_12345678901234567890"

    static func normalizedIdentityToken(from rawValue: String, clientID: String) -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if isJWTLike(trimmed) {
            return trimmed
        }

        let subject = sanitizedSubject(from: trimmed.isEmpty ? legacyDevTokenSeed : trimmed)
        let now = Date()
        let expiration = Int(now.addingTimeInterval(60 * 60 * 24).timeIntervalSince1970)
        let header: [String: Any] = [
            "alg": "HS256",
            "typ": "JWT"
        ]
        let payload: [String: Any] = [
            "sub": subject,
            "aud": clientID,
            "iss": appleIssuer,
            "exp": expiration,
            "email": "\(subject)@storycomicai.local",
            "email_verified": true
        ]

        let headerPart = base64URLString(for: header)
        let payloadPart = base64URLString(for: payload)
        let signaturePart = base64URLString(for: "storycomicai-dev-signature")
        return "\(headerPart).\(payloadPart).\(signaturePart)"
    }

    static func isJWTLike(_ value: String) -> Bool {
        let segments = value.split(separator: ".", omittingEmptySubsequences: false)
        return segments.count == 3 && segments.allSatisfy { !$0.isEmpty }
    }

    static func sanitizedSubject(from seed: String) -> String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._")
        let normalized = String(
            seed.unicodeScalars.map { allowed.contains($0) ? String($0) : "-" }.joined()
        )
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-."))

        return normalized.isEmpty ? "storycomicai-dev-user" : normalized
    }

    static func base64URLString(for dictionary: [String: Any]) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: dictionary, options: [.sortedKeys])) ?? Data()
        return base64URLString(for: data)
    }

    static func base64URLString(for string: String) -> String {
        base64URLString(for: Data(string.utf8))
    }

    static func base64URLString(for data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
