import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    let container: AppContainer
    @State private var navigateToCreateProject: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                header

                PrimaryButton(title: "Create New Story") {
                    navigateToCreateProject = true
                }

                Button {
                    navigateToCreateProject = true
                } label: {
                    CardContainer {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Build From Your Story Prompt")
                                .font(AppTypography.heading)
                                .foregroundStyle(AppColor.textPrimary)
                            Text("Generate personalized comic book reveal and page-turn preview.")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.plain)

                recentProjectsSection
            }
            .padding(AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .navigationDestination(isPresented: $navigateToCreateProject) {
            CreateProjectView(
                viewModel: CreateProjectViewModel(),
                flowStore: CreateProjectFlowStore(),
                container: container
            )
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Home")
        .task { await viewModel.loadRecentProjects() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Your Personal Story Studio")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)

            Text("Build premium comics where you are the main character.")
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var recentProjectsSection: some View {
        switch viewModel.recentProjectsState {
        case .idle, .loading:
            LoadingStateView(title: "Loading projects")
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 14))

        case let .failed(message):
            ErrorStateView(title: "Could not load projects", message: message) {
                Task { await viewModel.loadRecentProjects() }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 14))

        case let .loaded(projects):
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Recent Projects")
                    .font(AppTypography.heading)
                    .foregroundStyle(AppColor.textPrimary)

                if projects.isEmpty {
                    CardContainer {
                        Text("No projects yet. Start your first story.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    ForEach(projects.prefix(3)) { project in
                        CardContainer {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(project.title)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColor.textPrimary)
                                Text("\(project.style.displayName) • \(project.status)")
                                    .font(AppTypography.footnote)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    HomeView(viewModel: HomeViewModel(projectService: AppContainer.preview().projectService), container: .preview())
        .previewContainer()
}
#endif
