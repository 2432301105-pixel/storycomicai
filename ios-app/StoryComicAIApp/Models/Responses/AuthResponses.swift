import Foundation

struct AuthTokenResponseDTO: Codable {
    let userID: UUID
    let accessToken: String
    let tokenType: String
    let expiresInSeconds: Int
    let issuedAtUTC: Date

    enum CodingKeys: String, CodingKey {
        case userID = "userId"
        case accessToken
        case tokenType
        case expiresInSeconds
        case issuedAtUTC = "issuedAtUtc"
    }
}
