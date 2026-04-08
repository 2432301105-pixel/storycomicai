import SwiftUI
import UIKit

enum MainTab: Hashable, CaseIterable {
    case home
    case library
    case settings

    var title: String {
        switch self {
        case .home:     return L10n.string("tab.home")
        case .library:  return L10n.string("tab.library")
        case .settings: return L10n.string("tab.settings")
        }
    }

    var systemImage: String {
        switch self {
        case .home:     return "house.fill"
        case .library:  return "books.vertical.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var label: String {
        switch self {
        case .home:     return "HOME"
        case .library:  return "LIBRARY"
        case .settings: return "SETTINGS"
        }
    }
}

struct MainTabView: View {
    let container: AppContainer
    @State private var selectedTab: MainTab = .home

    init(container: AppContainer) {
        self.container = container
        // Hide the system tab bar — we use a custom one
        UITabBar.appearance().isHidden = true
        Self.configureNavigationAppearance()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Page content ──────────────────────────────────────────────────
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView(
                        viewModel: HomeViewModel(projectService: container.projectService),
                        container: container
                    )
                }
                .tag(MainTab.home)

                NavigationStack {
                    LibraryView(
                        viewModel: LibraryViewModel(projectService: container.projectService),
                        container: container
                    )
                }
                .tag(MainTab.library)

                NavigationStack {
                    SettingsView(viewModel: SettingsViewModel())
                }
                .tag(MainTab.settings)
            }

            // ── Custom floating tab bar ───────────────────────────────────────
            InkTabBar(selectedTab: $selectedTab)
        }
        .background(AppColor.inkBlack.ignoresSafeArea())
        .ignoresSafeArea(edges: .bottom)
    }

    private static func configureNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColor.inkBlack)
        appearance.shadowColor = UIColor(AppColor.panelBorder)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(AppColor.textPrimary),
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold)
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(AppColor.comicYellow)
    }
}

// ─── Custom ink tab bar ───────────────────────────────────────────────────────

private struct InkTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                } label: {
                    InkTabItem(tab: tab, isSelected: selectedTab == tab)
                }
                .buttonStyle(InkPressStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            ZStack {
                // Frosted dark panel
                Rectangle()
                    .fill(AppColor.inkDeep)
                // Top border — comic panel edge
                VStack {
                    Rectangle()
                        .fill(AppColor.panelBorderStrong)
                        .frame(height: 1.5)
                    Spacer()
                }
            }
        )
    }
}

private struct InkTabItem: View {
    let tab: MainTab
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColor.comicYellow)
                        .frame(width: 44, height: 28)
                        .transition(.scale.combined(with: .opacity))
                }

                Image(systemName: tab.systemImage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isSelected ? AppColor.textOnLight : AppColor.textTertiary)
                    .frame(width: 44, height: 28)
            }

            Text(tab.label)
                .font(.system(size: 9, weight: .bold, design: .default))
                .tracking(1.2)
                .foregroundStyle(isSelected ? AppColor.comicYellow : AppColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
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
