# Claude Usage - Menu Bar App

A native macOS menu bar app that displays your Claude Code subscription usage limits.

## Features

- Real-time usage monitoring in menu bar
- 5-hour and 7-day window stats
- Auto-refresh every 60 seconds
- Launch at login option
- Uses existing Claude Code CLI authentication

## Requirements

- macOS 13.0 (Ventura) or later
- Claude Code CLI installed and authenticated

## Installation

### Build from Source

```bash
cd ClaudeUsage
./build-app.sh
cp -r build/Claude\ Usage.app /Applications/
```

### Run Directly

```bash
cd ClaudeUsage
swift build -c release
.build/release/ClaudeUsage
```

## Usage

1. Make sure you're logged in via Claude Code CLI
2. Launch the app
3. View your usage in the menu bar: `CC: 30% [1h 20m]`
4. Click the menu bar item for detailed stats

## Troubleshooting

### "Not logged in" error

Run `claude` in terminal and complete the login flow first.

### App doesn't appear in menu bar

Check Console.app for error messages from "Claude Usage".

## License

MIT
