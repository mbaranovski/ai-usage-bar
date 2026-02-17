# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A native macOS menu bar app (SwiftUI) that displays Claude Code subscription usage limits in real-time. It reads authentication credentials from the macOS keychain (stored by the Claude Code CLI) and fetches usage data from the Anthropic API.

## Build Commands

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run the app
.build/release/AIUsageBar
```

## Architecture

MVVM pattern with the following structure:

```
Sources/AIUsageBar/
├── AIUsageBarApp.swift      # @main entry point, MenuBarExtra setup
├── ViewModels/
│   └── UsageViewModel.swift  # ObservableObject, manages state & auto-refresh
├── Views/
│   ├── MenuBarLabelView.swift  # Menu bar label: "CC: 30% [1h 20m]"
│   └── MenuBarMenuView.swift   # Dropdown menu with detailed stats
├── Services/
│   ├── UsageService.swift      # API client for anthropic.com usage endpoint
│   ├── KeychainService.swift   # Reads Claude CLI credentials from keychain
│   └── LaunchAtLoginManager.swift  # SMAppService for login items
├── Models/
│   └── UsageResponse.swift     # Codable structs for API response
└── Utilities/
    └── DateExtensions.swift    # Date formatting helpers
```

### Key Data Flow

1. **KeychainService** reads credentials from keychain service `"Claude Code-credentials"` (stored by Claude CLI)
2. **UsageService** fetches usage from `https://api.anthropic.com/api/oauth/usage` with Bearer token
3. **UsageViewModel** auto-refreshes every 60 seconds, exposes utilization percentages and reset times
4. **Views** observe the ViewModel and display current session (5-hour) and weekly (7-day) usage

### Usage Metrics

- `fiveHour`: Current session utilization (resets every 5 hours)
- `sevenDay`: Weekly usage for all models
- `sevenDaySonnet`: Weekly usage for Sonnet only
- `extraUsage`: Pay-as-you-go extra usage (if enabled)

## Requirements

- macOS 13.0+ (Ventura)
- Swift 6.0+
- Claude Code CLI must be authenticated (`claude login`)

## Resources

- `Resources/Info.plist` - App bundle configuration
- `Resources/AIUsageBar.entitlements` - App sandbox entitlements
