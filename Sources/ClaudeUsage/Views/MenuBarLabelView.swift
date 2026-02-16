// Sources/AISubscriptionUsage/Views/MenuBarLabelView.swift

import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        Text(viewModel.menuBarText)
            .font(.system(size: 12, weight: .medium))
    }
}

#Preview {
    MenuBarLabelView(viewModel: UsageViewModel())
}
