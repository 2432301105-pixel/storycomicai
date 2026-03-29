import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case transport(underlying: Error)
    case backend(code: String, message: String)
    case server(statusCode: Int, body: String?)
    case decoding(underlying: Error)
    case emptyResponseData
}

extension APIError {
    var userMessage: String {
        switch self {
        case .invalidURL:
            return "Invalid server URL."
        case .invalidResponse:
            return "Server response was invalid."
        case .unauthorized:
            return "Your session is not authorized."
        case let .transport(underlying):
            return "Network error: \(underlying.localizedDescription)"
        case let .backend(_, message):
            return message
        case .server:
            return "Server error occurred. Please try again."
        case .decoding:
            return "Could not process server response."
        case .emptyResponseData:
            return "Server returned empty data."
        }
    }
}
