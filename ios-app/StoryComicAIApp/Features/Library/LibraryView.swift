import SwiftUI

struct LibraryView: View {
    @StateObject var viewModel: LibraryViewModel
    let container: AppContainer

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                LoadingStateView(title: "Loading library")

            case let .failed(message):
                ErrorStateView(title: "Failed to load library", message: message) {
                    Task { await viewModel.loadProjects() }
                }

            case let .loaded(projects):
                if projects.isEmpty {
                    VStack(spacing: AppSpacing.sm) {
                        Text("No projects yet")
                            .font(AppTypography.heading)
                            .foregroundStyle(AppColor.textPrimary)
                        Text("Your generated comics will appear here.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColor.backgroundPrimary)
                } else {
                    List(projects) { project in
                        NavigationLink {
                            ProjectDetailView(
                                viewModel: ProjectDetailViewModel(project: project),
                                container: container
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(project.title)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColor.textPrimary)
                                Text("\(project.style.displayName) • \(project.status)")
                                    .font(AppTypography.footnote)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                            .padding(.vertical, AppSpacing.xs)
                        }
                        .listRowBackground(AppColor.surface)
                    }
                    .scrollContentBackground(.hidden)
                    .background(AppColor.backgroundPrimary)
                }
            }
        }
        .navigationTitle("Library")
        .task { await viewModel.loadProjects() }
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        LibraryView(
            viewModel: LibraryViewModel(projectService: AppContainer.preview().projectService),
            container: .preview()
        )
    }
    .previewContainer()
}
#endif
