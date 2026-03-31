import SwiftUI

struct LibraryView: View {
    @StateObject var viewModel: LibraryViewModel
    let container: AppContainer

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md)
    ]

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                LoadingStateView(title: "Loading your shelf", subtitle: "Arranging your finished editions")

            case let .failed(message):
                ErrorStateView(title: "Failed to load library", message: message) {
                    Task { await viewModel.loadProjects() }
                }

            case let .loaded(projects):
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        header(projectCount: projects.count)

                        if projects.isEmpty {
                            CardContainer(emphasize: true) {
                                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                    Text("Your first comic belongs here")
                                        .font(AppTypography.section)
                                        .foregroundStyle(AppColor.textPrimary)
                                    Text("Once a project is generated, its finished edition will appear on this shelf.")
                                        .font(AppTypography.body)
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                                ForEach(projects) { project in
                                    NavigationLink {
                                        ProjectDetailView(
                                            viewModel: ProjectDetailViewModel(project: project),
                                            container: container
                                        )
                                    } label: {
                                        LibraryProjectCard(project: project)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.section)
                }
                .background(AppColor.backgroundPrimary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .task { await viewModel.loadProjects() }
    }

    private func header(projectCount: Int) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Library")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)
            Text(projectCount == 0 ? "Your collection is waiting for its first edition." : "\(projectCount) comic editions in your collection")
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}

private struct LibraryProjectCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            cover

            Text(project.title)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(2)

            Text(project.collectionSubtitle)
                .font(AppTypography.footnote)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private var cover: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [AppColor.accent(for: project.style), AppColor.textPrimary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .aspectRatio(2 / 3, contentMode: .fit)
            .overlay(alignment: .topLeading) {
                Text(project.statusDisplayName)
                    .font(AppTypography.meta)
                    .foregroundStyle(AppColor.textOnDark)
                    .padding(.horizontal, AppSpacing.xs)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(Color.black.opacity(0.18))
                    .clipShape(Capsule())
                    .padding(AppSpacing.sm)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(project.style.moodLabel)
                        .font(AppTypography.meta)
                        .foregroundStyle(AppColor.textOnDark.opacity(0.78))
                    Text(project.title)
                        .font(AppTypography.heading)
                        .foregroundStyle(AppColor.textOnDark)
                        .lineLimit(3)
                }
                .padding(AppSpacing.sm)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: AppColor.bookShadow, radius: 16, x: 0, y: 8)
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
