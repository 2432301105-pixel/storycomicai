import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    let container: AppContainer
    @State private var navigateToCreateProject: Bool = false

    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.accent, showsDeskBand: false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    header
                    heroCreateCard
                    recentProjectsSection
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, AppSpacing.section)
            }
        }
        .navigationDestination(isPresented: $navigateToCreateProject) {
            CreateProjectView(
                viewModel: CreateProjectViewModel(),
                flowStore: CreateProjectFlowStore(),
                container: container
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadRecentProjects() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("StoryComicAI")
                .font(AppTypography.eyebrow)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(1.4)
                .textCase(.uppercase)

            Text("Your Comic Library,\nPrinted For One")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)

            Text("Build a premium comic edition where you are the main character, then reveal it like a finished collectible book.")
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var heroCreateCard: some View {
        Button {
            navigateToCreateProject = true
        } label: {
            ZStack(alignment: .bottomLeading) {
                ComicCoverCard(
                    title: "Create A New\nPersonal Edition",
                    subtitle: "Upload photos, shape the story and reveal the final comic book.",
                    accent: AppColor.accent(for: .cinematic),
                    eyebrow: "Studio Launch",
                    badge: "Start Here",
                    emphasize: true
                )

                HStack {
                    Text("Create your comic")
                        .font(AppTypography.button)
                        .foregroundStyle(AppColor.textOnDark)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColor.textOnDark)
                }
                .padding(AppSpacing.lg)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var recentProjectsSection: some View {
        switch viewModel.recentProjectsState {
        case .idle, .loading:
            LoadingStateView(title: "Loading your collection", subtitle: "Gathering recent editions")
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: AppElevation.Surface.radius, style: .continuous))

        case let .failed(message):
            ErrorStateView(title: "Could not load collection", message: message) {
                Task { await viewModel.loadRecentProjects() }
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: AppElevation.Surface.radius, style: .continuous))

        case let .loaded(projects):
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Recent Editions")
                        .font(AppTypography.heading)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Return to the books already on your desk.")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                }

                if projects.isEmpty {
                    CardContainer {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Your shelf is empty")
                                .font(AppTypography.section)
                                .foregroundStyle(AppColor.textPrimary)
                            Text("Create your first personalized comic and it will appear here as a finished edition.")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    VStack(spacing: AppSpacing.md) {
                        ForEach(projects.prefix(3)) { project in
                            NavigationLink {
                                ProjectDetailView(
                                    viewModel: ProjectDetailViewModel(project: project),
                                    container: container
                                )
                            } label: {
                                HomeProjectCard(project: project)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

private struct HomeProjectCard: View {
    let project: Project

    var body: some View {
        CardContainer(emphasize: true) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                ComicCoverCard(
                    title: project.title,
                    subtitle: project.collectionSubtitle,
                    accent: AppColor.accent(for: project.style),
                    eyebrow: project.style.moodLabel,
                    badge: project.statusDisplayName,
                    emphasize: false
                )
                .frame(width: 118)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(project.title)
                        .font(AppTypography.heading)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(project.collectionSubtitle)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)

                    Text("Open the reveal, continue reading or export the finished edition.")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)

                    HStack {
                        Text("Open project")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.accent(for: project.style))
                        Spacer()
                        Image(systemName: "book.closed")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColor.accent(for: project.style))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel(projectService: AppContainer.preview().projectService), container: .preview())
    }
    .previewContainer()
}
#endif
