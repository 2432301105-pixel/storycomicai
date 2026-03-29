import SwiftUI

struct ProjectDetailView: View {
    @StateObject var viewModel: ProjectDetailViewModel
    let container: AppContainer

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            CardContainer {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(viewModel.project.title)
                        .font(AppTypography.heading)
                        .foregroundStyle(AppColor.textPrimary)

                    Text("Style: \(viewModel.project.style.displayName)")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)

                    Text("Status: \(viewModel.project.status)")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            NavigationLink {
                ComicPresentationCoordinatorView(
                    projectID: viewModel.project.id,
                    container: container
                )
            } label: {
                CardContainer {
                    Text("Open Comic Book")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(AppSpacing.lg)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Project Detail")
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
