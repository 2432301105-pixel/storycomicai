import Foundation

enum ReaderTelemetryKind: String {
    case imageLoad = "image_load"
    case prefetchWindow = "prefetch_window"
}

struct ReaderTelemetryEvent {
    let kind: ReaderTelemetryKind
    let scope: String
    let properties: [String: String]
}

protocol ReaderPerformanceTelemetry: AnyObject {
    func record(event: ReaderTelemetryEvent)
}

final class NoopReaderPerformanceTelemetry: ReaderPerformanceTelemetry {
    func record(event: ReaderTelemetryEvent) {
        _ = event
    }
}

final class AnalyticsReaderPerformanceTelemetry: ReaderPerformanceTelemetry {
    private let analyticsService: any AnalyticsService
    private let samplingRate: Double

    init(
        analyticsService: any AnalyticsService,
        samplingRate: Double = 0.2
    ) {
        self.analyticsService = analyticsService
        self.samplingRate = min(max(samplingRate, 0), 1)
    }

    func record(event: ReaderTelemetryEvent) {
        guard shouldSample else { return }

        var payload = event.properties
        payload[AnalyticsPropertyKey.telemetryType] = event.kind.rawValue
        payload[AnalyticsPropertyKey.telemetryScope] = event.scope

        analyticsService.track(event: .readerTelemetry, properties: payload)
    }

    private var shouldSample: Bool {
        Double.random(in: 0...1) <= samplingRate
    }
}
