// Sources/ClaudeUsage/Views/MenuBarLabelView.swift

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
