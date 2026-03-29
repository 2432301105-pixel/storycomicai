import Foundation

struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data? = nil
    var requiresAuth: Bool = true

    static func encodeBody<T: Encodable>(_ value: T) throws -> Data {
        try APICoding.encoder.encode(value)
    }
}
