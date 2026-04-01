import SwiftUI

struct ComicPresentationCoordinatorView: View {
    @StateObject private var coordinator: ComicPresentationCoordinator
    private let exportService: any ExportService
    @Environment(\.dismiss) private var dismiss

    init(
        projectID: UUID,
        container: AppContainer,
        initialMode: ComicPresentationMode = .reveal,
        storyText: String? = nil
    ) {
        self.exportService = container.exportService
        _coordinator = StateObject(
            wrappedValue: ComicPresentationCoordinator(
                projectID: projectID,
                comicPackageService: container.comicPackageService,
                prefetcher: container.readerAssetPrefetcher,
                analyticsService: container.analyticsService,
                storyText: storyText,
                initialMode: initialMode
            )
        )
    }

    var body: some View {
        ZStack {
            switch coordinator.mode {
            case .reveal:
                BookRevealView(coordinator: coordinator)

            case .preview:
                BookPreviewView(coordinator: coordinator)

            case .flatReader:
                FlatReaderView(coordinator: coordinator)

            case .export:
                ExportView(coordinator: coordinator, exportService: exportService)
            }
        }
        .ignoresSafeArea()
        .safeAreaInset(edge: .top, spacing: 0) {
            presentationTopBar
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await coordinator.startIfNeeded()
        }
    }

    private var navigationTitle: String {
        if case let .loaded(package) = coordinator.packageState {
            return package.title
        }
        return "Comic"
    }

    private var presentationTopBar: some View {
        HStack(spacing: AppSpacing.md) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppColor.surfaceElevated.opacity(0.94))
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(AppColor.border.opacity(0.9), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Text(navigationTitle)
                .font(AppTypography.heading)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.md)
        .background(
            ZStack {
                AppColor.backgroundPrimary.opacity(0.98)
                LinearGradient(
                    colors: [AppColor.backgroundPrimary.opacity(0.98), AppColor.backgroundPrimary.opacity(0.86)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppColor.border.opacity(0.7))
                    .frame(height: 1)
            }
            .ignoresSafeArea(edges: .top)
        )
    }
}

#if !CI_DISABLE_PREVIEWS
struct ComicPresentationCoordinatorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ComicPresentationCoordinatorView(projectID: UUID(), container: .preview())
        }
        .previewContainer()
    }
}
#endif
