import SwiftUI

struct StyleSelectionView: View {
    @StateObject var viewModel: StyleSelectionViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToGeneration: Bool = false
    @State private var generationProjectID: UUID?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        FloatingPanelScreen(accent: AppColor.accentSecondary) {
            header
        } content: {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                ForEach(StoryStyle.allCases) { style in
                    Button {
                        flowStore.selectedStyle = style
                    } label: {
                        StyleOptionCard(style: style, isSelected: flowStore.selectedStyle == style)
                    }
                    .buttonStyle(.plain)
                }

                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } footer: {
                    PrimaryButton(title: L10n.string("action.generate_comic"), isLoading: viewModel.isCreatingProject) {
                        Task {
                            let success = await viewModel.ensureProjectExists(for: flowStore)
                            if (success || flowStore.createdProject != nil), let projectID = flowStore.createdProject?.id {
                                generationProjectID = projectID
                                navigateToGeneration = true
                            }
                        }
                    }
            .disabled(viewModel.isCreatingProject)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationDestination(isPresented: $navigateToGeneration) {
            if let projectID = generationProjectID {
                GenerationProgressView(
                    viewModel: GenerationProgressViewModel(
                        comicGenerationService: container.comicGenerationService,
                        comicPackageService: container.comicPackageService,
                        pollingIntervalSeconds: container.configuration.heroPreviewPollingIntervalSeconds,
                        projectID: projectID
                    ),
                    flowStore: flowStore,
                    container: container
                )
            } else {
                ErrorStateView(
                    title: L10n.string("generation.not_ready_title"),
                    message: L10n.string("generation.not_ready_message")
                ) {}
            }
        }
        .navigationTitle(L10n.string("style.nav"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(L10n.string("style.header_title"))
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)
            Text(L10n.string("style.header_subtitle"))
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}

private struct StyleOptionCard: View {
    let style: StoryStyle
    let isSelected: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        CardContainer(emphasize: isSelected) {
            Group {
                if horizontalSizeClass == .compact {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        cover
                            .frame(height: 190)
                        styleMeta
                    }
                } else {
                    HStack(alignment: .top, spacing: AppSpacing.md) {
                        cover
                            .frame(width: 108)
                        styleMeta
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var cover: some View {
        ComicCoverCard(
            title: style.coverTitle,
            subtitle: style.coverSubtitle,
            accent: AppColor.accent(for: style),
            style: style,
            eyebrow: style.coverEyebrow,
            badge: nil,
            emphasize: isSelected,
            presentation: .compact
        )
    }

    private var styleMeta: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(style.displayName)
                .font(AppTypography.heading)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.84)

            Text(style.editorialBlurb)
                .font(AppTypography.footnote)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(horizontalSizeClass == .compact ? 3 : 4)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            HStack(spacing: AppSpacing.xs) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppColor.accent(for: style) : AppColor.borderStrong)
                Text(isSelected ? L10n.string("style.selected_for_rendering") : L10n.string("common.tap_to_choose"))
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.92)
            }
            .padding(.top, AppSpacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    StyleSelectionView(
        viewModel: StyleSelectionViewModel(projectService: AppContainer.preview().projectService),
        flowStore: CreateProjectFlowStore(),
        container: .preview()
    )
    .previewContainer()
}
#endif
