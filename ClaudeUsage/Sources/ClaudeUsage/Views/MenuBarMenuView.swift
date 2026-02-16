// Sources/ClaudeUsage/Views/MenuBarMenuView.swift

import SwiftUI

struct MenuBarMenuView: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var launchManager = LaunchAtLoginManager()
    @State private var isClaudeExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            headerSection

            Divider()

            // Claude Code Section (Collapsible)
            claudeSection

            Divider()

            // Actions
            actionsSection
        }
        .padding()
        .frame(width: 300)
    }

    // MARK: - View Components

    private var headerSection: some View {
        HStack {
            Text("AI Subscription Usage")
                .font(.headline)
            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
    }

    private var claudeSection: some View {
        DisclosureGroup(isExpanded: $isClaudeExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                // Current session (5-hour)
                usageSection(
                    title: "Current session",
                    utilization: viewModel.fiveHourUtilization,
                    resetInfo: viewModel.fiveHourTimeRemainingFormatted,
                    level: viewModel.utilizationColor
                )

                // Current week (all models)
                usageSection(
                    title: "Current week (all models)",
                    utilization: viewModel.sevenDayUtilization,
                    resetInfo: viewModel.sevenDayResetsAt,
                    level: utilizationLevel(for: viewModel.sevenDayUtilization)
                )

                // Current week (Sonnet only)
                usageSection(
                    title: "Current week (Sonnet only)",
                    utilization: viewModel.sonnetUtilization,
                    resetInfo: viewModel.sonnetResetsAt,
                    level: utilizationLevel(for: viewModel.sonnetUtilization)
                )

                // Extra usage
                if viewModel.extraUsageIsEnabled {
                    extraUsageSection
                }
            }
            .padding(.leading, 8)
        } label: {
            Text("Claude Code")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    private var extraUsageSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Extra usage")
                .font(.subheadline)
                .fontWeight(.semibold)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForLevel(utilizationLevel(for: viewModel.extraUsageUtilization)))
                        .frame(width: geometry.size.width * min(viewModel.extraUsageUtilization / 100, 1), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(Int(viewModel.extraUsageUtilization))% used")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            Text("\(viewModel.extraUsageSpent) / \(viewModel.extraUsageLimit) spent")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(extraUsageResetDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var extraUsageResetDate: String {
        let timeZone = TimeZone.current
        let timeZoneName = timeZone.identifier

        let calendar = Calendar.current
        let now = Date()

        let components = calendar.dateComponents([.year, .month], from: now)
        var nextMonth = components
        nextMonth.month! += 1

        guard let resetDate = calendar.date(from: nextMonth) else {
            return "--"
        }

        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "MMM d"

        return "Resets \(formatter.string(from: resetDate)) (\(timeZoneName))"
    }

    private func usageSection(title: String, utilization: Double, resetInfo: String, level: UtilizationLevel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForLevel(level))
                        .frame(width: geometry.size.width * min(utilization / 100, 1), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(Int(utilization))% used")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(resetInfo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Launch at Login", isOn: $launchManager.isEnabled)
                .toggleStyle(.checkbox)

            Button(action: { NSApp.terminate(nil) }) {
                Label("Quit", systemImage: "power")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helper Methods

    private func colorForLevel(_ level: UtilizationLevel) -> Color {
        switch level {
        case .normal: return .green
        case .warning: return .yellow
        case .critical: return .red
        }
    }

    private func utilizationLevel(for value: Double) -> UtilizationLevel {
        if value >= 80 { return .critical }
        if value >= 50 { return .warning }
        return .normal
    }
}

#Preview {
    MenuBarMenuView(viewModel: UsageViewModel())
}
