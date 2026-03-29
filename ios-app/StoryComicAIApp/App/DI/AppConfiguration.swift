import Foundation

struct AppConfiguration {
    let apiBaseURL: URL
    let useMockServices: Bool
    let heroPreviewPollingIntervalSeconds: UInt64

    static func resolve(processInfo: ProcessInfo = .processInfo) -> AppConfiguration {
        let environment = processInfo.environment
        let urlString = environment["STORYCOMICAI_API_BASE_URL"] ?? "http://localhost:8000"
        let resolvedURL = URL(string: urlString) ?? URL(string: "http://localhost:8000")!

        #if DEBUG
        let defaultMockFlag = true
        #else
        let defaultMockFlag = false
        #endif

        let mockFlag = environment["STORYCOMICAI_USE_MOCK_SERVICES"].flatMap { Bool($0) } ?? defaultMockFlag

        return AppConfiguration(
            apiBaseURL: resolvedURL,
            useMockServices: mockFlag,
            heroPreviewPollingIntervalSeconds: 2
        )
    }
}
