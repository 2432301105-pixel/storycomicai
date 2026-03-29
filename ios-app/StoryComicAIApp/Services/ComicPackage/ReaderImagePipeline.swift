import Foundation
import ImageIO
import UIKit

enum ReaderImageRequestPurpose: String {
    case display
    case prefetch
}

struct ReaderImagePipelinePolicy {
    let maxCacheItems: Int
    let maxCacheBytes: Int
    let requestTimeout: TimeInterval
    let conservativeNetwork: Bool

    static func standard(processInfo: ProcessInfo = .processInfo) -> ReaderImagePipelinePolicy {
        let isThermalConstrained: Bool = {
            switch processInfo.thermalState {
            case .serious, .critical:
                return true
            case .nominal, .fair:
                return false
            @unknown default:
                return true
            }
        }()

        if processInfo.isLowPowerModeEnabled || isThermalConstrained {
            return ReaderImagePipelinePolicy(
                maxCacheItems: 40,
                maxCacheBytes: 32 * 1024 * 1024,
                requestTimeout: 18,
                conservativeNetwork: true
            )
        }
        return ReaderImagePipelinePolicy(
            maxCacheItems: 80,
            maxCacheBytes: 64 * 1024 * 1024,
            requestTimeout: 24,
            conservativeNetwork: false
        )
    }
}

protocol ReaderImagePipelining: Actor {
    func image(
        url: URL,
        targetPixelSize: CGFloat,
        allowsNetwork: Bool,
        purpose: ReaderImageRequestPurpose
    ) async -> UIImage?
    func prefetch(url: URL, targetPixelSize: CGFloat, allowsNetwork: Bool) async
    func setTelemetry(_ telemetry: any ReaderPerformanceTelemetry) async
    func clear() async
}

actor ReaderImagePipeline: ReaderImagePipelining {
    static let shared = ReaderImagePipeline()

    private let policy: ReaderImagePipelinePolicy
    private let session: URLSession
    private let cache = NSCache<NSString, UIImage>()
    private var inFlightTasks: [String: Task<UIImage?, Never>] = [:]
    private var telemetry: (any ReaderPerformanceTelemetry)?
    private var consecutiveFailures: Int = 0
    private var prefetchNetworkThrottledUntil: Date?

    private enum RuntimeTuning {
        static let failureThresholdForPrefetchThrottle = 3
        static let prefetchThrottleDurationSeconds: TimeInterval = 45
    }

    init(
        policy: ReaderImagePipelinePolicy = .standard(),
        session: URLSession = .shared
    ) {
        self.policy = policy
        self.session = session
        cache.countLimit = policy.maxCacheItems
        cache.totalCostLimit = policy.maxCacheBytes
    }

    func image(
        url: URL,
        targetPixelSize: CGFloat,
        allowsNetwork: Bool = true,
        purpose: ReaderImageRequestPurpose = .display
    ) async -> UIImage? {
        let startedAt = Date()
        let pixelSize = max(64, Int(targetPixelSize.rounded(.up)))
        let key = cacheKey(url: url, pixelSize: pixelSize)

        if let cached = cache.object(forKey: key as NSString) {
            track(
                kind: .imageLoad,
                scope: purpose.rawValue,
                properties: [
                    AnalyticsPropertyKey.cacheHit: "true",
                    AnalyticsPropertyKey.success: "true",
                    AnalyticsPropertyKey.targetPixels: "\(pixelSize)",
                    AnalyticsPropertyKey.durationMs: "\(elapsedMilliseconds(since: startedAt))",
                    AnalyticsPropertyKey.networkPolicy: policy.conservativeNetwork ? "conservative" : "standard",
                    AnalyticsPropertyKey.networkThrottled: isPrefetchNetworkThrottled ? "true" : "false",
                    AnalyticsPropertyKey.failureStreak: "\(consecutiveFailures)"
                ]
            )
            return cached
        }

        if let existingTask = inFlightTasks[key] {
            return await existingTask.value
        }

        if purpose == .prefetch, isPrefetchNetworkThrottled {
            track(
                kind: .imageLoad,
                scope: purpose.rawValue,
                properties: [
                    AnalyticsPropertyKey.cacheHit: "false",
                    AnalyticsPropertyKey.success: "false",
                    AnalyticsPropertyKey.targetPixels: "\(pixelSize)",
                    AnalyticsPropertyKey.durationMs: "\(elapsedMilliseconds(since: startedAt))",
                    AnalyticsPropertyKey.networkPolicy: policy.conservativeNetwork ? "conservative" : "standard",
                    AnalyticsPropertyKey.networkThrottled: "true",
                    AnalyticsPropertyKey.failureStreak: "\(consecutiveFailures)"
                ]
            )
            return nil
        }

        guard allowsNetwork else { return nil }

        let policy = self.policy
        let session = self.session
        let task = Task<UIImage?, Never>(priority: .utility) {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            request.timeoutInterval = policy.requestTimeout
            request.allowsConstrainedNetworkAccess = !policy.conservativeNetwork
            request.allowsExpensiveNetworkAccess = !policy.conservativeNetwork

            do {
                let (data, response) = try await session.data(for: request)
                if let response = response as? HTTPURLResponse,
                   !(200..<300).contains(response.statusCode) {
                    return nil
                }
                return Self.downsampleImage(data: data, maxPixelSize: pixelSize)
            } catch {
                return nil
            }
        }

        inFlightTasks[key] = task
        let result = await task.value
        inFlightTasks[key] = nil

        if let result {
            cache.setObject(result, forKey: key as NSString, cost: result.cacheCost)
            consecutiveFailures = 0
            prefetchNetworkThrottledUntil = nil
            track(
                kind: .imageLoad,
                scope: purpose.rawValue,
                properties: [
                    AnalyticsPropertyKey.cacheHit: "false",
                    AnalyticsPropertyKey.success: "true",
                    AnalyticsPropertyKey.targetPixels: "\(pixelSize)",
                    AnalyticsPropertyKey.durationMs: "\(elapsedMilliseconds(since: startedAt))",
                    AnalyticsPropertyKey.networkPolicy: policy.conservativeNetwork ? "conservative" : "standard",
                    AnalyticsPropertyKey.networkThrottled: isPrefetchNetworkThrottled ? "true" : "false",
                    AnalyticsPropertyKey.failureStreak: "\(consecutiveFailures)"
                ]
            )
        } else {
            consecutiveFailures += 1
            if consecutiveFailures >= RuntimeTuning.failureThresholdForPrefetchThrottle {
                prefetchNetworkThrottledUntil = Date().addingTimeInterval(
                    RuntimeTuning.prefetchThrottleDurationSeconds
                )
            }
            track(
                kind: .imageLoad,
                scope: purpose.rawValue,
                properties: [
                    AnalyticsPropertyKey.cacheHit: "false",
                    AnalyticsPropertyKey.success: "false",
                    AnalyticsPropertyKey.targetPixels: "\(pixelSize)",
                    AnalyticsPropertyKey.durationMs: "\(elapsedMilliseconds(since: startedAt))",
                    AnalyticsPropertyKey.networkPolicy: policy.conservativeNetwork ? "conservative" : "standard",
                    AnalyticsPropertyKey.networkThrottled: isPrefetchNetworkThrottled ? "true" : "false",
                    AnalyticsPropertyKey.failureStreak: "\(consecutiveFailures)"
                ]
            )
        }
        return result
    }

    func prefetch(url: URL, targetPixelSize: CGFloat, allowsNetwork: Bool = true) async {
        _ = await image(
            url: url,
            targetPixelSize: targetPixelSize,
            allowsNetwork: allowsNetwork,
            purpose: .prefetch
        )
    }

    func setTelemetry(_ telemetry: any ReaderPerformanceTelemetry) async {
        self.telemetry = telemetry
    }

    func clear() async {
        cache.removeAllObjects()
        inFlightTasks.removeAll()
        consecutiveFailures = 0
        prefetchNetworkThrottledUntil = nil
    }

    private func cacheKey(url: URL, pixelSize: Int) -> String {
        "\(url.absoluteString)#\(pixelSize)"
    }

    private var isPrefetchNetworkThrottled: Bool {
        guard let throttledUntil = prefetchNetworkThrottledUntil else { return false }
        return throttledUntil > Date()
    }

    private func track(kind: ReaderTelemetryKind, scope: String, properties: [String: String]) {
        telemetry?.record(
            event: ReaderTelemetryEvent(
                kind: kind,
                scope: scope,
                properties: properties
            )
        )
    }

    private func elapsedMilliseconds(since startDate: Date) -> Int {
        max(0, Int(Date().timeIntervalSince(startDate) * 1_000))
    }

    private static func downsampleImage(data: Data, maxPixelSize: Int) -> UIImage? {
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
            return nil
        }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            downsampleOptions as CFDictionary
        ) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

private extension UIImage {
    var cacheCost: Int {
        if let cgImage {
            return cgImage.bytesPerRow * cgImage.height
        }
        let width = Int(size.width * scale)
        let height = Int(size.height * scale)
        return max(1, width * height * 4)
    }
}
