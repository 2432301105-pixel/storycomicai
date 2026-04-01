import SwiftUI

struct ComicPresentationCoordinatorView: View {
    @StateObject private var coordinator: ComicPresentationCoordinator
    private let exportService: any ExportService

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
        Group {
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
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
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
