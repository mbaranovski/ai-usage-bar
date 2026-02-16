// Sources/ClaudeUsage/Services/LaunchAtLoginManager.swift

import Foundation
import ServiceManagement

@MainActor
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
