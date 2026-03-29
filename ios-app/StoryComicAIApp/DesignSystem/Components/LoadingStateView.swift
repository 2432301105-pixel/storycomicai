import SwiftUI

struct LoadingStateView: View {
    let title: String
    let subtitle: String?

    init(title: String = "Loading", subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .tint(AppColor.accent)
            Text(title)
                .font(AppTypography.heading)
                .foregroundStyle(AppColor.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.lg)
        .background(AppColor.backgroundPrimary)
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    LoadingStateView(title: "Preparing Hero", subtitle: "Generating your preview...")
}
#endif
