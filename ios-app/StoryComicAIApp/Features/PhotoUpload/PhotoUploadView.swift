import SwiftUI

struct PhotoUploadView: View {
    @StateObject var viewModel: PhotoUploadViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToHeroPreview: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            CardContainer {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Uploaded Photos")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textPrimary)

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

            Spacer()
        }
        .padding(AppSpacing.lg)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
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
