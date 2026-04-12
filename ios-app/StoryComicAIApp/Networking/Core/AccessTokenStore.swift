import Foundation
import Security

protocol AccessTokenStore: AnyObject {
    func readToken() async -> String?
    func writeToken(_ token: String?) async
}

// MARK: - Keychain-backed store (default for all builds)

actor KeychainAccessTokenStore: AccessTokenStore {
    private let service = "com.storycomicai.app"
    private let account = "access_token"

    func readToken() async -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func writeToken(_ token: String?) async {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        guard let token else {
            SecItemDelete(query as CFDictionary)
            return
        }
        let data = Data(token.utf8)
        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }
}

// MARK: - In-memory store (for unit tests / previews only)

actor InMemoryAccessTokenStore: AccessTokenStore {
    private var token: String?

    func readToken() async -> String? { token }
    func writeToken(_ token: String?) async { self.token = token }
}
