// Sources/ClaudeUsage/ClaudeUsageApp.swift

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
