#if canImport(UserNotifications)
import Foundation
@preconcurrency import UserNotifications

/// Bridges ReviewBatchNotification scheduling to UNUserNotificationCenter.
actor UserNotificationScheduler: NotificationScheduling {
    private let center: UserNotificationCenterProxy
    private var calendar: Calendar

    init(
        center: UserNotificationCenterProxy = UNUserNotificationCenterProxy(),
        calendar: Calendar = {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = .current
            return calendar
        }()
    ) {
        self.center = center
        self.calendar = calendar
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        let status = await center.authorizationStatus()
        switch status {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        case .ephemeral:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }

    func schedule(batches: [ReviewBatchNotification]) async throws {
        for batch in batches {
            let content = makeContent(from: batch)
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: batch.fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: batch.id,
                content: content,
                trigger: trigger
            )
            try await center.add(request)
        }
    }

    func remove(identifiers: [String]) async throws {
        guard !identifiers.isEmpty else { return }
        await center.removePending(with: identifiers)
        await center.removeDelivered(with: identifiers)
    }

    func currentBatches() async throws -> [ReviewBatchNotification] {
        let requests = await center.pendingRequests()
        var notifications: [ReviewBatchNotification] = []

        for request in requests {
            guard request.content.categoryIdentifier == NotificationCategory.reviewBatch.rawValue else {
                continue
            }

            guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
                  let fireDate = trigger.nextTriggerDate()
            else {
                continue
            }

            let badgeValue = request.content.badge?.intValue ?? 0
            let itemIDs = Self.extractItemIDs(from: request.content.userInfo)

            guard !itemIDs.isEmpty else { continue }

            let notification = ReviewBatchNotification(
                id: request.identifier,
                fireDate: fireDate,
                itemIDs: itemIDs,
                title: request.content.title,
                body: request.content.body,
                badge: badgeValue,
                categoryIdentifier: request.content.categoryIdentifier
            )
            notifications.append(notification)
        }

        notifications.sort { $0.fireDate < $1.fireDate }
        return notifications
    }

    func cancelAllScheduledBatches() async throws {
        await center.removeAllPending()
        await center.removeAllDelivered()
    }

    private func makeContent(from batch: ReviewBatchNotification) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = batch.title
        content.body = batch.body
        content.badge = NSNumber(value: batch.badge)
        content.categoryIdentifier = batch.categoryIdentifier
        content.sound = .default
        content.userInfo = [
            NotificationUserInfoKey.itemIDs: batch.itemIDs.map(\.uuidString)
        ]
        return content
    }

    private static func extractItemIDs(from userInfo: [AnyHashable: Any]) -> [UUID] {
        guard let raw = userInfo[NotificationUserInfoKey.itemIDs] as? [String] else {
            return []
        }
        return raw.compactMap(UUID.init(uuidString:))
    }
}

/// Keys stored inside the notification userInfo payload.
private enum NotificationUserInfoKey {
    static let itemIDs = "item_ids"
}

/// Abstraction over UNUserNotificationCenter to improve testability.
protocol UserNotificationCenterProxy: Sendable {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func authorizationStatus() async -> UNAuthorizationStatus
    func add(_ request: UNNotificationRequest) async throws
    func pendingRequests() async -> [UNNotificationRequest]
    func removePending(with identifiers: [String]) async
    func removeDelivered(with identifiers: [String]) async
    func removeAllPending() async
    func removeAllDelivered() async
}

/// Default proxy that forwards calls to UNUserNotificationCenter.
struct UNUserNotificationCenterProxy: @unchecked Sendable, UserNotificationCenterProxy {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            center.requestAuthorization(options: options) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { (continuation: CheckedContinuation<UNAuthorizationStatus, Never>) in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func pendingRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { (continuation: CheckedContinuation<[UNNotificationRequest], Never>) in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }

    func removePending(with identifiers: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func removeDelivered(with identifiers: [String]) async {
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func removeAllPending() async {
        center.removeAllPendingNotificationRequests()
    }

    func removeAllDelivered() async {
        center.removeAllDeliveredNotifications()
    }
}
#endif