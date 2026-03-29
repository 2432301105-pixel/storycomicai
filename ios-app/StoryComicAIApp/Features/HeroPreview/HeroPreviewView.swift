import SwiftUI

struct HeroPreviewView: View {
    @StateObject var viewModel: HeroPreviewViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToGeneration: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            content

            NavigationLink(
                destination: GenerationProgressView(
                    viewModel: GenerationProgressViewModel(),
                    flowStore: flowStore,
                    container: container
                ),
                isActive: $navigateToGeneration
            ) { EmptyView() }

            if case let .loaded(job) = viewModel.state,
               job.status == .succeeded {
                PrimaryButton(title: "Continue to Generation") {
                    navigateToGeneration = true
                }

                PrimaryButton(title: "Approve Character (Soon)") {}
                    .disabled(true)
                    .opacity(0.5)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Hero Preview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.startIfNeeded(flowStore: flowStore)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingStateView(title: "Generating Hero Preview", subtitle: "This can take a few moments.")
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 14))

        case let .failed(message):
            ErrorStateView(title: "Hero Preview Failed", message: message) {
                viewModel.retry(flowStore: flowStore)
            }
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 14))

        case let .loaded(job):
            CardContainer {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Status: \(job.status.displayTitle)")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textPrimary)

                    Text("Stage: \(job.currentStage)")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)

                    ProgressView(value: Double(job.progressPercent), total: 100)
                        .tint(AppColor.accent)

                    HStack(spacing: AppSpacing.sm) {
                        previewCard(title: "Front", url: job.previewAssets?.frontURL)
                        previewCard(title: "3/4", url: job.previewAssets?.threeQuarterURL)
                        previewCard(title: "Side", url: job.previewAssets?.sideURL)
                    }
                }
            }
        }
    }

    private func previewCard(title: String, url: URL?) -> some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColor.backgroundSecondary)
                if let url {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Image(systemName: "person.crop.square")
                        .font(.title2)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .frame(height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(title)
                .font(AppTypography.footnote)
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    HeroPreviewPreviewFactory.make()
}
#endif

private enum HeroPreviewPreviewFactory {
    @MainActor
    static func make() -> some View {
        let flowStore = CreateProjectFlowStore()
        flowStore.createdProject = MockFixtures.sampleProjects().first
        flowStore.uploadedPhotoIDs = [UUID(), UUID()]
        return HeroPreviewView(
            viewModel: HeroPreviewViewModel(
                heroPreviewService: AppContainer.preview().heroPreviewService,
                pollingIntervalSeconds: 1
            ),
            flowStore: flowStore,
            container: .preview()
        )
        .previewContainer()
    }
}
