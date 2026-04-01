import SwiftUI

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    init(title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppColor.accentSecondary.opacity(0.96), AppColor.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(AppColor.borderStrong.opacity(0.44), lineWidth: 1)
                    )
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.22), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .shadow(color: AppColor.bookShadow, radius: 18, x: 0, y: 10)

                if isLoading {
                    ProgressView()
                        .tint(AppColor.textPrimary)
                } else {
                    Text(title)
                        .font(AppTypography.button)
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
            .frame(height: 60)
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
        .opacity(isLoading ? 0.9 : 1)
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    VStack(spacing: 12) {
        PrimaryButton(title: "Continue") {}
        PrimaryButton(title: "Processing", isLoading: true) {}
    }
    .padding()
    .background(AppColor.backgroundPrimary)
}
#endif
