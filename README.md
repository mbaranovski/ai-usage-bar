# AI Usage Bar

A native macOS menu bar app that displays Claude Code subscription usage limits in real-time.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- Real-time usage monitoring for Claude Code subscription
- Current session usage (5-hour rolling window)
- Weekly usage for all models and Sonnet-specific
- Extra usage (pay-as-you-go) tracking
- Auto-refresh every 60 seconds
- Launch at login support
- Native macOS menu bar integration

## Requirements

- macOS 13.0 (Ventura) or later
- [Claude Code CLI](https://claude.ai/code) installed and authenticated

## Installation

### Build from Source

```bash
# Clone the repository
git clone https://github.com/mbaranovski/ai-usage-bar.git
cd ai-usage-bar

# Build and run
swift build -c release
.build/release/AIUsageBar
```

### Create App Bundle

```bash
./build-app.sh
```

This creates `AIUsageBar.app` in the `build/` directory that you can drag to your Applications folder.

## Usage

1. Make sure you're logged in to Claude Code CLI (`claude login`)
2. Launch AI Usage Bar
3. Click the menu bar icon to view detailed usage statistics

The app automatically reads your Claude credentials from the macOS keychain (stored by the Claude CLI during login).

## Data Displayed

| Metric | Description |
|--------|-------------|
| Current Session | Usage within the current 5-hour rolling window |
| Current Week (All Models) | Total usage across all Claude models |
| Current Week (Sonnet Only) | Usage specific to Claude Sonnet |
| Extra Usage | Pay-as-you-go usage (if enabled on your account) |

## Architecture

Built with SwiftUI using MVVM pattern:

```
Sources/AIUsageBar/
├── AIUsageBarApp.swift           # App entry point
├── ViewModels/
│   └── UsageViewModel.swift      # State management & auto-refresh
├── Views/
│   ├── MenuBarLabelView.swift    # Menu bar display
│   └── MenuBarMenuView.swift     # Dropdown menu
├── Services/
│   ├── UsageService.swift        # Anthropic API client
│   ├── KeychainService.swift     # Keychain access
│   └── LaunchAtLoginManager.swift
├── Models/
│   └── UsageResponse.swift       # API response models
└── Utilities/
    └── DateExtensions.swift      # Date formatting helpers
```

## Privacy

- All credentials remain on your device in the macOS keychain
- No data is collected or transmitted beyond the Anthropic API
- No analytics or tracking

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

Built for use with [Claude Code](https://claude.ai/code) by Anthropic.
