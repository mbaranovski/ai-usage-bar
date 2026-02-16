// Sources/ClaudeUsage/ViewModels/UsageViewModel.swift

import Foundation
import Combine

@MainActor
class UsageViewModel: ObservableObject {
    // Published state
    @Published var usageResponse: UsageResponse?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastUpdated: Date?
    @Published var subscriptionType: String?

    // Timer for auto-refresh
    nonisolated(unsafe) var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 60 // 1 minute

    // Cancellables for Combine
    private var cancellables = Set<AnyCancellable>()

    init() {
        startAutoRefresh()
    }

    deinit {
        stopAutoRefresh()
    }

    // MARK: - Public Methods

    func refresh() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Get subscription type from credentials
            let credentials = try KeychainService.shared.getCredentials()
            subscriptionType = credentials.claudeAiOauth.subscriptionType?.capitalized ?? "Unknown"

            // Fetch usage data
            let response = try await UsageService.shared.fetchUsage()
            usageResponse = response
            lastUpdated = Date()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func startAutoRefresh() {
        stopAutoRefresh()

        // Refresh immediately on start
        Task {
            await refresh()
        }

        // Set up timer for periodic refresh
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }

    nonisolated func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Computed Properties

    var fiveHourUtilization: Double {
        usageResponse?.fiveHour?.utilization ?? 0
    }

    var fiveHourTimeRemaining: String {
        usageResponse?.fiveHour?.formattedTimeRemaining ?? "--"
    }

    var sevenDayUtilization: Double {
        usageResponse?.sevenDay?.utilization ?? 0
    }

    var sevenDayResetsAt: String {
        guard let date = usageResponse?.sevenDay?.resetsAtDate else {
            return "--"
        }
        return date.formattedDateTime()
    }

    var menuBarText: String {
        if error != nil {
            return "CC: Error"
        }
        let percent = Int(fiveHourUtilization)
        return "CC: \(percent)% [\(fiveHourTimeRemaining)]"
    }

    var utilizationColor: UtilizationLevel {
        let utilization = fiveHourUtilization
        if utilization >= 80 { return .critical }
        if utilization >= 50 { return .warning }
        return .normal
    }

    var lastUpdatedText: String {
        guard let lastUpdated = lastUpdated else {
            return "Never"
        }
        let interval = Date().timeIntervalSince(lastUpdated)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return lastUpdated.formattedDateTime()
        }
    }
}

// MARK: - Utilization Level

enum UtilizationLevel {
    case normal
    case warning
    case critical
}
