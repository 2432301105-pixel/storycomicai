import SwiftUI

struct ProjectDetailView: View {
    @StateObject var viewModel: ProjectDetailViewModel
    let container: AppContainer

    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.accent(for: viewModel.project.style), showsDeskBand: false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    ComicCoverCard(
                        title: viewModel.project.title,
                        subtitle: viewModel.project.collectionSubtitle,
                        accent: AppColor.accent(for: viewModel.project.style),
                        style: viewModel.project.style,
                        eyebrow: viewModel.project.style.moodLabel,
                        badge: viewModel.project.statusDisplayName,
                        emphasize: true
                    )

                    CardContainer(emphasize: true) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            detailRow(title: "Style", value: viewModel.project.style.displayName)
                            detailRow(title: "Status", value: viewModel.project.statusDisplayName)
                            detailRow(title: "Pages", value: "\(viewModel.project.targetPages)")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    NavigationLink {
                        ComicPresentationCoordinatorView(
                            projectID: viewModel.project.id,
                            container: container
                        )
                    } label: {
                        Text("Open Comic Book")
                            .font(AppTypography.button)
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(
                                LinearGradient(
                                    colors: [AppColor.accentSecondary, AppColor.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppColor.borderStrong.opacity(0.55), lineWidth: 1)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: AppColor.bookShadow, radius: 16, x: 0, y: 8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, AppSpacing.section)
            }
        }
        .navigationTitle("Project Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(title)
                .font(AppTypography.meta)
                .foregroundStyle(AppColor.textTertiary)
                .textCase(.uppercase)
            Text(value)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColor.textPrimary)
        }
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        ProjectDetailView(
            viewModel: ProjectDetailViewModel(project: MockFixtures.sampleProjects()[0]),
            container: .preview()
        )
    }
    .previewContainer()
}
#endif
