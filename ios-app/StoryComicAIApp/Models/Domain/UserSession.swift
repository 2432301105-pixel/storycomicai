import Foundation

struct UserSession: Equatable {
    let userID: UUID
    let accessToken: String
    let tokenType: String
    let expiresInSeconds: Int
    let issuedAtUTC: Date
}
