import SwiftUI

struct ErrorStateView: View {
    let title: String
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 42))
                .foregroundStyle(AppColor.warning)

            Text(title)
                .font(AppTypography.heading)
                .foregroundStyle(AppColor.textPrimary)

            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)

            if let retryAction {
                PrimaryButton(title: "Retry", action: retryAction)
                    .padding(.top, AppSpacing.sm)
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.backgroundPrimary)
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    ErrorStateView(title: "Something went wrong", message: "Please try again.", retryAction: {})
}
#endif
