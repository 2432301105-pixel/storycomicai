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
                    LoadingStateView(title: L10n.string("library.loading_title"), subtitle: L10n.string("library.loading_subtitle"))

                case let .failed(message):
                    ErrorStateView(title: L10n.string("library.error_title"), message: message) {
                        Task { await viewModel.loadProjects() }
                    }

                case let .loaded(projects):
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: AppSpacing.lg) {
                            header(projectCount: projects.count)

                            if projects.isEmpty {
                                CardContainer(emphasize: true) {
                                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                        Text(L10n.string("library.empty_title"))
                                            .font(AppTypography.section)
                                            .foregroundStyle(AppColor.textPrimary)
                                        Text(L10n.string("library.empty_body"))
                                            .font(AppTypography.body)
                                            .foregroundStyle(AppColor.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            } else {
                                CardContainer {
                                    LazyVGrid(columns: columns, spacing: AppSpacing.lg) {
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
                        }
                        .frame(maxWidth: 640)
                        .frame(maxWidth: .infinity, alignment: .center)
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
            Text(L10n.string("library.eyebrow"))
                .font(AppTypography.eyebrow)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(1.4)
                .textCase(.uppercase)

            Text(L10n.string("library.title"))
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)

            Text(projectCount == 0 ? L10n.string("library.subtitle_empty") : L10n.string("library.subtitle_count", projectCount))
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}

private struct LibraryProjectCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ComicCoverCard(
                title: project.title,
                subtitle: nil,
                accent: AppColor.accent(for: project.style),
                style: project.style,
                eyebrow: project.style.coverEyebrow,
                badge: nil,
                emphasize: false,
                presentation: .compact
            )

            Text(project.title)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(2)

            Text(project.collectionSubtitle)
                .font(AppTypography.footnote)
                .foregroundStyle(AppColor.textSecondary)

            Text(project.statusDisplayName)
                .font(AppTypography.badge)
                .foregroundStyle(AppColor.accent(for: project.style))
                .tracking(0.8)
                .textCase(.uppercase)
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
