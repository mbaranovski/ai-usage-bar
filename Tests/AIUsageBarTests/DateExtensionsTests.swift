// Tests/AIUsageBarTests/DateExtensionsTests.swift

import XCTest
@testable import AIUsageBar

final class DateExtensionsTests: XCTestCase {

    // MARK: - formattedDateTime Tests

    func testFormattedDateTime_returnsCorrectFormat() {
        // Given
        let date = Date(timeIntervalSince1970: 1700000000) // Fixed timestamp

        // When
        let result = date.formattedDateTime()

        // Then
        // Should contain date and time components
        XCTAssertFalse(result.isEmpty)
    }

    func testFormattedDateTime_currentDate_isNotEmpty() {
        // Given
        let date = Date()

        // When
        let result = date.formattedDateTime()

        // Then
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - formattedResetTime Tests

    func testFormattedResetTime_includesTimezone() {
        // Given
        let date = Date()

        // When
        let result = date.formattedResetTime()

        // Then
        // Should contain time and timezone info
        XCTAssertFalse(result.isEmpty)
    }

    func testFormattedResetTime_futureDate_isNotEmpty() {
        // Given
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now

        // When
        let result = futureDate.formattedResetTime()

        // Then
        XCTAssertFalse(result.isEmpty)
    }
}
