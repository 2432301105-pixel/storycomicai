import Foundation

final class LiveAPIClient: APIClient {
    private let environment: APIEnvironment
    private let tokenStore: AccessTokenStore
    private let urlSession: URLSession

    init(
        environment: APIEnvironment,
        tokenStore: AccessTokenStore,
        urlSession: URLSession = .shared
    ) {
        self.environment = environment
        self.tokenStore = tokenStore
        self.urlSession = urlSession
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint, decode: T.Type) async throws -> T {
        let accessToken = await tokenStore.readToken()
        let request = try URLRequestBuilder(environment: environment).makeRequest(
            from: endpoint,
            accessToken: accessToken
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            throw APIError.transport(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            NotificationCenter.default.post(name: .storyComicAISessionUnauthorized, object: nil)
            throw APIError.unauthorized
        }

        let envelope: APIEnvelope<T>
        do {
            envelope = try APICoding.decoder.decode(APIEnvelope<T>.self, from: data)
        } catch {
            if !(200...299).contains(httpResponse.statusCode) {
                throw APIError.server(
                    statusCode: httpResponse.statusCode,
                    body: String(data: data, encoding: .utf8)
                )
            }
            throw APIError.decoding(underlying: error)
        }

        if let backendError = envelope.error {
            throw APIError.backend(code: backendError.code, message: backendError.message)
        }

        guard let payload = envelope.data else {
            throw APIError.emptyResponseData
        }

        return payload
    }
}
