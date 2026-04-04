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
            return L10n.string("api.invalid_url")
        case .invalidResponse:
            return L10n.string("api.invalid_response")
        case .unauthorized:
            return L10n.string("api.unauthorized")
        case let .transport(underlying):
            return L10n.string("api.transport", underlying.localizedDescription)
        case let .backend(_, message):
            return message
        case .server:
            return L10n.string("api.server")
        case .decoding:
            return L10n.string("api.decoding")
        case .emptyResponseData:
            return L10n.string("api.empty_response")
        }
    }
}
