import Foundation

protocol UploadTransferClient: AnyObject {
    func upload(data: Data, to destinationURL: URL, mimeType: String) async throws
}

final class LiveUploadTransferClient: UploadTransferClient {
    func upload(data: Data, to destinationURL: URL, mimeType: String) async throws {
        var request = URLRequest(url: destinationURL)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1, body: nil)
        }
    }
}

final class MockUploadTransferClient: UploadTransferClient {
    func upload(data: Data, to destinationURL: URL, mimeType: String) async throws {
        _ = (data, destinationURL, mimeType)
        try await Task.sleep(nanoseconds: 300_000_000)
    }
}
