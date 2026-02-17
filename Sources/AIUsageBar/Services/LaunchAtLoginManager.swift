// Sources/AIUsageBar/Services/LaunchAtLoginManager.swift

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
            // Silently handle launch at login registration errors
            // Revert state to reflect actual status
            isEnabled = SMAppService.mainApp.status == .enabled
        }
    }
}
