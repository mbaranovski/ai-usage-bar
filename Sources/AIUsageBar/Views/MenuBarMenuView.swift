// Sources/AIUsageBar/Views/MenuBarMenuView.swift

import SwiftUI

struct MenuBarMenuView: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var launchManager = LaunchAtLoginManager()
    @State private var isClaudeExpanded = true
    @State private var isClaudeHovered = false

    private let menuFont: Font = .system(size: 13)
    private let defaultFont: Font = .system(size: 12)
    private let smallFont: Font = .system(size: 11)
    private let barLabelFont: Font = .system(size: 10, weight: .medium)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            headerSection

            Divider()

            // Claude Code Section (Collapsible)
            claudeSection

            // Actions
            actionsSection
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(width: 320)
    }

    // MARK: - View Components

    private var headerSection: some View {
        HStack {
            Text("AI Usage Bar")
                .font(menuFont)
                .foregroundColor(.secondary)
            Spacer()
            ProgressView()
                .scaleEffect(0.4)
                .frame(width: 12, height: 12)
                .opacity(viewModel.isLoading ? 1 : 0)
        }
    }

    private var claudeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation { isClaudeExpanded.toggle() } }) {
                HStack {
                    Text("Claude Code".uppercased())
                        .font(smallFont.bold())
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isClaudeExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isClaudeExpanded)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isClaudeHovered = hovering
            }

            if isClaudeExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    // Show error message if there's an error
                    if viewModel.error != nil {
                        errorSection
                    } else {
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
                }
                .padding(.top, 8)
            }
        }
    }

    private var extraUsageSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Extra usage")
                .font(defaultFont)
                .foregroundColor(.secondary)

            // Progress bar with % inside
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(colorForLevel(utilizationLevel(for: viewModel.extraUsageUtilization)))
                        .frame(width: geometry.size.width * min(viewModel.extraUsageUtilization / 100, 1))

                    Text("\(Int(viewModel.extraUsageUtilization))%")
                        .font(barLabelFont)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 0)
                        .padding(.leading, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 16)

            HStack {
                Text("\(viewModel.extraUsageSpent) / \(viewModel.extraUsageLimit) spent")
                    .font(smallFont)
                    .foregroundColor(.secondary)
                Spacer()
                Text(extraUsageResetDate)
                    .font(smallFont)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var errorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Error title with icon
            HStack(spacing: 6) {
                Image(systemName: viewModel.isAuthError ? "person.crop.circle.badge.exclamationmark" : "exclamationmark.triangle.fill")
                    .foregroundColor(viewModel.isAuthError ? .orange : .red)
                    .font(.system(size: 14))
                Text(viewModel.errorTitle)
                    .font(defaultFont.bold())
                    .foregroundColor(viewModel.isAuthError ? .orange : .red)
            }

            // Error message
            Text(viewModel.errorMessage)
                .font(smallFont)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Retry button
            Button(action: { Task { await viewModel.refresh() } }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                    Text("Retry")
                }
                .font(smallFont)
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
    }

    private var extraUsageResetDate: String {
        Date().formattedMonthlyReset()
    }

    private func usageSection(title: String, utilization: Double, resetInfo: String, level: UtilizationLevel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(defaultFont)
                .foregroundColor(.secondary)

            // Progress bar with % inside
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(colorForLevel(level))
                        .frame(width: geometry.size.width * min(utilization / 100, 1))

                    Text("\(Int(utilization))%")
                        .font(barLabelFont)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 0)
                        .padding(.leading, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 16)

            HStack {
                Spacer()
                Text(resetInfo)
                    .font(smallFont)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 6) {
            Divider()
            HStack(spacing: 0) {
                Button(action: { launchManager.isEnabled.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: launchManager.isEnabled ? "checkmark.square.fill" : "square")
                            .foregroundColor(launchManager.isEnabled ? .accentColor : .secondary)
                        Text("Start at login")
                            .foregroundColor(.secondary)
                    }
                    .font(menuFont)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(height: 16)

                Button(action: { NSApp.terminate(nil) }) {
                    Text("Quit")
                        .font(menuFont)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
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
