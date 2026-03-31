import XCTest
@testable import StoryComicAIApp

final class SignInViewModelTests: XCTestCase {
    func testNormalizedIdentityTokenBuildsJWTFromLegacySeed() throws {
        let token = SignInViewModel.normalizedIdentityToken(
            from: "mock_identity_token_12345678901234567890",
            clientID: "com.storycomicai.app"
        )

        XCTAssertTrue(SignInViewModel.isJWTLike(token))

        let payload = try XCTUnwrap(decodePayload(from: token))
        XCTAssertEqual(payload["aud"] as? String, "com.storycomicai.app")
        XCTAssertEqual(payload["iss"] as? String, SignInViewModel.appleIssuer)
        XCTAssertEqual(payload["sub"] as? String, "mock_identity_token_12345678901234567890")
        XCTAssertNotNil(payload["exp"] as? Int)
    }

    func testNormalizedIdentityTokenPreservesJWTInput() {
        let rawToken = "header.payload.signature"

        let token = SignInViewModel.normalizedIdentityToken(
            from: rawToken,
            clientID: "com.storycomicai.app"
        )

        XCTAssertEqual(token, rawToken)
    }

    private func decodePayload(from token: String) -> [String: Any]? {
        let segments = token.split(separator: ".")
        guard segments.count == 3 else { return nil }

        var payload = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let paddingCount = (4 - (payload.count % 4)) % 4
        payload.append(String(repeating: "=", count: paddingCount))

        guard
            let data = Data(base64Encoded: payload),
            let object = try? JSONSerialization.jsonObject(with: data),
            let dictionary = object as? [String: Any]
        else {
            return nil
        }

        return dictionary
    }
}
