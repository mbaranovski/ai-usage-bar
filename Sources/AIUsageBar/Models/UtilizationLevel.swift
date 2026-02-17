// Sources/AIUsageBar/Models/UtilizationLevel.swift

import Foundation

/// Represents the severity level of resource utilization
enum UtilizationLevel {
    case normal    // Under 50%
    case warning   // 50-79%
    case critical  // 80% and above
}
