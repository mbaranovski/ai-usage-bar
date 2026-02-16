// Sources/AISubscriptionUsage/ViewModels/UsageViewModel.swift

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

    // Current session (5-hour window)
    var fiveHourUtilization: Double {
        usageResponse?.fiveHour?.utilization ?? 0
    }

    var fiveHourTimeRemaining: String {
        usageResponse?.fiveHour?.formattedTimeRemaining ?? "--"
    }

    var fiveHourTimeRemainingFormatted: String {
        guard let date = usageResponse?.fiveHour?.resetsAtDate else {
            return "--"
        }
        return date.formattedResetTime()
    }

    // Current week (all models)
    var sevenDayUtilization: Double {
        usageResponse?.sevenDay?.utilization ?? 0
    }

    var sevenDayResetsAt: String {
        guard let date = usageResponse?.sevenDay?.resetsAtDate else {
            return "--"
        }
        return date.formattedResetTime()
    }

    // MARK: - Sonnet Properties

    var sonnetUtilization: Double {
        usageResponse?.sevenDaySonnet?.utilization ?? 0
    }

    var sonnetResetsAt: String {
        guard let date = usageResponse?.sevenDaySonnet?.resetsAtDate else {
            return "--"
        }
        return date.formattedResetTime()
    }

    // MARK: - Extra Usage Properties

    var extraUsageUtilization: Double {
        usageResponse?.extraUsage?.utilization ?? 0
    }

    var extraUsageSpent: String {
        guard let extra = usageResponse?.extraUsage, extra.isEnabled else {
            return "--"
        }
        return String(format: "$%.2f", extra.spentDollars)
    }

    var extraUsageLimit: String {
        guard let extra = usageResponse?.extraUsage, extra.isEnabled else {
            return "--"
        }
        return String(format: "$%.2f", extra.limitDollars)
    }

    var extraUsageIsEnabled: Bool {
        usageResponse?.extraUsage?.isEnabled ?? false
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

    // MARK: - Error Properties

    var isAuthError: Bool {
        guard let serviceError = error as? UsageServiceError else { return false }
        switch serviceError {
        case .noToken, .httpError(401):
            return true
        default:
            return false
        }
    }

    var errorTitle: String {
        guard let serviceError = error as? UsageServiceError else {
            return "Error"
        }
        switch serviceError {
        case .noToken:
            return "No Authentication"
        case .httpError(401):
            return "Authentication Expired"
        case .httpError(let code):
            return "HTTP Error (\(code))"
        case .networkError:
            return "Network Error"
        case .invalidResponse:
            return "Invalid Response"
        }
    }

    var errorMessage: String {
        guard let serviceError = error as? UsageServiceError else {
            return error?.localizedDescription ?? "Unknown error"
        }
        switch serviceError {
        case .noToken, .httpError(401):
            return "Please sign in using the Claude Code CLI:\n\nclaude login"
        default:
            return serviceError.errorDescription ?? "Unknown error"
        }
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
