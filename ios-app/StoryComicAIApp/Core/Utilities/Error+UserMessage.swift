import Foundation

extension Error {
    var userFacingMessage: String {
        if let apiError = self as? APIError {
            return apiError.userMessage
        }
        return localizedDescription
    }
}
