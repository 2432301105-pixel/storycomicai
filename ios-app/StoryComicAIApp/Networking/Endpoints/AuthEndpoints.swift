import Foundation

enum AuthEndpoints {
    static func verifyApple(identityToken: String) throws -> APIEndpoint {
        APIEndpoint(
            path: "/v1/auth/apple/verify",
            method: .post,
            body: try APIEndpoint.encodeBody(AppleVerifyRequestBody(identityToken: identityToken)),
            requiresAuth: false
        )
    }
}
