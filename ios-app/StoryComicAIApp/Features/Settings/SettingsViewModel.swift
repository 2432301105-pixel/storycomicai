import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isSigningOut: Bool = false

    func signOut(using sessionStore: AppSessionStore) {
        isSigningOut = true
        Task {
            await sessionStore.signOut()
            isSigningOut = false
        }
    }
}
