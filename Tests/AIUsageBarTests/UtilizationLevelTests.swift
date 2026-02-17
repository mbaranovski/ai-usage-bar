// Tests/AIUsageBarTests/UtilizationLevelTests.swift

import XCTest
@testable import AIUsageBar

final class UtilizationLevelTests: XCTestCase {

    func testUtilizationLevel_hasNormalCase() {
        let level = UtilizationLevel.normal
        XCTAssertNotNil(level)
    }

    func testUtilizationLevel_hasWarningCase() {
        let level = UtilizationLevel.warning
        XCTAssertNotNil(level)
    }

    func testUtilizationLevel_hasCriticalCase() {
        let level = UtilizationLevel.critical
        XCTAssertNotNil(level)
    }
}
