import Foundation

protocol AuthService: AnyObject {
    func verifyApple(identityToken: String) async throws -> UserSession
}

final class DefaultAuthService: AuthService {
    private let apiClient: any APIClient

    init(apiClient: any APIClient) {
        self.apiClient = apiClient
    }

    func verifyApple(identityToken: String) async throws -> UserSession {
        let endpoint = try AuthEndpoints.verifyApple(identityToken: identityToken)
        let dto = try await apiClient.request(endpoint, decode: AuthTokenResponseDTO.self)
        return UserSession(
            userID: dto.userID,
            accessToken: dto.accessToken,
            tokenType: dto.tokenType,
            expiresInSeconds: dto.expiresInSeconds,
            issuedAtUTC: dto.issuedAtUTC
        )
    }
}
