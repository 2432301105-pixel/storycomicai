import SwiftUI
import UIKit

enum MainTab: Hashable {
    case home
    case library
    case settings
}

struct MainTabView: View {
    let container: AppContainer

    @State private var selectedTab: MainTab = .home

    init(container: AppContainer) {
        self.container = container
        Self.configureTabBarAppearanceIfNeeded()
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(viewModel: HomeViewModel(projectService: container.projectService), container: container)
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(MainTab.home)

            NavigationStack {
                LibraryView(
                    viewModel: LibraryViewModel(projectService: container.projectService),
                    container: container
                )
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
            .tag(MainTab.library)

            NavigationStack {
                SettingsView(viewModel: SettingsViewModel())
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(MainTab.settings)
        }
        .tint(AppColor.accent)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(AppColor.backgroundSecondary, for: .tabBar)
    }

    private static var hasConfiguredTabBarAppearance = false

    private static func configureTabBarAppearanceIfNeeded() {
        guard !hasConfiguredTabBarAppearance else { return }
        hasConfiguredTabBarAppearance = true

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColor.backgroundSecondary)
        appearance.shadowColor = UIColor(AppColor.border).withAlphaComponent(0.25)

        let normalItemColor = UIColor(AppColor.textSecondary)
        let selectedItemColor = UIColor(AppColor.textPrimary)
        appearance.stackedLayoutAppearance.normal.iconColor = normalItemColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalItemColor]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedItemColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedItemColor]

        let proxy = UITabBar.appearance()
        proxy.standardAppearance = appearance
        proxy.scrollEdgeAppearance = appearance
        proxy.isTranslucent = false
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    MainTabView(container: .preview())
        .environmentObject(AppSessionStore(authService: AppContainer.preview().authService, tokenStore: AppContainer.preview().tokenStore))
}
#endif
