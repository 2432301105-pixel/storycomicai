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
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColor.accent)
                if isLoading {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text(title)
                        .font(AppTypography.button)
                        .foregroundStyle(.black)
                }
            }
            .frame(height: 50)
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
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
