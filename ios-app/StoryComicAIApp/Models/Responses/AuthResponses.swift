import Foundation

struct AuthTokenResponseDTO: Codable {
    let userID: UUID
    let accessToken: String
    let tokenType: String
    let expiresInSeconds: Int
    let issuedAtUTC: Date

    init(
        userID: UUID,
        accessToken: String,
        tokenType: String,
        expiresInSeconds: Int,
        issuedAtUTC: Date
    ) {
        self.userID = userID
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.expiresInSeconds = expiresInSeconds
        self.issuedAtUTC = issuedAtUTC
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        userID = try container.decode(UUID.self, forAnyKey: ["userId", "user_id"])
        accessToken = try container.decode(String.self, forAnyKey: ["accessToken", "access_token"])
        tokenType = try container.decodeIfPresent(String.self, forAnyKey: ["tokenType", "token_type"]) ?? "bearer"
        expiresInSeconds = try container.decode(Int.self, forAnyKey: ["expiresInSeconds", "expires_in_seconds"])
        issuedAtUTC = try container.decode(Date.self, forAnyKey: ["issuedAtUtc", "issued_at_utc"])
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        try container.encode(userID, forKey: AnyCodingKey("userId"))
        try container.encode(accessToken, forKey: AnyCodingKey("accessToken"))
        try container.encode(tokenType, forKey: AnyCodingKey("tokenType"))
        try container.encode(expiresInSeconds, forKey: AnyCodingKey("expiresInSeconds"))
        try container.encode(issuedAtUTC, forKey: AnyCodingKey("issuedAtUtc"))
    }
}
