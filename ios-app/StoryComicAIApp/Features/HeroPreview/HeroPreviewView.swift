import SwiftUI

struct HeroPreviewView: View {
    @StateObject var viewModel: HeroPreviewViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToGeneration: Bool = false

    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.accentSecondary, showsDeskBand: false)

            VStack(spacing: AppSpacing.lg) {
                content

                NavigationLink(
                    destination: GenerationProgressView(
                        viewModel: GenerationProgressViewModel(
                            comicGenerationService: container.comicGenerationService,
                            comicPackageService: container.comicPackageService,
                            pollingIntervalSeconds: container.configuration.heroPreviewPollingIntervalSeconds,
                            projectID: flowStore.createdProject?.id ?? UUID()
                        ),
                        flowStore: flowStore,
                        container: container
                    ),
                    isActive: $navigateToGeneration
                ) { EmptyView() }

                if case let .loaded(job) = viewModel.state,
                   job.status == .succeeded {
                    PrimaryButton(title: L10n.string("action.continue_generation")) {
                        navigateToGeneration = true
                    }

                    PrimaryButton(title: L10n.string("action.approve_character_soon")) {}
                        .disabled(true)
                        .opacity(0.5)
                }
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle(L10n.string("hero.nav"))
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
            LoadingStateView(title: L10n.string("hero.loading_title"), subtitle: L10n.string("hero.loading_subtitle"))
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 14))

        case let .failed(message):
            ErrorStateView(title: L10n.string("hero.failed_title"), message: message) {
                viewModel.retry(flowStore: flowStore)
            }
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 14))

        case let .loaded(job):
            CardContainer(emphasize: true) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(L10n.string("hero.status_prefix", job.status.displayTitle))
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(L10n.string("hero.stage_prefix", localizedStageTitle(job.currentStage)))
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)

                    ProgressView(value: Double(job.progressPercent), total: 100)
                        .tint(AppColor.accent)

                    Text(L10n.string("hero.preview_section"))
                        .font(AppTypography.meta)
                        .foregroundStyle(AppColor.textTertiary)
                        .textCase(.uppercase)

                    HStack(spacing: AppSpacing.sm) {
                        previewCard(title: L10n.string("common.front"), url: job.previewAssets?.frontURL)
                        previewCard(title: L10n.string("common.three_quarter"), url: job.previewAssets?.threeQuarterURL)
                        previewCard(title: L10n.string("common.side"), url: job.previewAssets?.sideURL)
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

    private func localizedStageTitle(_ stage: String) -> String {
        switch stage
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_") {
        case "story_planner":
            return L10n.string("generation.stage.story_planner")
        case "character_bible":
            return L10n.string("generation.stage.character_bible")
        case "style_guide":
            return L10n.string("generation.stage.style_guide")
        case "reference_taxonomy":
            return L10n.string("generation.stage.reference_taxonomy")
        case "panel_prompts":
            return L10n.string("generation.stage.panel_prompts")
        case "page_composer":
            return L10n.string("generation.stage.page_composer")
        case "completed":
            return L10n.string("generation.stage.completed")
        case "failed":
            return L10n.string("generation.stage.failed")
        default:
            return stage
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
