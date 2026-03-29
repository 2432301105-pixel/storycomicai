import Foundation

protocol APIClient: AnyObject {
    func request<T: Decodable>(_ endpoint: APIEndpoint, decode: T.Type) async throws -> T
}

extension APIClient {
    func request<T: Decodable>(_ endpoint: APIEndpoint, decode: T.Type = T.self) async throws -> T {
        try await request(endpoint, decode: decode)
    }
}
