import SwiftUI

struct LibraryView: View {
    @StateObject var viewModel: LibraryViewModel
    let container: AppContainer

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md)
    ]

    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.accentSecondary, showsDeskBand: false)

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
                                LazyVGrid(columns: columns, spacing: AppSpacing.lg) {
                                    ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                                        NavigationLink {
                                            ProjectDetailView(
                                                viewModel: ProjectDetailViewModel(project: project),
                                                container: container
                                            )
                                        } label: {
                                            LibraryProjectCard(project: project, isOffset: index.isMultiple(of: 2) == false)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.xl)
                        .padding(.bottom, AppSpacing.section)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationBarTitleDisplayMode(.inline)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .task { await viewModel.loadProjects() }
    }

    private func header(projectCount: Int) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Collection")
                .font(AppTypography.eyebrow)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(1.4)
                .textCase(.uppercase)

            Text("Your Comic Shelf")
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
    let isOffset: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ComicCoverCard(
                title: project.title,
                subtitle: project.collectionSubtitle,
                accent: AppColor.accent(for: project.style),
                eyebrow: project.style.moodLabel,
                badge: project.statusDisplayName,
                emphasize: true
            )
            .offset(y: isOffset ? 10 : 0)

            Text(project.title)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(2)

            Text(project.collectionSubtitle)
                .font(AppTypography.footnote)
                .foregroundStyle(AppColor.textSecondary)
        }
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
