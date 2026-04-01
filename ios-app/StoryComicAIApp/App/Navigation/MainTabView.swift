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
                Label(MainTab.home.title, systemImage: MainTab.home.systemImage)
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
                Label(MainTab.library.title, systemImage: MainTab.library.systemImage)
            }
            .tag(MainTab.library)

            NavigationStack {
                SettingsView(viewModel: SettingsViewModel())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .tabItem {
                Label(MainTab.settings.title, systemImage: MainTab.settings.systemImage)
            }
            .tag(MainTab.settings)
        }
        .tint(AppColor.accent)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }

    private static var hasConfiguredTabBarAppearance = false

    private static func configureTabBarAppearanceIfNeeded() {
        guard !hasConfiguredTabBarAppearance else { return }
        hasConfiguredTabBarAppearance = true

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColor.tabBarBackground)
        appearance.shadowColor = UIColor(AppColor.tabBarBorder)
        appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 0)
        appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 0)

        let normalItemColor = UIColor(AppColor.textTertiary)
        let selectedItemColor = UIColor(AppColor.accent)
        appearance.stackedLayoutAppearance.normal.iconColor = normalItemColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalItemColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedItemColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedItemColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]

        let proxy = UITabBar.appearance()
        proxy.standardAppearance = appearance
        proxy.scrollEdgeAppearance = appearance
        proxy.isTranslucent = false
        proxy.isHidden = false

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
