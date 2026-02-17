// Sources/AIUsageBar/Utilities/DateExtensions.swift

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

    func formattedResetTime() -> String {
        let timeZone = TimeZone.current
        let timeZoneName = timeZone.identifier

        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Locale.current

        let calendar = Calendar.current
        let now = Date()

        // Check if reset is today
        if calendar.isDate(self, inSameDayAs: now) {
            formatter.dateFormat = "ha"
            return "Resets \(formatter.string(from: self).lowercased()) (\(timeZoneName))"
        }

        // Check if reset is within 7 days
        let daysUntil = calendar.dateComponents([.day], from: now, to: self).day ?? 0
        if daysUntil < 7 {
            formatter.dateFormat = "MMM d 'at' ha"
            return "Resets \(formatter.string(from: self)) (\(timeZoneName))"
        }

        // Otherwise just show date
        formatter.dateFormat = "MMM d"
        return "Resets \(formatter.string(from: self)) (\(timeZoneName))"
    }

    func formattedMonthlyReset() -> String {
        let timeZone = TimeZone.current
        let timeZoneName = timeZone.identifier

        let calendar = Calendar.current
        let now = Date()

        // Get first day of next month
        let components = calendar.dateComponents([.year, .month], from: now)
        var nextMonth = components
        nextMonth.month! += 1

        guard let resetDate = calendar.date(from: nextMonth) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "MMM d"

        return "Resets \(formatter.string(from: resetDate)) (\(timeZoneName))"
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
