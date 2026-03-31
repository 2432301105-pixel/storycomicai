import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    let container: AppContainer
    @State private var navigateToCreateProject: Bool = false

    var body: some View {
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
        .navigationDestination(isPresented: $navigateToCreateProject) {
            CreateProjectView(
                viewModel: CreateProjectViewModel(),
                flowStore: CreateProjectFlowStore(),
                container: container
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
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

            Text("Build a premium comic edition where you are the main character, then open it like a finished book.")
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
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text("Start A New Edition")
                        .font(AppTypography.eyebrow)
                        .foregroundStyle(AppColor.textTertiary)
                        .tracking(1.1)
                        .textCase(.uppercase)

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Turn your story prompt into a reveal-ready comic book")
                            .font(AppTypography.heading)
                            .foregroundStyle(AppColor.textPrimary)

                        Text("Upload photos, choose the art direction, preview your hero and open the finished book reveal.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    HStack {
                        Text("Create your comic")
                            .font(AppTypography.button)
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColor.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Recent Editions")
                            .font(AppTypography.heading)
                            .foregroundStyle(AppColor.textPrimary)
                        Text("Return to the books already on your desk.")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Spacer()
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
        CardContainer {
            HStack(spacing: AppSpacing.md) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppColor.accent(for: project.style).opacity(0.92), AppColor.textPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 144)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text(project.style.moodLabel)
                                .font(AppTypography.meta)
                                .foregroundStyle(AppColor.textOnDark.opacity(0.82))
                            Text(project.title)
                                .font(AppTypography.section)
                                .foregroundStyle(AppColor.textOnDark)
                                .lineLimit(3)
                        }
                        .padding(AppSpacing.sm)
                    }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(project.title)
                        .font(AppTypography.section)
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.leading)

                    Text(project.collectionSubtitle)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)

                    Text(project.statusDisplayName)
                        .font(AppTypography.meta)
                        .foregroundStyle(AppColor.accent(for: project.style))
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(AppColor.surfaceMuted)
                        .clipShape(Capsule())

                    Spacer()

                    HStack {
                        Text("Open project")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColor.textTertiary)
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
