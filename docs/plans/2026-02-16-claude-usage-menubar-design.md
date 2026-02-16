# Claude Code Usage Menu Bar App - Design Document

**Date:** 2026-02-16
**Status:** Approved

## Overview

A native macOS menu bar application that displays Claude Code subscription usage limits, leveraging the existing Claude Code CLI authentication.

## Requirements

### Functional
- Display 5-hour window usage percentage and time until reset in menu bar
- Show detailed 7-day usage stats in popup menu
- Display subscription type (Pro, Max, etc.)
- Refresh data every 60 seconds
- Launch at login option
- Quick link to open Claude Code CLI

### Non-Functional
- Native macOS look and feel
- Minimal resource usage
- Works with Claude Code CLI authentication (no separate login)

## Technical Approach

**Technology:** Swift + SwiftUI with MenuBarExtra (macOS 13+)

### Auth Token Location
- **Source:** macOS Keychain
- **Service:** `"Claude Code-credentials"`
- **Command:** `security find-generic-password -s "Claude Code-credentials" -w`
- **Token path:** `claudeAiOauth.accessToken`

### API Endpoint
- **URL:** `https://api.anthropic.com/api/oauth/usage`
- **Method:** GET
- **Headers:**
  - `Authorization: Bearer {token}`
  - `anthropic-beta: oauth-2025-04-20`
  - `User-Agent: claude-code/2.0.32`

### API Response Structure
```json
{
  "five_hour": {
    "utilization": 30.0,
    "resets_at": "2026-02-16T12:00:00.000000+00:00"
  },
  "seven_day": {
    "utilization": 45.0,
    "resets_at": "2026-02-23T03:00:00.000000+00:00"
  },
  "seven_day_oauth_apps": null,
  "seven_day_opus": {
    "utilization": 0.0,
    "resets_at": null
  }
}
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Menu Bar App                         │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌──────────────┐    ┌───────────┐  │
│  │ Keychain    │───>│ UsageService │───>│ ViewModel │  │
│  │ (Auth)      │    │ (API calls)  │    │ (State)   │  │
│  └─────────────┘    └──────────────┘    └───────────┘  │
│                              │                 │        │
│                              v                 v        │
│                      ┌──────────────┐    ┌─────────┐   │
│                      │ Timer (1min) │    │  Views  │   │
│                      └──────────────┘    └─────────┘   │
└─────────────────────────────────────────────────────────┘
```

## File Structure

```
ClaudeUsage/
├── ClaudeUsageApp.swift        # App entry point, MenuBarExtra setup
├── Models/
│   └── UsageResponse.swift     # Codable structs for API response
├── Services/
│   ├── KeychainService.swift   # Security framework wrapper
│   └── UsageService.swift      # URLSession API client
├── ViewModels/
│   └── UsageViewModel.swift    # ObservableObject, timer, state
├── Views/
│   ├── MenuBarLabelView.swift  # Menu bar text display
│   └── MenuBarMenuView.swift   # Popup menu content
├── Utilities/
│   └── DateExtensions.swift    # Time formatting helpers
└── Resources/
    └── Assets.xcassets         # App icon
```

## UI Design

### Menu Bar Display
```
CC: 30% [1h 20m]
```
- Prefix: `CC:` for Claude Code
- Percentage from `five_hour.utilization`
- Time remaining calculated from `resets_at` timestamp
- Color coding:
  - Green: <50%
  - Yellow: 50-80%
  - Red: >80%

### Popup Menu
- 5-Hour Window section with progress bar and reset time
- 7-Day Window section with progress bar and reset date
- Subscription type display
- Last refresh timestamp
- "Open Claude Code" action button
- "Launch at Login" toggle
- "Quit" option

## Error Handling

| Scenario | Behavior |
|----------|----------|
| No credentials | Display "Not logged in" |
| API error | Show "Error fetching" + retry |
| Network offline | Show cached data + "Offline" |
| Token expired | Show last data + warning |

## Dependencies

- macOS 13.0+ (Ventura)
- Xcode 15.0+
- Swift 5.9+

## References

- [Anthropic Rate Limits Docs](https://platform.claude.com/docs/en/api/rate-limits)
- [Usage API Discovery](https://codelynx.dev/posts/claude-code-usage-limits-statusline)
