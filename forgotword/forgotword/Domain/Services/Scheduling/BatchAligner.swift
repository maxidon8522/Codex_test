import Foundation

/// Aligns raw due dates to the user-defined notification batches within a daily window.
struct BatchAligner {
    var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }()

    func align(date: Date, settings: UserSettings) -> Date {
        let window = settings.notificationWindow
        let batchTimes = normalizedBatchTimes(window: window)
        let startOfDay = calendar.startOfDay(for: date)
        let start = calendar.date(byAdding: .hour, value: window.startHour, to: startOfDay) ?? date
        let end = calendar.date(byAdding: .hour, value: window.endHour, to: startOfDay) ?? date

        let todaysAnchors = anchors(for: date, window: window, batchTimes: batchTimes)

        if date < start {
            return todaysAnchors.first ?? fallbackAnchor(nextFrom: startOfDay, window: window, batchTimes: batchTimes)
        }

        if (start...end).contains(date) {
            if let next = todaysAnchors.first(where: { $0 >= date }) {
                return next
            }
        }

        return fallbackAnchor(nextFrom: startOfDay, window: window, batchTimes: batchTimes)
    }

    func anchors(for date: Date, settings: UserSettings) -> [Date] {
        anchors(for: date, window: settings.notificationWindow, batchTimes: normalizedBatchTimes(window: settings.notificationWindow))
    }

    func firstAnchorNextDay(after date: Date, settings: UserSettings) -> Date {
        fallbackAnchor(nextFrom: calendar.startOfDay(for: date), window: settings.notificationWindow, batchTimes: normalizedBatchTimes(window: settings.notificationWindow))
    }

    private func normalizedBatchTimes(window: UserSettings.NotificationWindow) -> [DateComponents] {
        let ordered = window.batchTimes
            .sorted { lhs, rhs in
                let lhsHour = lhs.hour ?? 0
                let rhsHour = rhs.hour ?? 0
                if lhsHour == rhsHour {
                    return (lhs.minute ?? 0) < (rhs.minute ?? 0)
                }
                return lhsHour < rhsHour
            }
        let count = max(1, min(window.dailyBatches, ordered.count))
        return Array(ordered.prefix(count))
    }

    private func anchors(
        for date: Date,
        window: UserSettings.NotificationWindow,
        batchTimes: [DateComponents]
    ) -> [Date] {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return batchTimes.compactMap { components -> Date? in
            var merged = comps
            merged.hour = components.hour ?? window.startHour
            merged.minute = components.minute ?? 0
            merged.second = 0
            return calendar.date(from: merged)
        }
    }

    private func fallbackAnchor(
        nextFrom startOfDay: Date,
        window: UserSettings.NotificationWindow,
        batchTimes: [DateComponents]
    ) -> Date {
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        let nextComps = calendar.dateComponents([.year, .month, .day], from: nextDay)
        let first = batchTimes.first ?? DateComponents(hour: window.startHour, minute: 0)
        var merged = nextComps
        merged.hour = first.hour ?? window.startHour
        merged.minute = first.minute ?? 0
        merged.second = 0
        return calendar.date(from: merged) ?? nextDay
    }
}
