import Foundation

enum AnalyticsEvent: String, CaseIterable {
    case revealStarted = "reveal_started"
    case bookOpened = "book_opened"
    case previewPageTurned = "preview_page_turned"
    case switchedToFlatReader = "switched_to_flat_reader"
    case modeSwitched = "mode_switched"
    case exportTapped = "export_tapped"
    case paywallSeen = "paywall_seen"
    case unlockStarted = "unlock_started"
    case unlockCompleted = "unlock_completed"
    case readerTelemetry = "reader_telemetry"
}

enum AnalyticsPropertyKey {
    static let projectID = "project_id"
    static let mode = "mode"
    static let fromMode = "from_mode"
    static let toMode = "to_mode"
    static let fromPageIndex = "from_page_index"
    static let toPageIndex = "to_page_index"
    static let totalPages = "total_pages"
    static let action = "action"
    static let offerID = "offer_id"
    static let lockReason = "lock_reason"
    static let source = "source"
    static let schemaVersion = "schema_version"
    static let telemetryType = "telemetry_type"
    static let telemetryScope = "telemetry_scope"
    static let durationMs = "duration_ms"
    static let success = "success"
    static let statusCode = "status_code"
    static let targetPixels = "target_px"
    static let networkPolicy = "network_policy"
    static let networkThrottled = "network_throttled"
    static let cacheHit = "cache_hit"
    static let pageIndex = "page_index"
    static let pagesCount = "pages_count"
    static let thumbnailRadius = "thumbnail_radius"
    static let fullRadius = "full_radius"
    static let failureStreak = "failure_streak"
    static let offerPriority = "offer_priority"
    static let offerRecommended = "offer_recommended"
}

protocol AnalyticsService: AnyObject {
    func track(event: AnalyticsEvent, properties: [String: String])
}

protocol AnalyticsSink: AnyObject {
    func record(event: AnalyticsEvent, properties: [String: String], timestampUTC: Date)
}

final class ConsoleAnalyticsSink: AnalyticsSink {
    func record(event: AnalyticsEvent, properties: [String: String], timestampUTC: Date) {
        #if DEBUG
        let propertiesText = properties
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
        print("[Analytics] \(event.rawValue) ts=\(timestampUTC.ISO8601Format()) {\(propertiesText)}")
        #else
        _ = (event, properties, timestampUTC)
        #endif
    }
}

final class ConsoleAnalyticsService: AnalyticsService {
    private let sink: any AnalyticsSink

    init(sink: any AnalyticsSink = ConsoleAnalyticsSink()) {
        self.sink = sink
    }

    func track(event: AnalyticsEvent, properties: [String: String]) {
        let normalizedProperties = AnalyticsSchema.normalize(event: event, properties: properties)
        sink.record(
            event: event,
            properties: normalizedProperties,
            timestampUTC: Date()
        )
    }
}
