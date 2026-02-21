import Foundation

struct NotificationPlanner {
    private let itemRepository: any ItemRepository
    private let settingsStore: any SettingsStore
    private let batchAligner: BatchAligner
    private let notificationScheduler: any NotificationScheduling
    private var calendar: Calendar

    private static let identifierFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMddHHmm"
        return formatter
    }()

    init(
        itemRepository: any ItemRepository,
        settingsStore: any SettingsStore,
        batchAligner: BatchAligner,
        notificationScheduler: any NotificationScheduling,
        calendar: Calendar = {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = .current
            return calendar
        }()
    ) {
        self.itemRepository = itemRepository
        self.settingsStore = settingsStore
        self.batchAligner = batchAligner
        self.notificationScheduler = notificationScheduler
        self.calendar = calendar
    }

    func regeneratePendingNotifications(now: Date) async throws {
        let settings = try await settingsStore.loadSettings()
        let startOfDay = calendar.startOfDay(for: now)
        guard let horizon = calendar.date(byAdding: .day, value: 7, to: startOfDay) else {
            return
        }

        let dueItems = try await itemRepository.fetchDueItems(until: horizon)
        let totalPending = dueItems.count

        let existing = try await notificationScheduler.currentBatches()
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        guard !dueItems.isEmpty else {
            if !existing.isEmpty {
                let identifiers = existing.map { $0.id }
                try await notificationScheduler.remove(identifiers: identifiers)
            }
            return
        }

        var grouped: [Date: [StudyItem]] = [:]
        for item in dueItems {
            let anchor = batchAligner.align(date: item.nextDueAt, settings: settings)
            grouped[anchor, default: []].append(item)
        }

        var notifications: [ReviewBatchNotification] = []
        let sortedAnchors = grouped.keys.sorted()
        for anchor in sortedAnchors {
            guard let items = grouped[anchor] else { continue }
            let sortedItems = items.sorted { lhs, rhs in
                if lhs.nextDueAt == rhs.nextDueAt {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.nextDueAt < rhs.nextDueAt
            }
            let preview = sortedItems.prefix(3).map { "\($0.deck) \($0.rangeText)" }.joined(separator: ", ")
            let body = preview.isEmpty ? "Priority: -" : "Priority: \(preview)"
            let notification = ReviewBatchNotification(
                id: Self.makeIdentifier(for: anchor),
                fireDate: anchor,
                itemIDs: sortedItems.map(\.id),
                title: "今日の復習 (\(sortedItems.count)件)",
                body: body,
                badge: totalPending,
                categoryIdentifier: NotificationCategory.reviewBatch.rawValue
            )
            notifications.append(notification)
        }

        notifications.sort { $0.fireDate < $1.fireDate }

        let newIDs = Set(notifications.map(\.id))
        let staleIDs = existingByID.keys.filter { !newIDs.contains($0) }
        if !staleIDs.isEmpty {
            try await notificationScheduler.remove(identifiers: staleIDs)
        }

        let changedNotifications = notifications.filter { notification in
            guard let existing = existingByID[notification.id] else { return true }
            return existing != notification
        }

        if !changedNotifications.isEmpty {
            let identifiers = changedNotifications.map(\.id)
            try await notificationScheduler.remove(identifiers: identifiers)
            try await notificationScheduler.schedule(batches: changedNotifications)
        }
    }

    func handleSnooze(for notificationID: String, now: Date) async throws {
        let settings = try await settingsStore.loadSettings()
        let existing = try await notificationScheduler.currentBatches()
        guard let current = existing.first(where: { $0.id == notificationID }),
              let currentDate = Self.date(from: notificationID) else {
            return
        }

        let anchorsToday = batchAligner.anchors(for: currentDate, settings: settings)
        let nextAnchor: Date
        if let index = anchorsToday.firstIndex(of: currentDate), index + 1 < anchorsToday.count {
            nextAnchor = anchorsToday[index + 1]
        } else {
            nextAnchor = batchAligner.firstAnchorNextDay(after: currentDate, settings: settings)
        }

        let updated = ReviewBatchNotification(
            id: Self.makeIdentifier(for: nextAnchor),
            fireDate: nextAnchor,
            itemIDs: current.itemIDs,
            title: current.title,
            body: current.body,
            badge: current.badge,
            categoryIdentifier: current.categoryIdentifier
        )

        try await notificationScheduler.remove(identifiers: [notificationID, updated.id])
        try await notificationScheduler.schedule(batches: [updated])
    }

    private static func makeIdentifier(for date: Date) -> String {
        identifierFormatter.string(from: date)
    }

    private static func date(from identifier: String) -> Date? {
        identifierFormatter.date(from: identifier)
    }
}
