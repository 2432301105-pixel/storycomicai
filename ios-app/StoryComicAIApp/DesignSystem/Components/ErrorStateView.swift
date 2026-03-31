import SwiftUI

struct ErrorStateView: View {
    let title: String
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Circle()
                .fill(AppColor.surfaceMuted)
                .frame(width: 76, height: 76)
                .overlay {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppColor.warning)
                }

            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.heading)
                    .foregroundStyle(AppColor.textPrimary)

                Text(message)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let retryAction {
                PrimaryButton(title: "Try Again", action: retryAction)
                    .frame(maxWidth: 240)
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.backgroundPrimary)
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    ErrorStateView(title: "Something went wrong", message: "Please try again.", retryAction: {})
}
#endif
