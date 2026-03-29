import XCTest
@testable import StoryComicAIApp

@MainActor
final class ComicPresentationCoordinatorTests: XCTestCase {
    func testStartIfNeededLoadsPackageAndTracksRevealEvent() async {
        let service = MockComicPackageServiceForTests()
        let analytics = MockAnalyticsServiceForTests()
        let coordinator = ComicPresentationCoordinator(
            projectID: UUID(),
            comicPackageService: service,
            prefetcher: NoopReaderAssetPrefetcherForTests(),
            analyticsService: analytics,
            hapticProvider: MockHapticProviderForTests()
        )

        await coordinator.startIfNeeded()

        guard case let .loaded(package) = coordinator.packageState else {
            XCTFail("Expected loaded package state")
            return
        }
        XCTAssertFalse(package.pages.isEmpty)
        XCTAssertEqual(analytics.events.first?.0, .revealStarted)
    }

    func testOpenBookSwitchesToPreviewModeAndTracksEvent() async {
        let service = MockComicPackageServiceForTests()
        let analytics = MockAnalyticsServiceForTests()
        let haptics = MockHapticProviderForTests()
        let coordinator = ComicPresentationCoordinator(
            projectID: UUID(),
            comicPackageService: service,
            prefetcher: NoopReaderAssetPrefetcherForTests(),
            analyticsService: analytics,
            hapticProvider: haptics
        )

        await coordinator.startIfNeeded()
        coordinator.openBook()

        XCTAssertEqual(coordinator.mode, .preview)
        XCTAssertTrue(analytics.events.contains { $0.0 == .bookOpened })
        XCTAssertTrue(haptics.tokens.contains(.revealIntro))
    }

    func testCurrentPageIsSharedAcrossModes() async {
        let service = MockComicPackageServiceForTests()
        let coordinator = ComicPresentationCoordinator(
            projectID: UUID(),
            comicPackageService: service,
            prefetcher: NoopReaderAssetPrefetcherForTests(),
            analyticsService: MockAnalyticsServiceForTests(),
            hapticProvider: MockHapticProviderForTests()
        )

        await coordinator.startIfNeeded()
        coordinator.setCurrentPageIndex(2)
        coordinator.switchMode(.flatReader)
        coordinator.switchMode(.preview)

        XCTAssertEqual(coordinator.currentPageIndex, 2)
    }

    func testReadingProgressWriteBackIsDebounced() async {
        let service = MockComicPackageServiceForTests()
        let coordinator = ComicPresentationCoordinator(
            projectID: UUID(),
            comicPackageService: service,
            prefetcher: NoopReaderAssetPrefetcherForTests(),
            analyticsService: MockAnalyticsServiceForTests(),
            hapticProvider: MockHapticProviderForTests()
        )

        await coordinator.startIfNeeded()
        coordinator.setCurrentPageIndex(1)
        coordinator.setCurrentPageIndex(2)
        coordinator.setCurrentPageIndex(3)

        try? await Task.sleep(nanoseconds: 1_300_000_000)

        XCTAssertEqual(service.updateCalls.count, 1)
        XCTAssertEqual(service.updateCalls.first?.pageIndex, 3)
    }

    func testReadingProgressWriteBackSkipsWhenPageUnchanged() async {
        let service = MockComicPackageServiceForTests()
        let coordinator = ComicPresentationCoordinator(
            projectID: UUID(),
            comicPackageService: service,
            prefetcher: NoopReaderAssetPrefetcherForTests(),
            analyticsService: MockAnalyticsServiceForTests(),
            hapticProvider: MockHapticProviderForTests()
        )

        await coordinator.startIfNeeded()
        coordinator.setCurrentPageIndex(0)

        try? await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertTrue(service.updateCalls.isEmpty)
    }

    func testReadingProgressWriteBackCancelsWhenUserReturnsToPersistedPage() async {
        let service = MockComicPackageServiceForTests()
        let coordinator = ComicPresentationCoordinator(
            projectID: UUID(),
            comicPackageService: service,
            prefetcher: NoopReaderAssetPrefetcherForTests(),
            analyticsService: MockAnalyticsServiceForTests(),
            hapticProvider: MockHapticProviderForTests()
        )

        await coordinator.startIfNeeded()
        coordinator.setCurrentPageIndex(1)
        coordinator.setCurrentPageIndex(0)

        try? await Task.sleep(nanoseconds: 1_300_000_000)

        XCTAssertTrue(service.updateCalls.isEmpty)
    }

    func testPreviewPageTurnTracksAnalyticsPayload() async {
        let service = MockComicPackageServiceForTests()
        let analytics = MockAnalyticsServiceForTests()
        let coordinator = ComicPresentationCoordinator(
            projectID: UUID(),
            comicPackageService: service,
            prefetcher: NoopReaderAssetPrefetcherForTests(),
            analyticsService: analytics,
            hapticProvider: MockHapticProviderForTests()
        )

        await coordinator.startIfNeeded()
        coordinator.openBook()
        coordinator.setCurrentPageIndex(1)

        guard let event = analytics.events.last(where: { $0.0 == .previewPageTurned }) else {
            XCTFail("Expected preview_page_turned analytics event.")
            return
        }

        XCTAssertEqual(event.1[AnalyticsPropertyKey.fromPageIndex], "0")
        XCTAssertEqual(event.1[AnalyticsPropertyKey.toPageIndex], "1")
        XCTAssertEqual(event.1[AnalyticsPropertyKey.mode], ComicPresentationMode.preview.rawValue)
    }

    func testSwitchToFlatReaderTracksDedicatedEvent() async {
        let service = MockComicPackageServiceForTests()
        let analytics = MockAnalyticsServiceForTests()
        let coordinator = ComicPresentationCoordinator(
            projectID: UUID(),
            comicPackageService: service,
            prefetcher: NoopReaderAssetPrefetcherForTests(),
            analyticsService: analytics,
            hapticProvider: MockHapticProviderForTests()
        )

        await coordinator.startIfNeeded()
        coordinator.openBook()
        coordinator.switchMode(.flatReader)

        guard let event = analytics.events.last(where: { $0.0 == .switchedToFlatReader }) else {
            XCTFail("Expected switched_to_flat_reader event.")
            return
        }
        XCTAssertEqual(event.1[AnalyticsPropertyKey.fromMode], ComicPresentationMode.preview.rawValue)
        XCTAssertEqual(event.1[AnalyticsPropertyKey.mode], ComicPresentationMode.flatReader.rawValue)
    }

    func testSwitchModeToSameValueDoesNotTrackDuplicateEvent() async {
        let service = MockComicPackageServiceForTests()
        let analytics = MockAnalyticsServiceForTests()
        let coordinator = ComicPresentationCoordinator(
            projectID: UUID(),
            comicPackageService: service,
            prefetcher: NoopReaderAssetPrefetcherForTests(),
            analyticsService: analytics,
            hapticProvider: MockHapticProviderForTests()
        )

        await coordinator.startIfNeeded()
        coordinator.switchMode(.reveal)

        XCTAssertFalse(analytics.events.contains { $0.0 == .modeSwitched })
    }
}
