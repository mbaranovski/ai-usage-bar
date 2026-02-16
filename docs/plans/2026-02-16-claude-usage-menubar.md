# Claude Code Usage Menu Bar App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native macOS menu bar app that displays Claude Code subscription usage limits using existing CLI authentication.

**Architecture:** SwiftUI app using MenuBarExtra for menu bar integration. KeychainService retrieves OAuth token from macOS Keychain. UsageService calls Anthropic's `/api/oauth/usage` endpoint. UsageViewModel manages state and 60-second refresh timer.

**Tech Stack:** Swift 5.9, SwiftUI, macOS 13+ (MenuBarExtra), Security framework (Keychain), URLSession

---

## Task 1: Create Xcode Project

**Files:**
- Create: `ClaudeUsage/ClaudeUsage.xcodeproj`
- Create: `ClaudeUsage/ClaudeUsageApp.swift`

**Step 1: Create Xcode project directory**

```bash
mkdir -p ClaudeUsage
```

**Step 2: Create Xcode project using swiftc**

Since we can't invoke Xcode GUI, create the project structure manually:

```bash
cd ClaudeUsage
mkdir -p ClaudeUsage.xcodeproj
mkdir -p ClaudeUsage/Models
mkdir -p ClaudeUsage/Services
mkdir -p ClaudeUsage/ViewModels
mkdir -p ClaudeUsage/Views
mkdir -p ClaudeUsage/Utilities
mkdir -p ClaudeUsage/Resources
```

**Step 3: Create project.pbxproj file**

Create `ClaudeUsage/ClaudeUsage.xcodeproj/project.pbxproj` with the Xcode project configuration. This is a large file - we'll generate it using `xcodebuild` or create a minimal Swift Package.

**Alternative Step 3: Use Swift Package with executable**

For simplicity, create a Swift Package that builds a macOS app:

```bash
cd ClaudeUsage
swift package init --type executable --name ClaudeUsage
```

**Step 4: Verify project structure**

```bash
ls -la ClaudeUsage/
```

Expected: `Package.swift`, `Sources/`, `Tests/` directories

**Step 5: Commit**

```bash
git add ClaudeUsage/
git commit -m "feat: initialize Swift package project structure"
```

---

## Task 2: Create Data Models

**Files:**
- Create: `ClaudeUsage/Sources/ClaudeUsage/Models/UsageResponse.swift`

**Step 1: Create Models directory**

```bash
mkdir -p ClaudeUsage/Sources/ClaudeUsage/Models
```

**Step 2: Write UsageResponse.swift**

```swift
// ClaudeUsage/Sources/ClaudeUsage/Models/UsageResponse.swift

import Foundation

struct UsageResponse: Codable {
    let fiveHour: UsageWindow?
    let sevenDay: UsageWindow?
    let sevenDayOauthApps: UsageWindow?
    let sevenDayOpus: UsageWindow?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDayOauthApps = "seven_day_oauth_apps"
        case sevenDayOpus = "seven_day_opus"
    }
}

struct UsageWindow: Codable {
    let utilization: Double
    let resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }

    var resetsAtDate: Date? {
        guard let resetsAt = resetsAt else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: resetsAt)
    }

    var timeRemaining: TimeInterval? {
        guard let date = resetsAtDate else { return nil }
        return date.timeIntervalSince(Date())
    }

    var formattedTimeRemaining: String {
        guard let remaining = timeRemaining, remaining > 0 else {
            return "0m"
        }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct Credentials: Codable {
    let claudeAiOauth: OAuthToken

    enum CodingKeys: String, CodingKey {
        case claudeAiOauth = "claudeAiOauth"
    }
}

struct OAuthToken: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Int?
    let scopes: [String]?
    let subscriptionType: String?

    enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case expiresAt
        case scopes
        case subscriptionType
    }
}
```

**Step 3: Build to verify**

```bash
cd ClaudeUsage && swift build 2>&1 | head -20
```

Expected: Build errors about missing files (expected - we haven't created them yet)

**Step 4: Commit**

```bash
git add ClaudeUsage/Sources/ClaudeUsage/Models/
git commit -m "feat: add UsageResponse and Credentials models"
```

---

## Task 3: Create Keychain Service

**Files:**
- Create: `ClaudeUsage/Sources/ClaudeUsage/Services/KeychainService.swift`

**Step 1: Create Services directory**

```bash
mkdir -p ClaudeUsage/Sources/ClaudeUsage/Services
```

**Step 2: Write KeychainService.swift**

```swift
// ClaudeUsage/Sources/ClaudeUsage/Services/KeychainService.swift

import Foundation
import Security

enum KeychainError: Error, LocalizedError {
    case itemNotFound
    case invalidData
    case unexpectedStatus(OSStatus)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Claude Code credentials not found in Keychain. Please login via Claude Code CLI first."
        case .invalidData:
            return "Invalid credential data in Keychain"
        case .unexpectedStatus(let status):
            return "Keychain error: \(status)"
        case .decodingError(let error):
            return "Failed to decode credentials: \(error.localizedDescription)"
        }
    }
}

class KeychainService {
    static let shared = KeychainService()

    private let service = "Claude Code-credentials"

    private init() {}

    func getCredentials() throws -> Credentials {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }

        do {
            let credentials = try JSONDecoder().decode(Credentials.self, from: data)
            return credentials
        } catch {
            throw KeychainError.decodingError(error)
        }
    }

    func getAccessToken() throws -> String {
        let credentials = try getCredentials()
        return credentials.claudeAiOauth.accessToken
    }
}
```

**Step 3: Build to verify**

```bash
cd ClaudeUsage && swift build 2>&1 | head -20
```

**Step 4: Commit**

```bash
git add ClaudeUsage/Sources/ClaudeUsage/Services/
git commit -m "feat: add KeychainService for credential retrieval"
```

---

## Task 4: Create Usage API Service

**Files:**
- Create: `ClaudeUsage/Sources/ClaudeUsage/Services/UsageService.swift`

**Step 1: Write UsageService.swift**

```swift
// ClaudeUsage/Sources/ClaudeUsage/Services/UsageService.swift

import Foundation

enum UsageServiceError: Error, LocalizedError {
    case noToken
    case networkError(Error)
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .noToken:
            return "No authentication token available"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        }
    }
}

class UsageService {
    static let shared = UsageService()

    private let apiURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    func fetchUsage() async throws -> UsageResponse {
        // Get token from keychain
        let token = try KeychainService.shared.getAccessToken()

        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("claude-code/2.0.32", forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw UsageServiceError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw UsageServiceError.httpError(httpResponse.statusCode)
            }

            let usageResponse = try JSONDecoder().decode(UsageResponse.self, from: data)
            return usageResponse
        } catch let error as UsageServiceError {
            throw error
        } catch {
            throw UsageServiceError.networkError(error)
        }
    }
}
```

**Step 2: Build to verify**

```bash
cd ClaudeUsage && swift build 2>&1 | head -20
```

**Step 3: Commit**

```bash
git add ClaudeUsage/Sources/ClaudeUsage/Services/UsageService.swift
git commit -m "feat: add UsageService for API calls"
```

---

## Task 5: Create Date Extensions

**Files:**
- Create: `ClaudeUsage/Sources/ClaudeUsage/Utilities/DateExtensions.swift`

**Step 1: Create Utilities directory**

```bash
mkdir -p ClaudeUsage/Sources/ClaudeUsage/Utilities
```

**Step 2: Write DateExtensions.swift**

```swift
// ClaudeUsage/Sources/ClaudeUsage/Utilities/DateExtensions.swift

import Foundation

extension Date {
    func formattedRelative() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    func formattedDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

extension TimeInterval {
    func formattedAsTimeRemaining() -> String {
        guard self > 0 else { return "0m" }

        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}
```

**Step 3: Build to verify**

```bash
cd ClaudeUsage && swift build 2>&1 | head -20
```

**Step 4: Commit**

```bash
git add ClaudeUsage/Sources/ClaudeUsage/Utilities/
git commit -m "feat: add Date and TimeInterval extensions"
```

---

## Task 6: Create Usage ViewModel

**Files:**
- Create: `ClaudeUsage/Sources/ClaudeUsage/ViewModels/UsageViewModel.swift`

**Step 1: Create ViewModels directory**

```bash
mkdir -p ClaudeUsage/Sources/ClaudeUsage/ViewModels
```

**Step 2: Write UsageViewModel.swift**

```swift
// ClaudeUsage/Sources/ClaudeUsage/ViewModels/UsageViewModel.swift

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
    private var refreshTimer: Timer?
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

    func stopAutoRefresh() {
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
        if let error = error {
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
```

**Step 3: Build to verify**

```bash
cd ClaudeUsage && swift build 2>&1 | head -20
```

**Step 4: Commit**

```bash
git add ClaudeUsage/Sources/ClaudeUsage/ViewModels/
git commit -m "feat: add UsageViewModel with auto-refresh"
```

---

## Task 7: Create Menu Bar Label View

**Files:**
- Create: `ClaudeUsage/Sources/ClaudeUsage/Views/MenuBarLabelView.swift`

**Step 1: Create Views directory**

```bash
mkdir -p ClaudeUsage/Sources/ClaudeUsage/Views
```

**Step 2: Write MenuBarLabelView.swift**

```swift
// ClaudeUsage/Sources/ClaudeUsage/Views/MenuBarLabelView.swift

import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "brain")
                .font(.system(size: 12))
            Text(viewModel.menuBarText)
                .font(.system(size: 12, weight: .medium))
        }
    }
}

#Preview {
    MenuBarLabelView(viewModel: UsageViewModel())
}
```

**Step 3: Build to verify**

```bash
cd ClaudeUsage && swift build 2>&1 | head -20
```

**Step 4: Commit**

```bash
git add ClaudeUsage/Sources/ClaudeUsage/Views/MenuBarLabelView.swift
git commit -m "feat: add MenuBarLabelView for menu bar display"
```

---

## Task 8: Create Menu Bar Menu View

**Files:**
- Create: `ClaudeUsage/Sources/ClaudeUsage/Views/MenuBarMenuView.swift`

**Step 1: Write MenuBarMenuView.swift**

```swift
// ClaudeUsage/Sources/ClaudeUsage/Views/MenuBarMenuView.swift

import SwiftUI

struct MenuBarMenuView: View {
    @ObservedObject var viewModel: UsageViewModel
    @AppStorage("launchAtLogin") var launchAtLogin = false

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

            Toggle("Launch at Login", isOn: $launchAtLogin)
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
```

**Step 2: Build to verify**

```bash
cd ClaudeUsage && swift build 2>&1 | head -20
```

**Step 3: Commit**

```bash
git add ClaudeUsage/Sources/ClaudeUsage/Views/MenuBarMenuView.swift
git commit -m "feat: add MenuBarMenuView with detailed stats"
```

---

## Task 9: Create Main App Entry Point

**Files:**
- Modify: `ClaudeUsage/Sources/main.swift` (rename/replace)
- Create: `ClaudeUsage/Sources/ClaudeUsage/ClaudeUsageApp.swift`

**Step 1: Write ClaudeUsageApp.swift**

```swift
// ClaudeUsage/Sources/ClaudeUsage/ClaudeUsageApp.swift

import SwiftUI

@main
struct ClaudeUsageApp: App {
    @StateObject private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenuView(viewModel: viewModel)
        } label: {
            MenuBarLabelView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
```

**Step 2: Update Package.swift for SwiftUI app**

Replace `ClaudeUsage/Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeUsage",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ClaudeUsage", targets: ["ClaudeUsage"])
    ],
    targets: [
        .executableTarget(
            name: "ClaudeUsage",
            path: "Sources/ClaudeUsage"
        )
    ]
)
```

**Step 3: Remove default main.swift**

```bash
rm -f ClaudeUsage/Sources/main.swift 2>/dev/null || true
```

**Step 4: Build to verify**

```bash
cd ClaudeUsage && swift build 2>&1
```

Expected: Successful build or clear error messages

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add main app entry point with MenuBarExtra"
```

---

## Task 10: Add Launch at Login Support

**Files:**
- Create: `ClaudeUsage/Sources/ClaudeUsage/Services/LaunchAtLoginManager.swift`

**Step 1: Write LaunchAtLoginManager.swift**

```swift
// ClaudeUsage/Sources/ClaudeUsage/Services/LaunchAtLoginManager.swift

import Foundation
import ServiceManagement

class LaunchAtLoginManager: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            updateLaunchAtLogin()
        }
    }

    init() {
        // Check current status
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    private func updateLaunchAtLogin() {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}
```

**Step 2: Update MenuBarMenuView to use LaunchAtLoginManager**

Add to `MenuBarMenuView.swift`:

```swift
// Add to the view
@ObservedObject var launchManager = LaunchAtLoginManager()

// Replace the Toggle with:
Toggle("Launch at Login", isOn: $launchManager.isEnabled)
    .toggleStyle(.checkbox)
```

**Step 3: Build to verify**

```bash
cd ClaudeUsage && swift build 2>&1
```

**Step 4: Commit**

```bash
git add ClaudeUsage/Sources/ClaudeUsage/Services/LaunchAtLoginManager.swift
git commit -m "feat: add Launch at Login support using ServiceManagement"
```

---

## Task 11: Create Info.plist and Entitlements

**Files:**
- Create: `ClaudeUsage/Resources/Info.plist`
- Create: `ClaudeUsage/Resources/ClaudeUsage.entitlements`

**Step 1: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>com.claudeusage.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Claude Usage</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright 2026. All rights reserved.</string>
    <key>NSMainStoryboardFile</key>
    <string></string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
```

**Step 2: Create entitlements for Keychain access**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
```

**Step 3: Commit**

```bash
git add ClaudeUsage/Resources/
git commit -m "feat: add Info.plist and entitlements"
```

---

## Task 12: Build and Test the App

**Step 1: Build the release version**

```bash
cd ClaudeUsage && swift build -c release 2>&1
```

**Step 2: Locate the built binary**

```bash
find ClaudeUsage/.build -name "ClaudeUsage" -type f 2>/dev/null
```

**Step 3: Run the app to test**

```bash
./ClaudeUsage/.build/release/ClaudeUsage 2>&1 &
```

**Step 4: Verify menu bar item appears**

- Check menu bar for "CC: X% [Xh Xm]" text
- Click to verify popup menu shows
- Check Console.app for any error messages

**Step 5: Kill the test process**

```bash
pkill -f ClaudeUsage || true
```

**Step 6: Commit final build configuration**

```bash
git add -A
git commit -m "build: verify release build works"
```

---

## Task 13: Create Build Script for Xcode Project

Since Swift Package apps don't have proper macOS app bundles, we need to create a proper .app bundle.

**Files:**
- Create: `ClaudeUsage/build-app.sh`

**Step 1: Write build script**

```bash
#!/bin/bash
# build-app.sh - Creates a proper macOS .app bundle

set -e

APP_NAME="Claude Usage"
BUNDLE_ID="com.claudeusage.app"
VERSION="1.0"
BUILD_NUM="1"

# Directories
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building $APP_NAME..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build with Swift
echo "Compiling..."
cd "$SCRIPT_DIR"
swift build -c release --arch arm64 --arch x86_64 2>&1 || swift build -c release 2>&1

# Create app bundle structure
echo "Creating app bundle..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp ".build/release/ClaudeUsage" "$MACOS_DIR/$APP_NAME"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Claude Usage</string>
    <key>CFBundleIdentifier</key>
    <string>com.claudeusage.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Claude Usage</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright 2026. All rights reserved.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo "App bundle created at: $APP_DIR"
echo "To install: cp -r '$APP_DIR' /Applications/"
```

**Step 2: Make script executable**

```bash
chmod +x ClaudeUsage/build-app.sh
```

**Step 3: Run build script**

```bash
./ClaudeUsage/build-app.sh
```

**Step 4: Test the app bundle**

```bash
open ClaudeUsage/build/Claude\ Usage.app
```

**Step 5: Commit**

```bash
git add ClaudeUsage/build-app.sh
git commit -m "feat: add build script for .app bundle creation"
```

---

## Task 14: Create README

**Files:**
- Create: `ClaudeUsage/README.md`

**Step 1: Write README**

```markdown
# Claude Usage - Menu Bar App

A native macOS menu bar app that displays your Claude Code subscription usage limits.

## Features

- 📊 Real-time usage monitoring in menu bar
- ⏱️ 5-hour and 7-day window stats
- 🔄 Auto-refresh every 60 seconds
- 🚀 Launch at login option
- 🔐 Uses existing Claude Code CLI authentication

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
```

**Step 2: Commit**

```bash
git add ClaudeUsage/README.md
git commit -m "docs: add README with installation instructions"
```

---

## Summary

| Task | Description | Status |
|------|-------------|--------|
| 1 | Create Xcode Project | Pending |
| 2 | Create Data Models | Pending |
| 3 | Create Keychain Service | Pending |
| 4 | Create Usage API Service | Pending |
| 5 | Create Date Extensions | Pending |
| 6 | Create Usage ViewModel | Pending |
| 7 | Create Menu Bar Label View | Pending |
| 8 | Create Menu Bar Menu View | Pending |
| 9 | Create Main App Entry Point | Pending |
| 10 | Add Launch at Login Support | Pending |
| 11 | Create Info.plist and Entitlements | Pending |
| 12 | Build and Test the App | Pending |
| 13 | Create Build Script | Pending |
| 14 | Create README | Pending |

**Total: 14 tasks**
