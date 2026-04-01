import Foundation

struct AppConfiguration {
    let apiBaseURL: URL
    let useMockServices: Bool
    let heroPreviewPollingIntervalSeconds: UInt64
    let launchesDirectlyIntoApp: Bool
    let launchIdentityTokenSeed: String
    let appleClientID: String

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
        #if DEBUG
        let defaultDirectLaunch = true
        #else
        let defaultDirectLaunch = false
        #endif
        let directLaunch = environment["STORYCOMICAI_SKIP_ENTRY_FLOW"].flatMap { Bool($0) } ?? defaultDirectLaunch
        let appleClientID = environment["STORYCOMICAI_APPLE_CLIENT_ID"] ?? "com.storycomicai.app"
        let launchIdentityTokenSeed = environment["STORYCOMICAI_LAUNCH_IDENTITY_TOKEN"] ?? "storycomicai-launch-user"

        return AppConfiguration(
            apiBaseURL: resolvedURL,
            useMockServices: mockFlag,
            heroPreviewPollingIntervalSeconds: 2,
            launchesDirectlyIntoApp: directLaunch,
            launchIdentityTokenSeed: launchIdentityTokenSeed,
            appleClientID: appleClientID
        )
    }
}
