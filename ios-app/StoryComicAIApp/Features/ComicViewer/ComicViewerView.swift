import SwiftUI

struct ComicViewerView: View {
    @StateObject var viewModel: ComicViewerViewModel

    var body: some View {
        TabView {
            ForEach(viewModel.pages) { page in
                CardContainer {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Page \(page.pageNumber)")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.textSecondary)

                        Text(page.title)
                            .font(AppTypography.heading)
                            .foregroundStyle(AppColor.textPrimary)

                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColor.backgroundSecondary)
                            .frame(height: 280)
                            .overlay {
                                Image(systemName: "rectangle.stack.person.crop")
                                    .font(.system(size: 42))
                                    .foregroundStyle(AppColor.textSecondary)
                            }

                        Text(page.caption)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                .padding(AppSpacing.lg)
                .background(AppColor.backgroundPrimary)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Comic Viewer")
    }
}

#if !CI_DISABLE_PREVIEWS
#Preview {
    ComicViewerView(viewModel: ComicViewerViewModel())
        .previewContainer()
}
#endif
