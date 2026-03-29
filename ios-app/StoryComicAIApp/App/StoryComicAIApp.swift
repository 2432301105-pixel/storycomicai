import SwiftUI

@main
struct StoryComicAIApp: App {
    private let container: AppContainer
    @StateObject private var sessionStore: AppSessionStore

    init() {
        let resolvedContainer = AppContainer.live()
        self.container = resolvedContainer
        _sessionStore = StateObject(
            wrappedValue: AppSessionStore(
                authService: resolvedContainer.authService,
                tokenStore: resolvedContainer.tokenStore
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                AppColor.backgroundPrimary.ignoresSafeArea()
                AppCoordinatorView(container: container)
            }
            .environmentObject(sessionStore)
            .preferredColorScheme(.light)
        }
    }
}
