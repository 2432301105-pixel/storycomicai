import SwiftUI

struct ComicPresentationModePicker: View {
    let selectedMode: ComicPresentationMode
    let onSelect: (ComicPresentationMode) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Picker("Presentation Mode", selection: binding) {
            ForEach(ComicPresentationMode.switchableModes) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .animation(AppMotion.modeSwitch(reduceMotion: reduceMotion), value: selectedMode)
    }

    private var binding: Binding<ComicPresentationMode> {
        Binding(
            get: { selectedMode },
            set: { onSelect($0) }
        )
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    ComicPresentationModePicker(selectedMode: .preview) { _ in }
        .padding()
        .background(AppColor.backgroundPrimary)
}
#endif
