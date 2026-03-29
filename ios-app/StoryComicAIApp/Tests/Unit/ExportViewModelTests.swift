import XCTest
@testable import StoryComicAIApp

@MainActor
final class ExportViewModelTests: XCTestCase {
    func testStartExportTransitionsToReady() async {
        let packageService = MockComicPackageServiceForTests()
        let exportService = MockExportServiceForTests()
        let analytics = MockAnalyticsServiceForTests()
        let coordinator = ComicPresentationCoordinator(
            projectID: UUID(),
            comicPackageService: packageService,
            prefetcher: NoopReaderAssetPrefetcherForTests(),
            analyticsService: analytics,
            hapticProvider: MockHapticProviderForTests(),
            initialMode: .export
        )
        await coordinator.startIfNeeded()

        let viewModel = ExportViewModel(coordinator: coordinator, exportService: exportService)
        viewModel.selectedType = .pdf
        viewModel.startExport()

        await AsyncTestHelpers.assertEventually {
            if case .ready = viewModel.state { return true }
            return false
        }
    }

    func testPrepareShareTransitionsToSharingState() async {
        let packageService = MockComicPackageServiceForTests()
        let exportService = MockExportServiceForTests()
        let coordinator = ComicPresentationCoordinator(
            projectID: UUID(),
            comicPackageService: packageService,
            prefetcher: NoopReaderAssetPrefetcherForTests(),
            analyticsService: MockAnalyticsServiceForTests(),
            hapticProvider: MockHapticProviderForTests(),
            initialMode: .export
        )
        await coordinator.startIfNeeded()

        let jobID = UUID()
        exportService.createResult = ComicExportJob(
            jobID: jobID,
            projectID: coordinator.projectID,
            type: .pdf,
            status: .queued,
            progressPct: 0,
            artifactURL: nil,
            errorCode: nil,
            errorMessage: nil,
            retryable: true
        )
        exportService.statusSequence = [
            ComicExportJob(
                jobID: jobID,
                projectID: coordinator.projectID,
                type: .pdf,
                status: .succeeded,
                progressPct: 100,
                artifactURL: URL(string: "https://mock.storycomicai.local/exports/final.pdf"),
                errorCode: nil,
                errorMessage: nil,
                retryable: true
            )
        ]

        let viewModel = ExportViewModel(coordinator: coordinator, exportService: exportService)
        viewModel.startExport()

        await AsyncTestHelpers.assertEventually {
            if case .ready = viewModel.state { return true }
            return false
        }

        viewModel.prepareShare()

        await AsyncTestHelpers.assertEventually {
            if case .sharing = viewModel.state { return true }
            return false
        }

        XCTAssertNotNil(viewModel.shareSheetURL)
    }

    func testStartExportDoesNotCallServiceWhenPaywallLocked() async {
        let packageService = MockComicPackageServiceForTests()
        let basePackage = packageService.package
        packageService.package = ComicBookPackage(
            projectID: basePackage.projectID,
            title: basePackage.title,
            subtitle: basePackage.subtitle,
            styleLabel: basePackage.styleLabel,
            cover: basePackage.cover,
            pages: basePackage.pages,
            previewPageCount: basePackage.previewPageCount,
            presentationHints: basePackage.presentationHints,
            exportAvailability: ComicExportAvailability(
                isPDFAvailable: false,
                pdfURL: nil,
                isImagePackAvailable: false,
                lockedByPaywall: true
            ),
            paywallMetadata: ComicPaywallMetadata(
                isUnlocked: false,
                lockReason: "preview_limit",
                offers: basePackage.paywallMetadata.offers
            ),
            ctaMetadata: basePackage.ctaMetadata,
            readingProgress: basePackage.readingProgress,
            legacyRevealMetadata: basePackage.legacyRevealMetadata,
            source: basePackage.source
        )
        let exportService = MockExportServiceForTests()
        let coordinator = ComicPresentationCoordinator(
            projectID: UUID(),
            comicPackageService: packageService,
            prefetcher: NoopReaderAssetPrefetcherForTests(),
            analyticsService: MockAnalyticsServiceForTests(),
            hapticProvider: MockHapticProviderForTests(),
            initialMode: .export
        )
        await coordinator.startIfNeeded()

        let viewModel = ExportViewModel(coordinator: coordinator, exportService: exportService)
        viewModel.startExport()

        if case let .failed(_, retryable) = viewModel.state {
            XCTAssertFalse(retryable)
        } else {
            XCTFail("Expected non-retryable failed state for paywall lock.")
        }
        XCTAssertEqual(exportService.createCalls, 0)
    }

    func testChangingSelectedTypeResetsReadyStateToIdle() async {
        let packageService = MockComicPackageServiceForTests()
        let exportService = MockExportServiceForTests()
        let coordinator = ComicPresentationCoordinator(
            projectID: UUID(),
            comicPackageService: packageService,
            prefetcher: NoopReaderAssetPrefetcherForTests(),
            analyticsService: MockAnalyticsServiceForTests(),
            hapticProvider: MockHapticProviderForTests(),
            initialMode: .export
        )
        await coordinator.startIfNeeded()

        let jobID = UUID()
        exportService.createResult = ComicExportJob(
            jobID: jobID,
            projectID: coordinator.projectID,
            type: .pdf,
            status: .queued,
            progressPct: nil,
            artifactURL: nil,
            errorCode: nil,
            errorMessage: nil,
            retryable: true
        )
        exportService.statusSequence = [
            ComicExportJob(
                jobID: jobID,
                projectID: coordinator.projectID,
                type: .pdf,
                status: .succeeded,
                progressPct: 100,
                artifactURL: URL(string: "https://mock.storycomicai.local/exports/final.pdf"),
                errorCode: nil,
                errorMessage: nil,
                retryable: true
            )
        ]

        let viewModel = ExportViewModel(coordinator: coordinator, exportService: exportService)
        viewModel.startExport()

        await AsyncTestHelpers.assertEventually {
            if case .ready = viewModel.state { return true }
            return false
        }

        viewModel.selectedType = .imageBundle

        if case .idle = viewModel.state {
            // expected
        } else {
            XCTFail("Expected idle state after changing export type from ready state.")
        }
    }

    func testCreateExportErrorMapsToNonRetryableFailedState() async {
        let packageService = MockComicPackageServiceForTests()
        let exportService = MockExportServiceForTests()
        exportService.createError = ExportServiceError.paywallLocked

        let coordinator = ComicPresentationCoordinator(
            projectID: UUID(),
            comicPackageService: packageService,
            prefetcher: NoopReaderAssetPrefetcherForTests(),
            analyticsService: MockAnalyticsServiceForTests(),
            hapticProvider: MockHapticProviderForTests(),
            initialMode: .export
        )
        await coordinator.startIfNeeded()

        let viewModel = ExportViewModel(coordinator: coordinator, exportService: exportService)
        viewModel.startExport()

        await AsyncTestHelpers.assertEventually {
            if case let .failed(_, retryable) = viewModel.state {
                return retryable == false
            }
            return false
        }
    }

    func testDidDismissShareSheetCleansUpTemporaryFile() async throws {
        let packageService = MockComicPackageServiceForTests()
        let exportService = MockExportServiceForTests()
        let coordinator = ComicPresentationCoordinator(
            projectID: UUID(),
            comicPackageService: packageService,
            prefetcher: NoopReaderAssetPrefetcherForTests(),
            analyticsService: MockAnalyticsServiceForTests(),
            hapticProvider: MockHapticProviderForTests(),
            initialMode: .export
        )
        await coordinator.startIfNeeded()

        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("storycomicai-export-test-\(UUID().uuidString).pdf")
        try Data("mock".utf8).write(to: tempFileURL)
        exportService.downloadedURL = tempFileURL

        let jobID = UUID()
        exportService.createResult = ComicExportJob(
            jobID: jobID,
            projectID: coordinator.projectID,
            type: .pdf,
            status: .queued,
            progressPct: nil,
            artifactURL: nil,
            errorCode: nil,
            errorMessage: nil,
            retryable: true
        )
        exportService.statusSequence = [
            ComicExportJob(
                jobID: jobID,
                projectID: coordinator.projectID,
                type: .pdf,
                status: .succeeded,
                progressPct: 100,
                artifactURL: URL(string: "https://mock.storycomicai.local/exports/final.pdf"),
                errorCode: nil,
                errorMessage: nil,
                retryable: true
            )
        ]

        let viewModel = ExportViewModel(coordinator: coordinator, exportService: exportService)
        viewModel.startExport()
        await AsyncTestHelpers.assertEventually {
            if case .ready = viewModel.state { return true }
            return false
        }

        viewModel.prepareShare()
        await AsyncTestHelpers.assertEventually {
            if case .sharing = viewModel.state { return true }
            return false
        }

        XCTAssertNotNil(viewModel.shareSheetURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFileURL.path))

        viewModel.didDismissShareSheet()

        XCTAssertNil(viewModel.shareSheetURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempFileURL.path))
        if case .ready = viewModel.state {
            // expected
        } else {
            XCTFail("Expected ready state after share sheet dismissal.")
        }
    }

    func testStartExportRetriesTransientCreateFailures() async {
        let packageService = MockComicPackageServiceForTests()
        let exportService = MockExportServiceForTests()
        exportService.createErrors = [
            ExportServiceError.temporarilyUnavailable,
            ExportServiceError.generationNotReady
        ]

        let coordinator = ComicPresentationCoordinator(
            projectID: UUID(),
            comicPackageService: packageService,
            prefetcher: NoopReaderAssetPrefetcherForTests(),
            analyticsService: MockAnalyticsServiceForTests(),
            hapticProvider: MockHapticProviderForTests(),
            initialMode: .export
        )
        await coordinator.startIfNeeded()

        let viewModel = ExportViewModel(coordinator: coordinator, exportService: exportService)
        viewModel.startExport()

        await AsyncTestHelpers.assertEventually {
            if case .ready = viewModel.state { return true }
            return false
        }

        XCTAssertEqual(exportService.createCalls, 3)
    }
}
