import SwiftUI

struct CardContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.md)
            .background(AppColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    CardContainer {
        Text("Premium Card")
            .foregroundStyle(AppColor.textPrimary)
    }
    .padding()
    .background(AppColor.backgroundPrimary)
}
#endif
