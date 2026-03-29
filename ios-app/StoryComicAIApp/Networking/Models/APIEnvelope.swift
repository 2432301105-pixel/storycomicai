import Foundation

struct APIEnvelope<T: Decodable>: Decodable {
    let requestID: String
    let data: T?
    let error: APIEnvelopeError?

    enum CodingKeys: String, CodingKey {
        case requestID = "requestId"
        case data
        case error
    }
}

struct APIEnvelopeError: Decodable {
    let code: String
    let message: String
}

struct EmptyPayload: Codable {}
