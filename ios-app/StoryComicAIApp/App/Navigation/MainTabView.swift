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
    @State private var homeDepth: Int = 1
    @State private var libraryDepth: Int = 1
    @State private var settingsDepth: Int = 1

    init(container: AppContainer) {
        self.container = container
        Self.configureNavigationAppearanceIfNeeded()
    }

    var body: some View {
        ZStack {
            tabNavigationLayer(.home)
            tabNavigationLayer(.library)
            tabNavigationLayer(.settings)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }

    private func tabNavigationLayer(_ tab: MainTab) -> some View {
        NavigationStack {
            rootView(for: tab)
                .background(
                    NavigationDepthReader { depth in
                        updateDepth(depth, for: tab)
                    }
                )
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if selectedTab == tab && depth(for: tab) <= 1 {
                        PremiumTabBar(selectedTab: selectedTab) { nextTab in
                            selectedTab = nextTab
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, 10)
                    }
                }
                .background(AppColor.backgroundPrimary.ignoresSafeArea())
        }
        .opacity(selectedTab == tab ? 1 : 0)
        .allowsHitTesting(selectedTab == tab)
        .zIndex(selectedTab == tab ? 1 : 0)
    }

    @ViewBuilder
    private func rootView(for tab: MainTab) -> some View {
        switch tab {
        case .home:
            HomeView(viewModel: HomeViewModel(projectService: container.projectService), container: container)
        case .library:
            LibraryView(
                viewModel: LibraryViewModel(projectService: container.projectService),
                container: container
            )
        case .settings:
            SettingsView(viewModel: SettingsViewModel())
        }
    }

    private static var hasConfiguredNavigationAppearance = false

    private static func configureNavigationAppearanceIfNeeded() {
        guard !hasConfiguredNavigationAppearance else { return }
        hasConfiguredNavigationAppearance = true

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

    private func depth(for tab: MainTab) -> Int {
        switch tab {
        case .home:
            return homeDepth
        case .library:
            return libraryDepth
        case .settings:
            return settingsDepth
        }
    }

    private func updateDepth(_ depth: Int, for tab: MainTab) {
        let resolvedDepth = max(depth, 1)
        switch tab {
        case .home:
            homeDepth = resolvedDepth
        case .library:
            libraryDepth = resolvedDepth
        case .settings:
            settingsDepth = resolvedDepth
        }
    }
}

private struct NavigationDepthReader: UIViewControllerRepresentable {
    let onChange: (Int) -> Void

    func makeUIViewController(context: Context) -> NavigationDepthProbeController {
        let controller = NavigationDepthProbeController()
        controller.onChange = onChange
        return controller
    }

    func updateUIViewController(_ uiViewController: NavigationDepthProbeController, context: Context) {
        uiViewController.onChange = onChange
        uiViewController.reportDepth()
    }
}

final class NavigationDepthProbeController: UIViewController {
    var onChange: ((Int) -> Void)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reportDepth()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reportDepth()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        reportDepth()
    }

    func reportDepth() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let depth = self.navigationController?.viewControllers.count ?? 1
            self.onChange?(depth)
        }
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
