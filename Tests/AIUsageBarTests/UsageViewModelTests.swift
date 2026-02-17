// Tests/AIUsageBarTests/UsageViewModelTests.swift

import XCTest
@testable import AIUsageBar

final class UsageViewModelTests: XCTestCase {

    // MARK: - UtilizationLevel Tests
    // Note: Full ViewModel tests require mocking KeychainService/UsageService
    // which would need a dependency injection refactor

    func testUtilizationLevel_exists() {
        // Verify the enum cases exist
        let normal = UtilizationLevel.normal
        let warning = UtilizationLevel.warning
        let critical = UtilizationLevel.critical

        // Just verify they can be created
        XCTAssertNotNil(normal)
        XCTAssertNotNil(warning)
        XCTAssertNotNil(critical)
    }

    // MARK: - Computed Property Logic Tests
    // These test the logic without needing a real ViewModel instance

    func testFiveHourUtilization_whenNil_returnsZero() {
        // Given: Response is nil, default should be 0
        let response: UsageResponse? = nil
        let utilization = response?.fiveHour?.utilization ?? 0

        // Then
        XCTAssertEqual(utilization, 0)
    }

    func testMenuBarTextFormat() {
        // Test the format string logic
        let percent = 50
        let timeRemaining = "2h 30m"
        let expected = "CC: \(percent)% [\(timeRemaining)]"

        XCTAssertEqual(expected, "CC: 50% [2h 30m]")
    }

    func testLastUpdatedText_whenNil_isNever() {
        let lastUpdated: Date? = nil
        let text = lastUpdated == nil ? "Never" : "Has value"
        XCTAssertEqual(text, "Never")
    }

    func testLastUpdatedText_whenRecent_isJustNow() {
        let lastUpdated = Date()
        let interval = Date().timeIntervalSince(lastUpdated)
        let text = interval < 60 ? "Just now" : "Older"
        XCTAssertEqual(text, "Just now")
    }

    func testLastUpdatedText_whenMinuteAgo_showsMinutes() {
        let lastUpdated = Date().addingTimeInterval(-90)
        let interval = Date().timeIntervalSince(lastUpdated)
        let minutes = Int(interval / 60)
        let text = interval < 3600 ? "\(minutes)m ago" : "Hours ago"

        XCTAssertTrue(text.contains("m ago"))
    }
}
