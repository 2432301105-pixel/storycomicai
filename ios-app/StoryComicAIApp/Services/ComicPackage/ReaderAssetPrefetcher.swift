import Foundation

struct ReaderAssetCachePolicy {
    let thumbnailPrefetchRadius: Int
    let fullPrefetchRadius: Int
    let thumbnailTargetPixelSize: CGFloat
    let fullTargetPixelSize: CGFloat
    let allowsNetworkPrefetch: Bool

    static func standard(processInfo: ProcessInfo = .processInfo) -> ReaderAssetCachePolicy {
        if processInfo.isLowPowerModeEnabled {
            return ReaderAssetCachePolicy(
                thumbnailPrefetchRadius: 2,
                fullPrefetchRadius: 0,
                thumbnailTargetPixelSize: 720,
                fullTargetPixelSize: 1_280,
                allowsNetworkPrefetch: true
            )
        }

        return ReaderAssetCachePolicy(
            thumbnailPrefetchRadius: 3,
            fullPrefetchRadius: 1,
            thumbnailTargetPixelSize: 960,
            fullTargetPixelSize: 1_800,
            allowsNetworkPrefetch: true
        )
    }
}

protocol ReaderAssetPrefetching: Actor {
    func prefetch(pages: [ComicPresentationPage], around index: Int) async
    func clear() async
}

actor DefaultReaderAssetPrefetcher: ReaderAssetPrefetching {
    private let cachePolicy: ReaderAssetCachePolicy
    private let imagePipeline: any ReaderImagePipelining
    private let telemetry: (any ReaderPerformanceTelemetry)?

    init(
        cachePolicy: ReaderAssetCachePolicy = .standard(),
        imagePipeline: any ReaderImagePipelining = ReaderImagePipeline.shared,
        telemetry: (any ReaderPerformanceTelemetry)? = nil
    ) {
        self.cachePolicy = cachePolicy
        self.imagePipeline = imagePipeline
        self.telemetry = telemetry
    }

    func prefetch(pages: [ComicPresentationPage], around index: Int) async {
        guard !pages.isEmpty else { return }
        let safeIndex = max(0, min(index, pages.count - 1))
        let thumbnailLowerBound = max(0, safeIndex - cachePolicy.thumbnailPrefetchRadius)
        let thumbnailUpperBound = min(pages.count - 1, safeIndex + cachePolicy.thumbnailPrefetchRadius)
        let fullLowerBound = max(0, safeIndex - cachePolicy.fullPrefetchRadius)
        let fullUpperBound = min(pages.count - 1, safeIndex + cachePolicy.fullPrefetchRadius)

        telemetry?.record(
            event: ReaderTelemetryEvent(
                kind: .prefetchWindow,
                scope: "reader_prefetch",
                properties: [
                    AnalyticsPropertyKey.success: "true",
                    AnalyticsPropertyKey.targetPixels: "\(Int(cachePolicy.fullTargetPixelSize))",
                    AnalyticsPropertyKey.pageIndex: "\(safeIndex)",
                    AnalyticsPropertyKey.pagesCount: "\(pages.count)",
                    AnalyticsPropertyKey.thumbnailRadius: "\(cachePolicy.thumbnailPrefetchRadius)",
                    AnalyticsPropertyKey.fullRadius: "\(cachePolicy.fullPrefetchRadius)"
                ]
            )
        )

        var queuedURLs = Set<URL>()

        if fullLowerBound <= fullUpperBound {
            for pageIndex in fullLowerBound...fullUpperBound {
                let page = pages[pageIndex]
                guard let url = page.fullImageURL ?? page.thumbnailURL else { continue }
                guard queuedURLs.insert(url).inserted else { continue }
                await imagePipeline.prefetch(
                    url: url,
                    targetPixelSize: cachePolicy.fullTargetPixelSize,
                    allowsNetwork: cachePolicy.allowsNetworkPrefetch
                )
            }
        }

        if thumbnailLowerBound <= thumbnailUpperBound {
            for pageIndex in thumbnailLowerBound...thumbnailUpperBound {
                if pageIndex >= fullLowerBound, pageIndex <= fullUpperBound { continue }
                let page = pages[pageIndex]
                guard let url = page.thumbnailURL ?? page.fullImageURL else { continue }
                guard queuedURLs.insert(url).inserted else { continue }
                await imagePipeline.prefetch(
                    url: url,
                    targetPixelSize: cachePolicy.thumbnailTargetPixelSize,
                    allowsNetwork: cachePolicy.allowsNetworkPrefetch
                )
            }
        }
    }

    func clear() async {
        await imagePipeline.clear()
    }
}
