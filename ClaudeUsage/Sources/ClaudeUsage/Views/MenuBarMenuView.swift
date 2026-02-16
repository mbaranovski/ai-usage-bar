// Sources/ClaudeUsage/Views/MenuBarMenuView.swift

import SwiftUI

struct MenuBarMenuView: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var launchManager = LaunchAtLoginManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            headerSection

            Divider()

            // 5-Hour Window
            usageSection(
                title: "5-Hour Window",
                utilization: viewModel.fiveHourUtilization,
                resetInfo: "Resets in: \(viewModel.fiveHourTimeRemaining)",
                level: viewModel.utilizationColor
            )

            Divider()

            // 7-Day Window
            usageSection(
                title: "7-Day Window",
                utilization: viewModel.sevenDayUtilization,
                resetInfo: "Resets: \(viewModel.sevenDayResetsAt)",
                level: utilizationLevel(for: viewModel.sevenDayUtilization)
            )

            Divider()

            // Status Info
            statusSection

            Divider()

            // Actions
            actionsSection
        }
        .padding()
        .frame(width: 280)
    }

    // MARK: - View Components

    private var headerSection: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundColor(.purple)
            Text("Claude Code Usage")
                .font(.headline)
            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
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

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let subscriptionType = viewModel.subscriptionType {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("Subscription: \(subscriptionType)")
                        .font(.caption)
                }
            }

            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text("Last updated: \(viewModel.lastUpdatedText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let error = viewModel.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 8) {
            Button(action: openClaudeCode) {
                Label("Open Claude Code", systemImage: "terminal")
            }
            .buttonStyle(.plain)

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

    private func openClaudeCode() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-a", "Terminal"]
        try? task.run()
    }
}

#Preview {
    MenuBarMenuView(viewModel: UsageViewModel())
}
