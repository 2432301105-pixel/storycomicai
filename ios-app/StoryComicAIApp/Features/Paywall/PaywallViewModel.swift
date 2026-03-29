import Foundation

@MainActor
final class PaywallViewModel: ObservableObject {
    struct Plan: Identifiable, Equatable {
        let id: String
        let title: String
        let priceText: String
        let isRecommended: Bool
        let badgeLabel: String?
    }

    struct Content: Equatable {
        let headline: String
        let subheadline: String
        let lockReasonText: String
        let plans: [Plan]
        let primaryButtonTitle: String
    }

    @Published private(set) var state: LoadableState<Content> = .idle
    @Published private(set) var isUnlocking: Bool = false
    @Published var selectedPlanID: String?

    private let comicPackageService: any ComicPackageService
    private let analyticsService: any AnalyticsService
    private let source: String
    private var hasTrackedSeen: Bool = false
    private var loadTask: Task<Void, Never>?

    init(
        comicPackageService: any ComicPackageService,
        analyticsService: any AnalyticsService,
        source: String = "generation_flow"
    ) {
        self.comicPackageService = comicPackageService
        self.analyticsService = analyticsService
        self.source = source
    }

    deinit {
        loadTask?.cancel()
    }

    func onAppear(projectID: UUID?) {
        trackPaywallSeen(projectID: projectID)
        if case .idle = state {
            load(projectID: projectID)
        }
    }

    func retry(projectID: UUID?) {
        load(projectID: projectID)
    }

    func unlock(projectID: UUID?, onCompleted: @escaping () -> Void) {
        guard !isUnlocking else { return }
        let offerID = selectedPlanID ?? "unknown_offer"

        analyticsService.track(
            event: .unlockStarted,
            properties: unlockProperties(projectID: projectID, offerID: offerID)
        )

        isUnlocking = true
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard let self else { return }
            if Task.isCancelled { return }
            self.isUnlocking = false
            self.analyticsService.track(
                event: .unlockCompleted,
                properties: self.unlockProperties(projectID: projectID, offerID: offerID)
            )
            onCompleted()
        }
    }

    private func load(projectID: UUID?) {
        guard let projectID else {
            let fallback = Self.defaultContent()
            state = .loaded(fallback)
            selectedPlanID = selectedPlanID ?? fallback.plans.first?.id
            return
        }

        loadTask?.cancel()
        state = .loading

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let package = try await comicPackageService.fetchComicBookPackage(projectID: projectID)
                if Task.isCancelled { return }
                let content = Self.content(from: package)
                self.state = .loaded(content)
                self.selectedPlanID = self.selectedPlanID ?? content.plans.first?.id
            } catch {
                if Task.isCancelled { return }
                let fallback = Self.defaultContent()
                self.state = .loaded(fallback)
                self.selectedPlanID = self.selectedPlanID ?? fallback.plans.first?.id
            }
        }
    }

    private func trackPaywallSeen(projectID: UUID?) {
        guard !hasTrackedSeen else { return }
        hasTrackedSeen = true

        var properties: [String: String] = [AnalyticsPropertyKey.source: source]
        if let projectID {
            properties[AnalyticsPropertyKey.projectID] = projectID.uuidString
        }
        analyticsService.track(event: .paywallSeen, properties: properties)
    }

    private func unlockProperties(projectID: UUID?, offerID: String) -> [String: String] {
        var properties: [String: String] = [
            AnalyticsPropertyKey.offerID: offerID,
            AnalyticsPropertyKey.source: source
        ]
        if let projectID {
            properties[AnalyticsPropertyKey.projectID] = projectID.uuidString
        }
        return properties
    }

    private static func content(from package: ComicBookPackage) -> Content {
        let plans = plans(from: package.rankedPaywallOffers)
        return Content(
            headline: package.ctaMetadata.revealHeadline ?? "Unlock Full Story",
            subheadline: package.ctaMetadata.revealSubheadline ?? "Continue with your personalized comic experience.",
            lockReasonText: package.paywallLockReasonText,
            plans: plans,
            primaryButtonTitle: package.ctaMetadata.revealPrimaryLabel
        )
    }

    private static func plans(from offers: [ComicPaywallOffer]) -> [Plan] {
        if !offers.isEmpty {
            let hasExplicitRecommended = offers.contains { $0.isRecommended == true }
            return offers.enumerated().map { index, offer in
                Plan(
                    id: offer.id,
                    title: humanizedTitle(from: offer.id),
                    priceText: offer.formattedPriceText,
                    isRecommended: hasExplicitRecommended ? (offer.isRecommended ?? false) : index == 0,
                    badgeLabel: offer.badgeLabel
                )
            }
        }
        return defaultContent().plans
    }

    private static func defaultContent() -> Content {
        Content(
            headline: "Unlock The Full Story",
            subheadline: "Continue from your free preview and export your comic.",
            lockReasonText: "Free preview pages are complete.",
            plans: [
                Plan(
                    id: "unlock_full_story",
                    title: "Unlock Full Story",
                    priceText: "$7.99 USD",
                    isRecommended: true,
                    badgeLabel: "Best"
                ),
                Plan(
                    id: "premium_export_addon",
                    title: "HD Export Add-on",
                    priceText: "$2.99 USD",
                    isRecommended: false,
                    badgeLabel: nil
                )
            ],
            primaryButtonTitle: "Continue"
        )
    }

    private static func humanizedTitle(from rawID: String) -> String {
        rawID
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { token in token.prefix(1).uppercased() + token.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}
