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
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity, alignment: .center)
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

            Text("Your personal comic studio")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)

            Text("Create a premium comic edition, return to your recent books and keep the collection calm and readable.")
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var heroCreateCard: some View {
        Button {
            navigateToCreateProject = true
        } label: {
            CardContainer(emphasize: true) {
                HStack(alignment: .center, spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Start A New Edition")
                            .font(AppTypography.heading)
                            .foregroundStyle(AppColor.textPrimary)

                        Text("Upload photos, write the story, choose the visual edition and reveal the finished comic like a bound book.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: AppSpacing.xs) {
                            Text("Create your comic")
                                .font(AppTypography.button)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(AppColor.accent)
                    }

                    Spacer(minLength: 0)

                    ComicCoverCard(
                        title: "Personal\nEdition",
                        subtitle: "Bound for one",
                        accent: AppColor.accent(for: .cinematic),
                        style: .cinematic,
                        eyebrow: "Create",
                        badge: "New",
                        emphasize: false
                    )
                    .frame(width: 124)
                }
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
            let featuredProjects = Array(projects.prefix(3))

            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Recent Editions")
                        .font(AppTypography.section)
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
                    CardContainer {
                        VStack(spacing: AppSpacing.md) {
                            ForEach(featuredProjects) { project in
                                NavigationLink {
                                    ProjectDetailView(
                                        viewModel: ProjectDetailViewModel(project: project),
                                        container: container
                                    )
                                } label: {
                                    HomeProjectCard(project: project)
                                }
                                .buttonStyle(.plain)

                                if project.id != featuredProjects.last?.id {
                                    Divider()
                                        .overlay(AppColor.border.opacity(0.8))
                                }
                            }
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
        HStack(alignment: .center, spacing: AppSpacing.md) {
            ComicCoverCard(
                title: project.title,
                subtitle: nil,
                accent: AppColor.accent(for: project.style),
                style: project.style,
                eyebrow: project.style.moodLabel,
                badge: project.statusDisplayName,
                emphasize: false
            )
            .frame(width: 94)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(project.title)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)

                Text(project.collectionSubtitle)
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(3)

                Text(project.statusDisplayName)
                    .font(AppTypography.badge)
                    .foregroundStyle(AppColor.accent(for: project.style))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .padding(.top, AppSpacing.xxs)
            }
            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.textTertiary)
        }
        .padding(.vertical, AppSpacing.xs)
        .contentShape(Rectangle())
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
