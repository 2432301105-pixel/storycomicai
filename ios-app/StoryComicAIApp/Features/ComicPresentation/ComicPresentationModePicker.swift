import SwiftUI

struct ComicPresentationModePicker: View {
    let selectedMode: ComicPresentationMode
    let onSelect: (ComicPresentationMode) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(ComicPresentationMode.switchableModes) { mode in
                Button {
                    onSelect(mode)
                } label: {
                    Text(mode.title)
                        .font(AppTypography.footnote)
                        .foregroundStyle(selectedMode == mode ? AppColor.textPrimary : AppColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selectedMode == mode ? AppColor.surfaceElevated : Color.clear)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.xs)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColor.surfaceMuted)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColor.border.opacity(0.9), lineWidth: 1)
        }
        .animation(AppMotion.modeSwitch(reduceMotion: reduceMotion), value: selectedMode)
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    ComicPresentationModePicker(selectedMode: .preview) { _ in }
        .padding()
        .background(AppColor.backgroundPrimary)
}
#endif
