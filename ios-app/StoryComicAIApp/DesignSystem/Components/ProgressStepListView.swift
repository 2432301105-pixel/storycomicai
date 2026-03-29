import SwiftUI

struct ProgressStepListView: View {
    let steps: [GenerationPipelineStep]

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(steps) { step in
                HStack(spacing: AppSpacing.sm) {
                    Circle()
                        .fill(color(for: step.status))
                        .frame(width: 10, height: 10)

                    Text(step.title)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textPrimary)

                    Spacer()

                    Text(step.status.title)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .padding(.vertical, AppSpacing.xs)
            }
        }
    }

    private func color(for status: GenerationPipelineStep.StepStatus) -> Color {
        switch status {
        case .pending:
            return AppColor.border
        case .active:
            return AppColor.accent
        case .completed:
            return AppColor.success
        case .failed:
            return AppColor.error
        }
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    ProgressStepListView(steps: GenerationPipelineStep.previewSteps)
        .padding()
        .background(AppColor.backgroundPrimary)
}
#endif
