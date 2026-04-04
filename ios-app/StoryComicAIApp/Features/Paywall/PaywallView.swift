import SwiftUI

struct PaywallView: View {
    @StateObject var viewModel: PaywallViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToViewer: Bool = false

    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.accent(for: flowStore.selectedStyle), showsDeskBand: true)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    switch viewModel.state {
                    case .idle, .loading:
                        LoadingStateView(title: "Preparing unlock options", subtitle: "Staging the rest of your story")
                            .frame(height: 420)

                    case let .failed(message):
                        ErrorStateView(title: "Paywall not available", message: message) {
                            viewModel.retry(projectID: presentationProjectID)
                        }
                        .frame(height: 420)

                    case let .loaded(content):
                        loadedContent(content: content)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, AppSpacing.section)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Unlock")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.onAppear(projectID: presentationProjectID)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }

    @ViewBuilder
    private func loadedContent(content: PaywallViewModel.Content) -> some View {
        let compactStyle = flowStore.selectedStyle

        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Collector Unlock")
                        .font(AppTypography.eyebrow)
                        .foregroundStyle(AppColor.textTertiary)
                        .tracking(1.3)
                        .textCase(.uppercase)

                    Text(content.headline)
                        .font(AppTypography.title)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(content.subheadline)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Spacer(minLength: 0)

                ComicCoverCard(
                    title: flowStore.projectName.isEmpty ? "Collector" : flowStore.projectName,
                    subtitle: "Unlock",
                    accent: AppColor.accent(for: compactStyle),
                    style: compactStyle,
                    eyebrow: compactStyle.coverEyebrow,
                    badge: "LOCKED",
                    emphasize: false,
                    presentation: .compact,
                    compactVariant: CompactCoverVariant.productDefault(for: compactStyle)
                )
                .frame(width: 106)
            }

            lockedPreview

            CardContainer(emphasize: true) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Your preview edition is staged. Unlocking opens the remaining pages, keeps export available and preserves the full collector version.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(content.lockReasonText)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.warning)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("Choose your edition")
                .font(AppTypography.heading)
                .foregroundStyle(AppColor.textPrimary)

            VStack(spacing: AppSpacing.md) {
                ForEach(content.plans) { plan in
                    Button {
                        viewModel.selectedPlanID = plan.id
                    } label: {
                        CardContainer(emphasize: viewModel.selectedPlanID == plan.id || plan.isRecommended) {
                            HStack(alignment: .top, spacing: AppSpacing.md) {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    if plan.isRecommended {
                                        Text(plan.badgeLabel ?? "Best Value")
                                            .font(AppTypography.meta)
                                            .foregroundStyle(AppColor.accent)
                                            .padding(.horizontal, AppSpacing.xs)
                                            .padding(.vertical, AppSpacing.xxs)
                                            .background(AppColor.surfaceMuted)
                                            .clipShape(Capsule())
                                    }
                                    Text(plan.title)
                                        .font(AppTypography.section)
                                        .foregroundStyle(AppColor.textPrimary)
                                    Text(plan.priceText)
                                        .font(AppTypography.body)
                                        .foregroundStyle(AppColor.textSecondary)
                                    Text("Complete comic access, collectible reveal and export-ready delivery.")
                                        .font(AppTypography.footnote)
                                        .foregroundStyle(AppColor.textSecondary)
                                }

                                Spacer()

                                Image(systemName: viewModel.selectedPlanID == plan.id ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(viewModel.selectedPlanID == plan.id ? AppColor.accent : AppColor.borderStrong)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if let projectID = presentationProjectID {
                NavigationLink(
                    destination: ComicPresentationCoordinatorView(
                        projectID: projectID,
                        container: container,
                        storyText: flowStore.storyText
                    ),
                    isActive: $navigateToViewer
                ) {
                    EmptyView()
                }
            }

            PrimaryButton(
                title: content.primaryButtonTitle,
                isLoading: viewModel.isUnlocking
            ) {
                guard let projectID = presentationProjectID else { return }
                viewModel.unlock(projectID: projectID) {
                    navigateToViewer = true
                }
            }
            .disabled(
                viewModel.selectedPlanID == nil
                    || viewModel.isUnlocking
                    || presentationProjectID == nil
            )
        }
    }

    private var lockedPreview: some View {
        ComicCoverCard(
            title: flowStore.projectName.isEmpty ? "Your comic continues here" : flowStore.projectName,
            subtitle: "Page 4 onward is staged behind the collector unlock.",
            accent: AppColor.accent(for: flowStore.selectedStyle),
            style: flowStore.selectedStyle,
            eyebrow: flowStore.selectedStyle.moodLabel,
            badge: "Preview Locked",
            emphasize: true
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppElevation.Cover.radius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColor.lockedOverlay.opacity(0.1), AppColor.lockedOverlay],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .overlay(alignment: .bottomLeading) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.44)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Your story continues on page 4")
                        .font(AppTypography.heading)
                        .foregroundStyle(AppColor.textOnDark)
                    Text("Unlock the full edition to open the book, keep export active and read every scene.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textOnDark.opacity(0.82))
                }
                .padding(AppSpacing.lg)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppElevation.Cover.radius, style: .continuous))
        }
        .shadow(color: AppColor.bookShadow, radius: 24, x: 0, y: 14)
    }

    private var presentationProjectID: UUID? {
        flowStore.createdProject?.id
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    PaywallView(
        viewModel: PaywallViewModel(
            comicPackageService: AppContainer.preview().comicPackageService,
            analyticsService: AppContainer.preview().analyticsService
        ),
        flowStore: CreateProjectFlowStore(),
        container: .preview()
    )
    .previewContainer()
}
#endif
