import SwiftUI

struct AppCoordinatorView: View {
    let container: AppContainer
    @EnvironmentObject private var sessionStore: AppSessionStore

    private var showsCompactCoverGallery: Bool {
        ProcessInfo.processInfo.environment["STORYCOMICAI_SHOW_COVER_GALLERY"] == "1"
    }

    private var singleCompactCoverVariant: CompactCoverVariant? {
        guard let value = ProcessInfo.processInfo.environment["STORYCOMICAI_SHOW_COVER_VARIANT"] else {
            return nil
        }

        return CompactCoverVariant(rawValue: value)
    }

    var body: some View {
        ZStack {
            AppColor.backgroundPrimary.ignoresSafeArea()

            Group {
                if let singleCompactCoverVariant {
                    SingleCompactCoverPreviewView(variant: singleCompactCoverVariant)
                } else if showsCompactCoverGallery {
                    CompactCoverGalleryView()
                } else if sessionStore.isBootstrappingLaunchSession {
                    // Bootstrap in progress — show loading screen regardless of
                    // whether the bypass flag is set.
                    LaunchBootView()
                } else if !sessionStore.hasCompletedOnboarding {
                    OnboardingView(viewModel: OnboardingViewModel()) {
                        sessionStore.completeOnboarding()
                    }
                } else if !sessionStore.isAuthenticated {
                    SignInView(viewModel: SignInViewModel(sessionStore: sessionStore))
                } else {
                    MainTabView(container: container)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            // Always try to restore a persisted token first so the user
            // does not have to sign in again after an app restart.
            await sessionStore.restoreSessionIfNeeded()
            // Dev-only: bootstrap a fake session for direct-launch builds
            // if no persisted session was found.
            await sessionStore.bootstrapLaunchSessionIfNeeded()
        }
        .animation(.easeInOut(duration: 0.25), value: sessionStore.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.25), value: sessionStore.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: sessionStore.isBootstrappingLaunchSession)
    }
}

private struct LaunchBootView: View {
    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.accent, showsDeskBand: false)

            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("StoryComicAI")
                    .font(AppTypography.eyebrow)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(1.4)
                    .textCase(.uppercase)

                Text("Opening your comic studio")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Preparing your library and loading the latest edition.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)

                LoadingStateView(title: "Loading your library", subtitle: "Connecting the comic studio")
            }
            .frame(maxWidth: 640)
            .padding(.horizontal, AppSpacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    let container = AppContainer.preview()
    let store = AppSessionStore(
        authService: container.authService,
        tokenStore: container.tokenStore,
        configuration: container.configuration
    )
    AppCoordinatorView(container: container)
        .environmentObject(store)
}
#endif
