import XCTest
@testable import StoryComicAIApp

final class AnalyticsSchemaTests: XCTestCase {
    func testNormalizeFillsRequiredAndDropsUnknownKeys() {
        let normalized = AnalyticsSchema.normalize(
            event: .exportTapped,
            properties: [
                AnalyticsPropertyKey.projectID: "project-1",
                "unexpected_key": "should_be_removed"
            ]
        )

        XCTAssertEqual(normalized[AnalyticsPropertyKey.projectID], "project-1")
        XCTAssertEqual(normalized[AnalyticsPropertyKey.action], "unknown")
        XCTAssertEqual(normalized[AnalyticsPropertyKey.mode], "unknown")
        XCTAssertNil(normalized["unexpected_key"])
        XCTAssertEqual(normalized[AnalyticsPropertyKey.schemaVersion], AnalyticsSchema.version)
    }

    func testNormalizeAddsSchemaVersionForReaderTelemetry() {
        let normalized = AnalyticsSchema.normalize(
            event: .readerTelemetry,
            properties: [
                AnalyticsPropertyKey.telemetryType: "image_load",
                AnalyticsPropertyKey.telemetryScope: "display",
                AnalyticsPropertyKey.success: "true",
                AnalyticsPropertyKey.failureStreak: "2"
            ]
        )

        XCTAssertEqual(normalized[AnalyticsPropertyKey.telemetryType], "image_load")
        XCTAssertEqual(normalized[AnalyticsPropertyKey.telemetryScope], "display")
        XCTAssertEqual(normalized[AnalyticsPropertyKey.failureStreak], "2")
        XCTAssertEqual(normalized[AnalyticsPropertyKey.schemaVersion], AnalyticsSchema.version)
    }

    func testSchemaCoverageIncludesAllAnalyticsEvents() {
        for event in AnalyticsEvent.allCases {
            let normalized = AnalyticsSchema.normalize(event: event, properties: [:])
            XCTAssertNotNil(normalized[AnalyticsPropertyKey.schemaVersion], "Missing schema for \(event.rawValue)")
        }
    }
}
