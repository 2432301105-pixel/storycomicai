import SwiftUI

extension View {
    func previewContainer() -> some View {
        let container = AppContainer.preview()
        let sessionStore = AppSessionStore(
            authService: container.authService,
            tokenStore: container.tokenStore,
            configuration: container.configuration
        )
        return self
            .environmentObject(sessionStore)
    }
}
