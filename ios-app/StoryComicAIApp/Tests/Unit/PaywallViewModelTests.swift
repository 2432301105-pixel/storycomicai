import XCTest
@testable import StoryComicAIApp

@MainActor
final class PaywallViewModelTests: XCTestCase {
    func testOnAppearWithoutProjectIDLoadsFallbackContent() async {
        let packageService = MockComicPackageServiceForTests()
        let analytics = MockAnalyticsServiceForTests()
        let viewModel = PaywallViewModel(
            comicPackageService: packageService,
            analyticsService: analytics
        )

        viewModel.onAppear(projectID: nil)

        await AsyncTestHelpers.assertEventually {
            if case .loaded = viewModel.state {
                return true
            }
            return false
        }

        guard case let .loaded(content) = viewModel.state else {
            XCTFail("Expected loaded fallback content.")
            return
        }
        XCTAssertEqual(content.headline, "Unlock The Full Story")
        XCTAssertNil(analytics.events.first?.1[AnalyticsPropertyKey.projectID])
    }

    func testOnAppearTracksPaywallSeenOnlyOnce() async {
        let packageService = MockComicPackageServiceForTests()
        let analytics = MockAnalyticsServiceForTests()
        let viewModel = PaywallViewModel(
            comicPackageService: packageService,
            analyticsService: analytics
        )
        let projectID = UUID()

        viewModel.onAppear(projectID: projectID)
        viewModel.onAppear(projectID: projectID)

        await AsyncTestHelpers.assertEventually {
            if case .loaded = viewModel.state {
                return true
            }
            return false
        }

        let seenEvents = analytics.events.filter { $0.0 == .paywallSeen }
        XCTAssertEqual(seenEvents.count, 1)
        XCTAssertEqual(seenEvents.first?.1[AnalyticsPropertyKey.projectID], projectID.uuidString)
    }

    func testUnlockTracksStartedAndCompletedEvents() async {
        let packageService = MockComicPackageServiceForTests()
        let analytics = MockAnalyticsServiceForTests()
        let viewModel = PaywallViewModel(
            comicPackageService: packageService,
            analyticsService: analytics
        )
        let projectID = UUID()

        viewModel.onAppear(projectID: projectID)
        await AsyncTestHelpers.assertEventually {
            if case .loaded = viewModel.state {
                return true
            }
            return false
        }
        viewModel.selectedPlanID = "unlock_full_story"

        var completed = false
        viewModel.unlock(projectID: projectID) {
            completed = true
        }

        await AsyncTestHelpers.assertEventually {
            completed
        }

        XCTAssertTrue(analytics.events.contains { event, _ in event == .unlockStarted })
        XCTAssertTrue(analytics.events.contains { event, _ in event == .unlockCompleted })
    }

    func testLoadMapsPaywallMetadataAndCTAMetadata() async {
        let packageService = MockComicPackageServiceForTests()
        let analytics = MockAnalyticsServiceForTests()
        let package = packageService.package
        packageService.package = ComicBookPackage(
            projectID: package.projectID,
            title: package.title,
            subtitle: package.subtitle,
            styleLabel: package.styleLabel,
            cover: package.cover,
            pages: package.pages,
            previewPageCount: package.previewPageCount,
            presentationHints: package.presentationHints,
            exportAvailability: package.exportAvailability,
            paywallMetadata: ComicPaywallMetadata(
                isUnlocked: false,
                lockReason: "preview_limit",
                offers: [
                    ComicPaywallOffer(id: "unlock_full_story", price: "7.99", currency: "USD")
                ]
            ),
            ctaMetadata: ComicCTAMetadata(
                revealHeadline: "Unlock Your Story",
                revealSubheadline: "Continue reading your premium comic.",
                revealPrimaryLabel: "Unlock Now",
                revealSecondaryLabel: "Read Preview",
                exportLabel: "Export PDF"
            ),
            readingProgress: package.readingProgress,
            legacyRevealMetadata: package.legacyRevealMetadata,
            generationBlueprint: package.generationBlueprint,
            source: package.source
        )

        let viewModel = PaywallViewModel(
            comicPackageService: packageService,
            analyticsService: analytics
        )
        viewModel.onAppear(projectID: UUID())

        await AsyncTestHelpers.assertEventually {
            if case .loaded = viewModel.state {
                return true
            }
            return false
        }

        guard case let .loaded(content) = viewModel.state else {
            XCTFail("Expected loaded state.")
            return
        }
        XCTAssertEqual(content.headline, "Unlock Your Story")
        XCTAssertEqual(content.primaryButtonTitle, "Unlock Now")
        XCTAssertEqual(content.plans.first?.priceText, "7.99 USD")
    }

    func testPlansPreferUnlockOfferOverAddonWhenMetadataOrderIsMixed() async {
        let packageService = MockComicPackageServiceForTests()
        let analytics = MockAnalyticsServiceForTests()
        let package = packageService.package
        packageService.package = ComicBookPackage(
            projectID: package.projectID,
            title: package.title,
            subtitle: package.subtitle,
            styleLabel: package.styleLabel,
            cover: package.cover,
            pages: package.pages,
            previewPageCount: package.previewPageCount,
            presentationHints: package.presentationHints,
            exportAvailability: package.exportAvailability,
            paywallMetadata: ComicPaywallMetadata(
                isUnlocked: false,
                lockReason: "preview_limit",
                offers: [
                    ComicPaywallOffer(id: "premium_export_addon", price: "2.99", currency: "USD"),
                    ComicPaywallOffer(id: "unlock_full_story", price: "7.99", currency: "USD")
                ]
            ),
            ctaMetadata: package.ctaMetadata,
            readingProgress: package.readingProgress,
            legacyRevealMetadata: package.legacyRevealMetadata,
            generationBlueprint: package.generationBlueprint,
            source: package.source
        )

        let viewModel = PaywallViewModel(
            comicPackageService: packageService,
            analyticsService: analytics
        )
        viewModel.onAppear(projectID: UUID())

        await AsyncTestHelpers.assertEventually {
            if case .loaded = viewModel.state {
                return true
            }
            return false
        }

        guard case let .loaded(content) = viewModel.state else {
            XCTFail("Expected loaded state.")
            return
        }
        XCTAssertEqual(content.plans.first?.id, "unlock_full_story")
        XCTAssertEqual(content.plans.first?.isRecommended, true)
    }

    func testPlansRespectExplicitBackendPriorityAndRecommendation() async {
        let packageService = MockComicPackageServiceForTests()
        let analytics = MockAnalyticsServiceForTests()
        let package = packageService.package
        packageService.package = ComicBookPackage(
            projectID: package.projectID,
            title: package.title,
            subtitle: package.subtitle,
            styleLabel: package.styleLabel,
            cover: package.cover,
            pages: package.pages,
            previewPageCount: package.previewPageCount,
            presentationHints: package.presentationHints,
            exportAvailability: package.exportAvailability,
            paywallMetadata: ComicPaywallMetadata(
                isUnlocked: false,
                lockReason: "preview_limit",
                offers: [
                    ComicPaywallOffer(
                        id: "unlock_full_story",
                        price: "7.99",
                        currency: "USD",
                        priority: 20,
                        isRecommended: false,
                        badgeLabel: nil
                    ),
                    ComicPaywallOffer(
                        id: "annual_subscription",
                        price: "29.99",
                        currency: "USD",
                        priority: 10,
                        isRecommended: true,
                        badgeLabel: "Popular"
                    )
                ]
            ),
            ctaMetadata: package.ctaMetadata,
            readingProgress: package.readingProgress,
            legacyRevealMetadata: package.legacyRevealMetadata,
            generationBlueprint: package.generationBlueprint,
            source: package.source
        )

        let viewModel = PaywallViewModel(
            comicPackageService: packageService,
            analyticsService: analytics
        )
        viewModel.onAppear(projectID: UUID())

        await AsyncTestHelpers.assertEventually {
            if case .loaded = viewModel.state {
                return true
            }
            return false
        }

        guard case let .loaded(content) = viewModel.state else {
            XCTFail("Expected loaded state.")
            return
        }
        XCTAssertEqual(content.plans.first?.id, "annual_subscription")
        XCTAssertEqual(content.plans.first?.isRecommended, true)
        XCTAssertEqual(content.plans.first?.badgeLabel, "Popular")
    }
}
