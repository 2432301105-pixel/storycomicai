import Foundation

struct APIEnvelope<T: Decodable>: Decodable {
    let requestID: String
    let data: T?
    let error: APIEnvelopeError?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        requestID = try container.decodeIfPresent(String.self, forAnyKey: ["requestId", "request_id"]) ?? UUID().uuidString
        data = try container.decodeIfPresent(T.self, forAnyKey: ["data"])
        error = try container.decodeIfPresent(APIEnvelopeError.self, forAnyKey: ["error"])
    }
}

struct APIEnvelopeError: Decodable {
    let code: String
    let message: String
}

struct EmptyPayload: Codable {}
