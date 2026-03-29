import Foundation

protocol AccessTokenStore: AnyObject {
    func readToken() async -> String?
    func writeToken(_ token: String?) async
}

actor InMemoryAccessTokenStore: AccessTokenStore {
    private var token: String?

    func readToken() async -> String? {
        token
    }

    func writeToken(_ token: String?) async {
        self.token = token
    }
}
