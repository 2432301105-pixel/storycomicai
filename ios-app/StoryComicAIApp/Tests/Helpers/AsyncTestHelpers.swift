import Foundation
import XCTest

enum AsyncTestHelpers {
    static func waitUntil(
        timeout: TimeInterval = 3,
        pollInterval: TimeInterval = 0.05,
        condition: @escaping () -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
        return condition()
    }

    static func assertEventually(
        timeout: TimeInterval = 3,
        pollInterval: TimeInterval = 0.05,
        condition: @escaping () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let success = await waitUntil(timeout: timeout, pollInterval: pollInterval, condition: condition)
        XCTAssertTrue(success, "Condition was not met within timeout", file: file, line: line)
    }
}
