// Sources/AISubscriptionUsage/AISubscriptionUsageApp.swift

import SwiftUI

@main
struct AISubscriptionUsageApp: App {
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
