// Sources/AIUsageBar/ViewModels/UsageViewModel.swift

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

    // Task for auto-refresh using async sequence
    // nonisolated(unsafe) is safe here because Task.cancel() is thread-safe
    nonisolated(unsafe) private var refreshTask: Task<Void, Never>?
    private let refreshInterval: TimeInterval = 60 // 1 minute

    init() {
        startAutoRefresh()
    }

    deinit {
        // Task.cancel() is thread-safe, safe to call from deinit
        refreshTask?.cancel()
    }

    // MARK: - Public Methods

    func refresh() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Get credentials from keychain (single access)
            let credentials = try KeychainService.shared.getCredentials()
            subscriptionType = credentials.claudeAiOauth.subscriptionType?.capitalized ?? "Unknown"

            // Fetch usage data with token from credentials
            let response = try await UsageService.shared.fetchUsage(token: credentials.claudeAiOauth.accessToken)
            usageResponse = response
            lastUpdated = Date()
        } catch let error as UsageServiceError {
            // Clear cached credentials on auth error so next refresh fetches fresh ones
            if case .httpError(401) = error {
                KeychainService.shared.clearCache()
            }
            self.error = error
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func startAutoRefresh() {
        stopAutoRefresh()

        // Refresh immediately on start
        refreshTask = Task { [weak self] in
            // Initial refresh
            await self?.refresh()

            // Periodic refresh using async sequence
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(self?.refreshInterval ?? 60))
                    guard !Task.isCancelled else { break }
                    await self?.refresh()
                } catch {
                    // Task.sleep was cancelled, exit the loop
                    break
                }
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    // MARK: - Computed Properties

    // Current session (5-hour window)
    var fiveHourUtilization: Double {
        usageResponse?.fiveHour?.utilization ?? 0
    }

    var fiveHourTimeRemaining: String {
        usageResponse?.fiveHour?.formattedTimeRemaining ?? "--"
    }

    var fiveHourHoursRemaining: Int {
        guard let remaining = usageResponse?.fiveHour?.timeRemaining, remaining > 0 else {
            return 0
        }
        return Int(remaining) / 3600
    }

    var fiveHourMinutesRemaining: Int {
        guard let remaining = usageResponse?.fiveHour?.timeRemaining, remaining > 0 else {
            return 0
        }
        return (Int(remaining) % 3600) / 60
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
