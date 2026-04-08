import SwiftUI

struct StoryInputView: View {
    @StateObject var viewModel: StoryInputViewModel
    @ObservedObject var flowStore: CreateProjectFlowStore
    let container: AppContainer

    @State private var navigateToStyleSelection = false
    @FocusState private var storyFieldFocused: Bool
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColor.inkBlack.ignoresSafeArea()
            HalftoneTextureView().ignoresSafeArea().allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    header
                    pipelineStrip
                    inputField
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            // Sticky bottom CTA
            bottomCTA
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .background(AppColor.inkBlack.ignoresSafeArea())
        .background(
            NavigationLink(
                destination: StyleSelectionView(
                    viewModel: StyleSelectionViewModel(projectService: container.projectService),
                    flowStore: flowStore,
                    container: container
                ),
                isActive: $navigateToStyleSelection
            ) { EmptyView() }
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) { appeared = true }
        }
    }

    // ─── Header ───────────────────────────────────────────────────────────────
    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(AppColor.comicRed)
                    .frame(width: 20, height: 3)
                Text("STEP 1 OF 3")
                    .font(AppTypography.eyebrow)
                    .foregroundStyle(AppColor.comicRed)
                    .tracking(2.0)
            }

            Text("Write your\nstory.")
                .font(.system(size: 42, weight: .black, design: .serif))
                .foregroundStyle(AppColor.textPrimary)
                .lineSpacing(2)

            Text("Any story. Any length. Claude will turn it into panels.")
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
    }

    // ─── Pipeline strip ───────────────────────────────────────────────────────
    private var pipelineStrip: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(index == 0 ? AppColor.comicYellow : AppColor.inkPanel)
                                .frame(width: 28, height: 20)
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(
                                    index == 0 ? AppColor.comicYellow : AppColor.panelBorder,
                                    lineWidth: 1
                                )
                                .frame(width: 28, height: 20)
                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(index == 0 ? AppColor.textOnLight : AppColor.textTertiary)
                        }
                        Text(step)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(index == 0 ? AppColor.comicYellow : AppColor.textTertiary)
                            .tracking(0.8)
                    }

                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(AppColor.panelBorder)
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 14)
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
    }

    private let steps = ["STORY", "STYLE", "COMIC"]

    // ─── Input field ──────────────────────────────────────────────────────────
    private var inputField: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text("YOUR STORY")
                    .font(AppTypography.eyebrow)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(1.6)
                Spacer()
                Text("\(flowStore.storyText.count) chars")
                    .font(AppTypography.badge)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.8)
            }

            ZStack(alignment: .topLeading) {
                // Panel background
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColor.inkPanel)
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(
                        storyFieldFocused ? AppColor.comicYellow : AppColor.panelBorderStrong,
                        lineWidth: storyFieldFocused ? 2 : 1.5
                    )
                    .animation(.easeOut(duration: 0.2), value: storyFieldFocused)

                if flowStore.storyText.isEmpty {
                    Text("A hero wakes up in a city that has forgotten its past. She carries the last memory of what it used to be…")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textTertiary.opacity(0.6))
                        .padding(16)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $flowStore.storyText)
                    .focused($storyFieldFocused)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 240)
                    .padding(12)
            }

            Text("The longer and richer your story, the more detailed the comic.")
                .font(AppTypography.footnote)
                .foregroundStyle(AppColor.textTertiary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)
    }

    // ─── Bottom CTA ───────────────────────────────────────────────────────────
    private var bottomCTA: some View {
        VStack(spacing: 0) {
            // Top border
            Rectangle()
                .fill(AppColor.panelBorderStrong)
                .frame(height: 1.5)

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(flowStore.storyText.isEmpty ? "Add your story above" : "Looking good!")
                        .font(AppTypography.caption)
                        .foregroundStyle(flowStore.storyText.isEmpty ? AppColor.textTertiary : AppColor.comicYellow)
                    Text("Next: choose a style")
                        .font(AppTypography.badge)
                        .foregroundStyle(AppColor.textTertiary)
                        .tracking(0.8)
                }

                Spacer()

                Button {
                    storyFieldFocused = false
                    if viewModel.isStoryValid(flowStore.storyText) {
                        navigateToStyleSelection = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("NEXT")
                            .font(.system(size: 13, weight: .black))
                            .tracking(1.4)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .black))
                    }
                    .foregroundStyle(
                        viewModel.isStoryValid(flowStore.storyText)
                            ? AppColor.textOnLight
                            : AppColor.textTertiary
                    )
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(
                        viewModel.isStoryValid(flowStore.storyText)
                            ? AppColor.comicYellow
                            : AppColor.inkPanel
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(
                                viewModel.isStoryValid(flowStore.storyText)
                                    ? .clear
                                    : AppColor.panelBorder,
                                lineWidth: 1.5
                            )
                    )
                }
                .buttonStyle(InkPressStyle())
                .disabled(!viewModel.isStoryValid(flowStore.storyText))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .padding(.bottom, 20)
            .background(AppColor.inkDeep)
        }
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    StoryInputPreviewFactory.make()
}
#endif

private enum StoryInputPreviewFactory {
    @MainActor
    static func make() -> some View {
        let flowStore = CreateProjectFlowStore()
        flowStore.storyText = "A hero discovers a hidden city conspiracy while protecting loved ones."
        return StoryInputView(
            viewModel: StoryInputViewModel(),
            flowStore: flowStore,
            container: .preview()
        )
        .previewContainer()
    }
}
