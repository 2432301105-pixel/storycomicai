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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
            .tag(MainTab.library)

            NavigationStack {
                SettingsView(viewModel: SettingsViewModel())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(MainTab.settings)
        }
        .tint(AppColor.accent)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(AppColor.tabBarBackground, for: .tabBar)
    }

    private static var hasConfiguredTabBarAppearance = false

    private static func configureTabBarAppearanceIfNeeded() {
        guard !hasConfiguredTabBarAppearance else { return }
        hasConfiguredTabBarAppearance = true

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColor.tabBarBackground)
        appearance.shadowColor = UIColor(AppColor.tabBarBorder)

        let normalItemColor = UIColor(AppColor.textTertiary)
        let selectedItemColor = UIColor(AppColor.accent)
        appearance.stackedLayoutAppearance.normal.iconColor = normalItemColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalItemColor]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedItemColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedItemColor]

        let proxy = UITabBar.appearance()
        proxy.standardAppearance = appearance
        proxy.scrollEdgeAppearance = appearance
        proxy.isTranslucent = false

        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = UIColor(AppColor.backgroundPrimary)
        navigationAppearance.shadowColor = UIColor(AppColor.border.opacity(0.22))
        navigationAppearance.titleTextAttributes = [.foregroundColor: UIColor(AppColor.textPrimary)]
        navigationAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppColor.textPrimary)]

        let navigationProxy = UINavigationBar.appearance()
        navigationProxy.standardAppearance = navigationAppearance
        navigationProxy.scrollEdgeAppearance = navigationAppearance
        navigationProxy.compactAppearance = navigationAppearance
        navigationProxy.tintColor = UIColor(AppColor.textPrimary)
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    MainTabView(container: .preview())
        .environmentObject(AppSessionStore(authService: AppContainer.preview().authService, tokenStore: AppContainer.preview().tokenStore))
}
#endif
