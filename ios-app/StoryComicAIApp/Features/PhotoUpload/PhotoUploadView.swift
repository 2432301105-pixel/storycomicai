import SwiftUI

struct PhotoUploadView: View {
    @StateObject var viewModel: PhotoUploadViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToHeroPreview: Bool = false

    var body: some View {
        FloatingPanelScreen(accent: AppColor.accentSecondary) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Hero Source")
                    .font(AppTypography.eyebrow)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(1.4)
                    .textCase(.uppercase)

                Text("Choose reference photos")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)

                Text("These images define the face and identity that should persist across the comic.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
        } content: {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Uploaded Photos")
                        .font(AppTypography.meta)
                        .foregroundStyle(AppColor.textTertiary)
                        .textCase(.uppercase)

                    CardContainer(emphasize: true) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            if flowStore.selectedLocalPhotos.isEmpty {
                                Text("No photos selected yet.")
                                    .font(AppTypography.footnote)
                                    .foregroundStyle(AppColor.textSecondary)
                            } else {
                                ForEach(flowStore.selectedLocalPhotos) { photo in
                                    HStack {
                                        Image(systemName: "photo")
                                        Text(photo.filename)
                                            .font(AppTypography.footnote)
                                        Spacer()
                                    }
                                    .foregroundStyle(AppColor.textSecondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                HStack(spacing: AppSpacing.sm) {
                    PrimaryButton(title: "Add Demo Photo") {
                        viewModel.addMockPhoto(to: flowStore)
                    }

                    PrimaryButton(title: "Use Fixture") {
                        flowStore.selectedLocalPhotos = MockFixtures.samplePhotos()
                    }
                }

                if let message = viewModel.uploadErrorMessage {
                    Text(message)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } footer: {
            NavigationLink(
                destination: HeroPreviewView(
                    viewModel: HeroPreviewViewModel(
                        heroPreviewService: container.heroPreviewService,
                        pollingIntervalSeconds: container.configuration.heroPreviewPollingIntervalSeconds
                    ),
                    flowStore: flowStore,
                    container: container
                ),
                isActive: $navigateToHeroPreview
            ) { EmptyView() }

            PrimaryButton(title: "Upload and Continue", isLoading: viewModel.isUploading) {
                Task {
                    let success = await viewModel.uploadSelectedPhotos(for: flowStore)
                    if success { navigateToHeroPreview = true }
                }
            }
        }
        .navigationTitle("Photo Upload")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    PhotoUploadPreviewFactory.make()
}
#endif

private enum PhotoUploadPreviewFactory {
    @MainActor
    static func make() -> some View {
        let flowStore = CreateProjectFlowStore()
        flowStore.createdProject = MockFixtures.sampleProjects().first
        return PhotoUploadView(
            viewModel: PhotoUploadViewModel(uploadService: AppContainer.preview().uploadService),
            flowStore: flowStore,
            container: .preview()
        )
        .previewContainer()
    }
}
