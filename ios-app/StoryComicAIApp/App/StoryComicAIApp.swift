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
                tokenStore: resolvedContainer.tokenStore,
                configuration: resolvedContainer.configuration
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView(container: container)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .environmentObject(sessionStore)
            .preferredColorScheme(.light)
        }
    }
}
