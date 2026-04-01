import Foundation

@MainActor
final class ComicPresentationCoordinator: ObservableObject {
    @Published private(set) var packageState: LoadableState<ComicBookPackage> = .idle
    @Published private(set) var mode: ComicPresentationMode
    @Published private(set) var currentPageIndex: Int = 0
    @Published private(set) var isPrefetchingAssets: Bool = false

    let projectID: UUID

    private let comicPackageService: any ComicPackageService
    private let prefetcher: any ReaderAssetPrefetching
    private let analyticsService: any AnalyticsService
    private let hapticProvider: HapticProviding
    private let storyText: String?

    private var hasStarted: Bool = false
    private var prefetchTask: Task<Void, Never>?
    private var progressWriteTask: Task<Void, Never>?
    private var lastPersistedPageIndex: Int?

    private enum Constants {
        static let readingProgressDebounceNanos: UInt64 = 900_000_000
    }

    init(
        projectID: UUID,
        comicPackageService: any ComicPackageService,
        prefetcher: any ReaderAssetPrefetching = DefaultReaderAssetPrefetcher(),
        analyticsService: any AnalyticsService,
        storyText: String? = nil,
        hapticProvider: HapticProviding = SystemHapticProvider(),
        initialMode: ComicPresentationMode = .reveal
    ) {
        self.projectID = projectID
        self.comicPackageService = comicPackageService
        self.prefetcher = prefetcher
        self.analyticsService = analyticsService
        self.storyText = storyText
        self.hapticProvider = hapticProvider
        self.mode = initialMode
    }

    deinit {
        prefetchTask?.cancel()
        progressWriteTask?.cancel()
    }

    func startIfNeeded() async {
        guard !hasStarted else { return }
        hasStarted = true
        await loadPackage()
    }

    func retry() async {
        hasStarted = false
        packageState = .idle
        await startIfNeeded()
    }

    func openBook() {
        hapticProvider.trigger(.revealIntro)
        analyticsService.track(
            event: .bookOpened,
            properties: analyticsProperties(extra: [AnalyticsPropertyKey.projectID: projectID.uuidString])
        )
        switchMode(.preview)
    }

    func openFlatReader() {
        switchMode(.flatReader)
    }

    func openExport() {
        trackExportTap(action: "open_export_mode")
        switchMode(.export)
    }

    func trackExportTap(action: String) {
        analyticsService.track(
            event: .exportTapped,
            properties: analyticsProperties(
                extra: [
                    AnalyticsPropertyKey.projectID: projectID.uuidString,
                    AnalyticsPropertyKey.action: action
                ]
            )
        )
    }

    func switchMode(_ newMode: ComicPresentationMode) {
        guard mode != newMode else { return }
        let previous = mode
        mode = newMode
        hapticProvider.trigger(.modeSwitch)
        analyticsService.track(
            event: .modeSwitched,
            properties: analyticsProperties(
                extra: [
                    AnalyticsPropertyKey.fromMode: previous.rawValue,
                    AnalyticsPropertyKey.toMode: newMode.rawValue,
                    AnalyticsPropertyKey.projectID: projectID.uuidString
                ]
            )
        )
        if newMode == .flatReader {
            analyticsService.track(
                event: .switchedToFlatReader,
                properties: analyticsProperties(
                    extra: [
                        AnalyticsPropertyKey.projectID: projectID.uuidString,
                        AnalyticsPropertyKey.fromMode: previous.rawValue
                    ]
                )
            )
        }
    }

    func setCurrentPageIndex(_ index: Int) {
        guard let totalPages = package?.pages.count, totalPages > 0 else { return }
        let previousIndex = currentPageIndex
        let boundedIndex = max(0, min(index, totalPages - 1))
        guard boundedIndex != currentPageIndex else { return }
        currentPageIndex = boundedIndex
        hapticProvider.trigger(.pageTurn)
        prefetchAroundCurrentPage()
        scheduleReadingProgressWriteBack(for: boundedIndex)
        if mode == .preview || mode == .flatReader {
            analyticsService.track(
                event: .previewPageTurned,
                properties: analyticsProperties(
                    extra: [
                        AnalyticsPropertyKey.projectID: projectID.uuidString,
                        AnalyticsPropertyKey.fromPageIndex: "\(previousIndex)",
                        AnalyticsPropertyKey.toPageIndex: "\(boundedIndex)",
                        AnalyticsPropertyKey.totalPages: "\(totalPages)"
                    ]
                )
            )
        }
    }

    func goToNextPage() {
        setCurrentPageIndex(currentPageIndex + 1)
    }

    func goToPreviousPage() {
        setCurrentPageIndex(currentPageIndex - 1)
    }

    var package: ComicBookPackage? {
        if case let .loaded(package) = packageState {
            return package
        }
        return nil
    }

    var currentPage: ComicPresentationPage? {
        guard let package else { return nil }
        guard package.pages.indices.contains(currentPageIndex) else { return nil }
        return package.pages[currentPageIndex]
    }

    var canGoNext: Bool {
        guard let package else { return false }
        return currentPageIndex < package.pages.count - 1
    }

    var canGoPrevious: Bool {
        currentPageIndex > 0
    }

    private func loadPackage() async {
        packageState = .loading
        analyticsService.track(
            event: .revealStarted,
            properties: analyticsProperties(extra: [AnalyticsPropertyKey.projectID: projectID.uuidString])
        )

        do {
            let fetchedPackage = try await comicPackageService.fetchComicBookPackage(projectID: projectID)
            let package = fetchedPackage.personalized(with: storyText)
            currentPageIndex = max(0, min(package.readingProgress.currentPageIndex, package.pages.count - 1))
            lastPersistedPageIndex = currentPageIndex
            packageState = .loaded(package)
            prefetchAroundCurrentPage()
        } catch {
            packageState = .failed(error.userFacingMessage)
        }
    }

    private func prefetchAroundCurrentPage() {
        guard let pages = package?.pages, !pages.isEmpty else { return }
        prefetchTask?.cancel()
        isPrefetchingAssets = true
        let prefetcher = self.prefetcher
        let index = self.currentPageIndex

        prefetchTask = Task { [weak self] in
            await prefetcher.prefetch(pages: pages, around: index)
            guard let self else { return }
            if Task.isCancelled { return }
            await MainActor.run {
                self.isPrefetchingAssets = false
            }
        }
    }

    private func analyticsProperties(extra: [String: String]) -> [String: String] {
        var properties: [String: String] = [AnalyticsPropertyKey.mode: mode.rawValue]
        for (key, value) in extra {
            properties[key] = value
        }
        return properties
    }

    private func scheduleReadingProgressWriteBack(for pageIndex: Int) {
        progressWriteTask?.cancel()
        guard package != nil else { return }
        guard pageIndex != lastPersistedPageIndex else { return }

        let service = comicPackageService
        let projectID = self.projectID

        progressWriteTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: Constants.readingProgressDebounceNanos)
                if Task.isCancelled { return }
                let progress = try await service.updateReadingProgress(
                    projectID: projectID,
                    currentPageIndex: pageIndex,
                    lastOpenedAtUTC: Date()
                )
                if Task.isCancelled { return }
                await MainActor.run {
                    self?.lastPersistedPageIndex = progress.currentPageIndex
                }
            } catch is CancellationError {
                return
            } catch {
                // Non-blocking path. Reading remains local even if write-back fails.
            }
        }
    }
}
