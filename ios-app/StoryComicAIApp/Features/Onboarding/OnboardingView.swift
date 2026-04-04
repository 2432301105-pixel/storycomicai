import SwiftUI

struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            EditorialBackground(accent: AppColor.accent, showsDeskBand: false)

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                VStack(spacing: AppSpacing.sm) {
                    Text(L10n.string("app.name"))
                        .font(AppTypography.eyebrow)
                        .foregroundStyle(AppColor.textTertiary)
                        .tracking(1.4)
                        .textCase(.uppercase)

                    Text(L10n.string("onboarding.headline"))
                        .font(AppTypography.title)
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                }

                CardContainer(emphasize: true) {
                    TabView(selection: $viewModel.currentIndex) {
                        ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                            VStack(spacing: AppSpacing.md) {
                                Image(systemName: page.systemImage)
                                    .font(.system(size: 64))
                                    .foregroundStyle(AppColor.accent)

                                Text(page.title)
                                    .font(AppTypography.heading)
                                    .foregroundStyle(AppColor.textPrimary)
                                    .multilineTextAlignment(.center)

                                Text(page.subtitle)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColor.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, AppSpacing.lg)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(height: 320)
                }

                PrimaryButton(title: viewModel.isLastPage ? L10n.string("action.get_started") : L10n.string("action.next")) {
                    if viewModel.isLastPage {
                        onFinish()
                    } else {
                        viewModel.next()
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    OnboardingView(viewModel: OnboardingViewModel(), onFinish: {})
        .previewContainer()
}
#endif
