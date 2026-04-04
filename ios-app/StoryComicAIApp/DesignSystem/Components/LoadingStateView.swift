import SwiftUI

struct LoadingStateView: View {
    let title: String
    let subtitle: String?

    init(title: String = L10n.string("loading.default_title"), subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            panelPreview

            VStack(spacing: AppSpacing.xs) {
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

            Text(L10n.string("loading.preparing_studio"))
                .font(AppTypography.meta)
                .foregroundStyle(AppColor.textTertiary)
                .textCase(.uppercase)
                .tracking(1.1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xl)
        .background(AppColor.backgroundPrimary)
    }

    private var panelPreview: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(index == 1 ? AppColor.surfaceElevated : AppColor.surfaceMuted)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppColor.border.opacity(0.8), lineWidth: 1)
                    )
                    .frame(height: index == 1 ? 156 : 132)
            }
        }
        .overlay {
            ProgressView()
                .tint(AppColor.accent)
                .scaleEffect(1.1)
        }
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    LoadingStateView(title: L10n.string("hero.loading_title"), subtitle: L10n.string("hero.loading_subtitle"))
}
#endif
