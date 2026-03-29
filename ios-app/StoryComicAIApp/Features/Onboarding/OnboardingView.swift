import SwiftUI

struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            TabView(selection: $viewModel.currentIndex) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: page.systemImage)
                            .font(.system(size: 64))
                            .foregroundStyle(AppColor.accent)

                        Text(page.title)
                            .font(AppTypography.title)
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
            .frame(height: 360)

            PrimaryButton(title: viewModel.isLastPage ? "Get Started" : "Next") {
                if viewModel.isLastPage {
                    onFinish()
                } else {
                    viewModel.next()
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    OnboardingView(viewModel: OnboardingViewModel(), onFinish: {})
        .previewContainer()
}
#endif
