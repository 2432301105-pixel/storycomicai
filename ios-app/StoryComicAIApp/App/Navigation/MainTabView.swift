import SwiftUI
import UIKit

enum MainTab: Hashable, CaseIterable {
    case home
    case library
    case settings

    var title: String {
        switch self {
        case .home: return "Home"
        case .library: return "Library"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .library: return "books.vertical"
        case .settings: return "gearshape"
        }
    }
}

struct MainTabView: View {
    let container: AppContainer

    @State private var selectedTab: MainTab = .home

    init(container: AppContainer) {
        self.container = container
        Self.configureAppearanceIfNeeded()
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(
                    viewModel: HomeViewModel(projectService: container.projectService),
                    container: container
                )
            }
            .tabItem {
                Label(MainTab.home.title, systemImage: MainTab.home.systemImage)
            }
            .tag(MainTab.home)

            NavigationStack {
                LibraryView(
                    viewModel: LibraryViewModel(projectService: container.projectService),
                    container: container
                )
            }
            .tabItem {
                Label(MainTab.library.title, systemImage: MainTab.library.systemImage)
            }
            .tag(MainTab.library)

            NavigationStack {
                SettingsView(viewModel: SettingsViewModel())
            }
            .tabItem {
                Label(MainTab.settings.title, systemImage: MainTab.settings.systemImage)
            }
            .tag(MainTab.settings)
        }
        .tint(AppColor.textPrimary)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }

    private static var hasConfiguredAppearance = false

    private static func configureAppearanceIfNeeded() {
        guard !hasConfiguredAppearance else { return }
        hasConfiguredAppearance = true

        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = UIColor(AppColor.backgroundPrimary)
        navigationAppearance.shadowColor = UIColor(AppColor.border.opacity(0.16))
        navigationAppearance.titleTextAttributes = [.foregroundColor: UIColor(AppColor.textPrimary)]
        navigationAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppColor.textPrimary)]

        let navigationProxy = UINavigationBar.appearance()
        navigationProxy.standardAppearance = navigationAppearance
        navigationProxy.scrollEdgeAppearance = navigationAppearance
        navigationProxy.compactAppearance = navigationAppearance
        navigationProxy.tintColor = UIColor(AppColor.textPrimary)

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(AppColor.tabBarBackground)
        tabAppearance.shadowColor = UIColor(AppColor.tabBarBorder)

        let itemAppearance = tabAppearance.stackedLayoutAppearance
        itemAppearance.normal.iconColor = UIColor(AppColor.textTertiary)
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(AppColor.textTertiary)]
        itemAppearance.selected.iconColor = UIColor(AppColor.textPrimary)
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(AppColor.textPrimary)]

        let tabProxy = UITabBar.appearance()
        tabProxy.standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            tabProxy.scrollEdgeAppearance = tabAppearance
        }
        tabProxy.tintColor = UIColor(AppColor.textPrimary)
        tabProxy.unselectedItemTintColor = UIColor(AppColor.textTertiary)
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    let container = AppContainer.preview()
    MainTabView(container: container)
        .environmentObject(
            AppSessionStore(
                authService: container.authService,
                tokenStore: container.tokenStore,
                configuration: container.configuration
            )
        )
}
#endif
