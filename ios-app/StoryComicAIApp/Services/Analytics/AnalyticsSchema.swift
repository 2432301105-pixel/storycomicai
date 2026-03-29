import Foundation

private struct AnalyticsSchemaRule {
    let requiredKeys: Set<String>
    let optionalKeys: Set<String>

    var allowedKeys: Set<String> {
        requiredKeys.union(optionalKeys)
    }
}

enum AnalyticsSchema {
    static let version = "2026-03-29"

    static func normalize(event: AnalyticsEvent, properties: [String: String]) -> [String: String] {
        _ = validateCoverage

        guard let rule = rules[event] else {
            assertionFailure("Analytics schema rule is missing for event: \(event.rawValue)")
            return [AnalyticsPropertyKey.schemaVersion: version]
        }

        var normalized = normalizedBase(properties: properties)
        normalized = normalized.filter { rule.allowedKeys.contains($0.key) || $0.key == AnalyticsPropertyKey.schemaVersion }

        for requiredKey in rule.requiredKeys where normalized[requiredKey] == nil {
            normalized[requiredKey] = "unknown"
        }

        return normalized
    }

    private static func normalizedBase(properties: [String: String]) -> [String: String] {
        var normalized: [String: String] = [:]
        for (key, value) in properties {
            let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedKey.isEmpty, !trimmedValue.isEmpty else { continue }
            normalized[trimmedKey] = trimmedValue
        }
        normalized[AnalyticsPropertyKey.schemaVersion] = version
        return normalized
    }

    private static let validateCoverage: Void = {
        let coveredEvents = Set(rules.keys)
        let missingEvents = Set(AnalyticsEvent.allCases).subtracting(coveredEvents)
        assertionFailureIfNeeded(
            missingEvents.isEmpty,
            "Analytics schema coverage mismatch. Missing events: \(missingEvents.map(\.rawValue).sorted())"
        )
    }()

    private static let rules: [AnalyticsEvent: AnalyticsSchemaRule] = [
        .revealStarted: .init(
            requiredKeys: [
                AnalyticsPropertyKey.projectID,
                AnalyticsPropertyKey.mode
            ],
            optionalKeys: []
        ),
        .bookOpened: .init(
            requiredKeys: [
                AnalyticsPropertyKey.projectID,
                AnalyticsPropertyKey.mode
            ],
            optionalKeys: []
        ),
        .previewPageTurned: .init(
            requiredKeys: [
                AnalyticsPropertyKey.projectID,
                AnalyticsPropertyKey.mode,
                AnalyticsPropertyKey.fromPageIndex,
                AnalyticsPropertyKey.toPageIndex,
                AnalyticsPropertyKey.totalPages
            ],
            optionalKeys: []
        ),
        .switchedToFlatReader: .init(
            requiredKeys: [
                AnalyticsPropertyKey.projectID,
                AnalyticsPropertyKey.mode,
                AnalyticsPropertyKey.fromMode
            ],
            optionalKeys: []
        ),
        .modeSwitched: .init(
            requiredKeys: [
                AnalyticsPropertyKey.projectID,
                AnalyticsPropertyKey.mode,
                AnalyticsPropertyKey.fromMode,
                AnalyticsPropertyKey.toMode
            ],
            optionalKeys: []
        ),
        .exportTapped: .init(
            requiredKeys: [
                AnalyticsPropertyKey.projectID,
                AnalyticsPropertyKey.mode,
                AnalyticsPropertyKey.action
            ],
            optionalKeys: []
        ),
        .paywallSeen: .init(
            requiredKeys: [AnalyticsPropertyKey.source],
            optionalKeys: [AnalyticsPropertyKey.projectID]
        ),
        .unlockStarted: .init(
            requiredKeys: [
                AnalyticsPropertyKey.offerID,
                AnalyticsPropertyKey.source
            ],
            optionalKeys: [AnalyticsPropertyKey.projectID]
        ),
        .unlockCompleted: .init(
            requiredKeys: [
                AnalyticsPropertyKey.offerID,
                AnalyticsPropertyKey.source
            ],
            optionalKeys: [AnalyticsPropertyKey.projectID]
        ),
        .readerTelemetry: .init(
            requiredKeys: [
                AnalyticsPropertyKey.telemetryType,
                AnalyticsPropertyKey.telemetryScope
            ],
            optionalKeys: [
                AnalyticsPropertyKey.durationMs,
                AnalyticsPropertyKey.success,
                AnalyticsPropertyKey.statusCode,
                AnalyticsPropertyKey.targetPixels,
                AnalyticsPropertyKey.networkPolicy,
                AnalyticsPropertyKey.networkThrottled,
                AnalyticsPropertyKey.cacheHit,
                AnalyticsPropertyKey.pageIndex,
                AnalyticsPropertyKey.pagesCount,
                AnalyticsPropertyKey.thumbnailRadius,
                AnalyticsPropertyKey.fullRadius,
                AnalyticsPropertyKey.failureStreak,
                AnalyticsPropertyKey.projectID,
                AnalyticsPropertyKey.mode
            ]
        )
    ]

    private static func assertionFailureIfNeeded(_ condition: Bool, _ message: String) {
        if !condition {
            assertionFailure(message)
        }
    }
}
