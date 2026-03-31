import SwiftUI

struct CardContainer<Content: View>: View {
    let emphasize: Bool
    let content: Content

    init(emphasize: Bool = false, @ViewBuilder content: () -> Content) {
        self.emphasize = emphasize
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.md)
            .background(background)
            .overlay(border)
            .clipShape(RoundedRectangle(cornerRadius: AppElevation.Surface.radius, style: .continuous))
            .shadow(
                color: AppColor.bookShadow.opacity(emphasize ? 1 : 0.72),
                radius: emphasize ? 22 : AppElevation.Surface.shadowRadius,
                x: 0,
                y: emphasize ? 12 : AppElevation.Surface.shadowYOffset
            )
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: AppElevation.Surface.radius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: emphasize
                        ? [AppColor.surfaceElevated, AppColor.surface]
                        : [AppColor.surface, AppColor.surfaceMuted],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: AppElevation.Surface.radius, style: .continuous)
            .stroke(AppColor.border.opacity(emphasize ? 0.95 : 0.7), lineWidth: 1)
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    CardContainer(emphasize: true) {
        Text("Premium Card")
            .foregroundStyle(AppColor.textPrimary)
    }
    .padding()
    .background(AppColor.backgroundPrimary)
}
#endif
