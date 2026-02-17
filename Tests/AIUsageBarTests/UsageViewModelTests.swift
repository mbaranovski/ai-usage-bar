// Tests/AIUsageBarTests/UsageViewModelTests.swift

import XCTest
@testable import AIUsageBar

// MARK: - Mocks

final class MockCredentialProvider: CredentialProvider, @unchecked Sendable {
    var credentials: Credentials?
    var error: Error?
    var clearCacheCalled = false

    func getCredentials() throws -> Credentials {
        if let error = error { throw error }
        guard let credentials = credentials else { throw KeychainError.itemNotFound }
        return credentials
    }

    func getAccessToken() throws -> String {
        return try getCredentials().claudeAiOauth.accessToken
    }

    func clearCache() {
        clearCacheCalled = true
    }
}

final class MockUsageService: UsageFetching, @unchecked Sendable {
    var response: UsageResponse?
    var error: Error?

    func fetchUsage(token: String) async throws -> UsageResponse {
        if let error = error { throw error }
        guard let response = response else { throw UsageServiceError.invalidResponse }
        return response
    }
}

// MARK: - Test Helpers

extension Credentials {
    static func mock(accessToken: String = "test-token", subscriptionType: String? = "pro") -> Credentials {
        Credentials(claudeAiOauth: OAuthToken(
            accessToken: accessToken,
            refreshToken: nil,
            expiresAt: nil,
            scopes: nil,
            subscriptionType: subscriptionType
        ))
    }
}

extension UsageResponse {
    static func mock(
        fiveHourUtilization: Double = 0.3,
        sevenDayUtilization: Double = 0.5
    ) -> UsageResponse {
        UsageResponse(
            fiveHour: UsageWindow(utilization: fiveHourUtilization, resetsAt: nil),
            sevenDay: UsageWindow(utilization: sevenDayUtilization, resetsAt: nil),
            sevenDaySonnet: nil,
            sevenDayOauthApps: nil,
            sevenDayOpus: nil,
            extraUsage: nil
        )
    }
}

// MARK: - Tests

final class UsageViewModelTests: XCTestCase {

    private var mockCredentials: MockCredentialProvider!
    private var mockUsage: MockUsageService!

    @MainActor
    private func makeViewModel() -> UsageViewModel {
        let vm = UsageViewModel(credentialProvider: mockCredentials, usageService: mockUsage)
        vm.stopAutoRefresh()
        return vm
    }

    override func setUp() {
        super.setUp()
        mockCredentials = MockCredentialProvider()
        mockUsage = MockUsageService()
    }

    // MARK: - Refresh Tests

    @MainActor
    func testRefresh_success() async {
        mockCredentials.credentials = .mock()
        mockUsage.response = .mock(fiveHourUtilization: 0.42)

        let vm = makeViewModel()
        await vm.refresh()

        XCTAssertEqual(vm.fiveHourUtilization, 0.42)
        XCTAssertNil(vm.error)
        XCTAssertNotNil(vm.lastUpdated)
        XCTAssertEqual(vm.subscriptionType, "Pro")
    }

    @MainActor
    func testRefresh_keychainError_setsError() async {
        mockCredentials.error = KeychainError.itemNotFound
        mockUsage.response = .mock()

        let vm = makeViewModel()
        await vm.refresh()

        XCTAssertNotNil(vm.error)
        XCTAssertNil(vm.usageResponse)
    }

    @MainActor
    func testRefresh_httpError401_clearsCachedCredentials() async {
        mockCredentials.credentials = .mock()
        mockUsage.error = UsageServiceError.httpError(401)

        let vm = makeViewModel()
        await vm.refresh()

        XCTAssertTrue(mockCredentials.clearCacheCalled)
    }

    @MainActor
    func testRefresh_networkError_doesNotClearCache() async {
        mockCredentials.credentials = .mock()
        mockUsage.error = UsageServiceError.networkError(URLError(.notConnectedToInternet))

        let vm = makeViewModel()
        await vm.refresh()

        XCTAssertFalse(mockCredentials.clearCacheCalled)
        XCTAssertNotNil(vm.error)
    }

    // MARK: - Computed Property Tests

    @MainActor
    func testMenuBarText_withError_showsError() async {
        mockCredentials.error = KeychainError.itemNotFound

        let vm = makeViewModel()
        await vm.refresh()

        XCTAssertEqual(vm.menuBarText, "CC: Error")
    }

    @MainActor
    func testMenuBarText_withData_showsPercentAndTime() async {
        mockCredentials.credentials = .mock()
        mockUsage.response = .mock(fiveHourUtilization: 50)

        let vm = makeViewModel()
        await vm.refresh()

        XCTAssertTrue(vm.menuBarText.hasPrefix("CC: 50%"))
    }

    @MainActor
    func testUtilizationColor_normal() async {
        mockCredentials.credentials = .mock()
        mockUsage.response = .mock(fiveHourUtilization: 30)

        let vm = makeViewModel()
        await vm.refresh()

        XCTAssertEqual(vm.utilizationColor, .normal)
    }

    @MainActor
    func testUtilizationColor_warning() async {
        mockCredentials.credentials = .mock()
        mockUsage.response = .mock(fiveHourUtilization: 55)

        let vm = makeViewModel()
        await vm.refresh()

        XCTAssertEqual(vm.utilizationColor, .warning)
    }

    @MainActor
    func testUtilizationColor_critical() async {
        mockCredentials.credentials = .mock()
        mockUsage.response = .mock(fiveHourUtilization: 85)

        let vm = makeViewModel()
        await vm.refresh()

        XCTAssertEqual(vm.utilizationColor, .critical)
    }

    // MARK: - Last Updated Text Tests

    @MainActor
    func testLastUpdatedText_whenNil_isNever() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.lastUpdatedText, "Never")
    }

    @MainActor
    func testLastUpdatedText_afterRefresh_isJustNow() async {
        mockCredentials.credentials = .mock()
        mockUsage.response = .mock()

        let vm = makeViewModel()
        await vm.refresh()

        XCTAssertEqual(vm.lastUpdatedText, "Just now")
    }
}
