// Sources/AIUsageBar/Views/MenuBarLabelView.swift

import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        if viewModel.error != nil {
            Text("CC·Error")
                .font(.system(size: 12, weight: .medium))
        } else {
            Text("CC•\(Int(viewModel.fiveHourUtilization))%·\(viewModel.fiveHourHoursRemaining)h\(viewModel.fiveHourMinutesRemaining)m")
                .font(.system(size: 12, weight: .medium))
        }
    }
}

#Preview {
    MenuBarLabelView(viewModel: UsageViewModel())
}
