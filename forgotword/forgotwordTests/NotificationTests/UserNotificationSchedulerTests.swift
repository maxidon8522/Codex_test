#if canImport(UserNotifications)
import XCTest
import UserNotifications
@testable import forgotword

final class UserNotificationSchedulerTests: XCTestCase {
    func testSchedulePersistsBatchesAsRequests() async throws {
        let center = RecordingNotificationCenterProxy()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 9 * 3_600)!
        let scheduler = UserNotificationScheduler(center: center, calendar: calendar)

        let fireDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 8, minute: 30))!
        let batch = ReviewBatchNotification(
            id: "batch_20240101_0830",
            fireDate: fireDate,
            itemIDs: [UUID(), UUID()],
            title: "今日の復習 (2件)",
            body: "Priority: Deck A",
            badge: 5,
            categoryIdentifier: NotificationCategory.reviewBatch.rawValue
        )

        try await scheduler.schedule(batches: [batch])

        let requests = await center.pendingRequests()
        XCTAssertEqual(requests.count, 1)
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.identifier, batch.id)
        XCTAssertEqual(request.content.title, batch.title)
        XCTAssertEqual(request.content.body, batch.body)
        XCTAssertEqual(request.content.categoryIdentifier, batch.categoryIdentifier)
        XCTAssertEqual(request.content.badge?.intValue, batch.badge)
        let storedIDs = request.content.userInfo["item_ids"] as? [String]
        XCTAssertEqual(storedIDs, batch.itemIDs.map(\.uuidString))
        let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
        XCTAssertEqual(trigger.nextTriggerDate(), batch.fireDate)
    }

    func testCurrentBatchesReflectsPendingRequests() async throws {
        let center = RecordingNotificationCenterProxy()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let scheduler = UserNotificationScheduler(center: center, calendar: calendar)

        let fireDate = calendar.date(from: DateComponents(year: 2024, month: 5, day: 1, hour: 12, minute: 0))!
        let batch = ReviewBatchNotification(
            id: "batch_20240501_1200",
            fireDate: fireDate,
            itemIDs: [UUID()],
            title: "Reminder",
            body: "Priority: Deck B",
            badge: 3,
            categoryIdentifier: NotificationCategory.reviewBatch.rawValue
        )

        try await scheduler.schedule(batches: [batch])

        let pending = try await scheduler.currentBatches()
        XCTAssertEqual(pending, [batch])
    }

    func testRemoveDeletesMatchingRequests() async throws {
        let center = RecordingNotificationCenterProxy()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let scheduler = UserNotificationScheduler(center: center, calendar: calendar)

        let fireDate = calendar.date(from: DateComponents(year: 2024, month: 6, day: 1, hour: 9, minute: 0))!
        let batch = ReviewBatchNotification(
            id: "batch_remove",
            fireDate: fireDate,
            itemIDs: [UUID()],
            title: "Remove",
            body: "Body",
            badge: 1,
            categoryIdentifier: NotificationCategory.reviewBatch.rawValue
        )

        try await scheduler.schedule(batches: [batch])
        try await scheduler.remove(identifiers: [batch.id])

        let requests = await center.pendingRequests()
        XCTAssertTrue(requests.isEmpty)
        let removeCalls = await center.removePendingInvocations()
        XCTAssertEqual(removeCalls, [[batch.id]])
    }

    func testCancelAllClearsPendingAndDelivered() async throws {
        let center = RecordingNotificationCenterProxy()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let scheduler = UserNotificationScheduler(center: center, calendar: calendar)

        let fireDate = calendar.date(from: DateComponents(year: 2024, month: 7, day: 1, hour: 7, minute: 0))!
        let batch = ReviewBatchNotification(
            id: "batch_cancel",
            fireDate: fireDate,
            itemIDs: [UUID()],
            title: "Cancel",
            body: "Body",
            badge: 2,
            categoryIdentifier: NotificationCategory.reviewBatch.rawValue
        )

        try await scheduler.schedule(batches: [batch])
        try await scheduler.cancelAllScheduledBatches()

        let pending = await center.pendingRequests()
        XCTAssertTrue(pending.isEmpty)
        let pendingCount = await center.removeAllPendingInvocationCount()
        let deliveredCount = await center.removeAllDeliveredInvocationCount()
        XCTAssertEqual(pendingCount, 1)
        XCTAssertEqual(deliveredCount, 1)
    }

    func testAuthorizationStatusMapping() async {
        let center = RecordingNotificationCenterProxy()
        let scheduler = UserNotificationScheduler(center: center)

        await center.setStatus(.provisional)
        let provisional = await scheduler.authorizationStatus()
        XCTAssertEqual(provisional, .provisional)

        await center.setStatus(.denied)
        let denied = await scheduler.authorizationStatus()
        XCTAssertEqual(denied, .denied)
    }

    func testRequestAuthorizationPropagatesErrors() async {
        struct TestError: Error {}
        let center = RecordingNotificationCenterProxy()
        let scheduler = UserNotificationScheduler(center: center)

        await center.setAuthorizationResult(.success(true))
        let granted = try? await scheduler.requestAuthorization()
        XCTAssertEqual(granted, true)

        await center.setAuthorizationResult(.failure(TestError()))
        do {
            _ = try await scheduler.requestAuthorization()
            XCTFail("Expected to throw")
        } catch is TestError {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private actor RecordingNotificationCenterProxy: UserNotificationCenterProxy {
    private var authorizationResult: Result<Bool, Error> = .success(true)
    private var status: UNAuthorizationStatus = .notDetermined
    private var requests: [UNNotificationRequest] = []
    private var removePendingCalls: [[String]] = []
    private var removeDeliveredCalls: [[String]] = []
    private var removeAllPendingCount = 0
    private var removeAllDeliveredCount = 0

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try authorizationResult.get()
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        status
    }

    func add(_ request: UNNotificationRequest) async throws {
        requests.removeAll { $0.identifier == request.identifier }
        requests.append(request)
    }

    func pendingRequests() async -> [UNNotificationRequest] {
        requests
    }

    func removePending(with identifiers: [String]) async {
        removePendingCalls.append(identifiers)
        requests.removeAll { identifiers.contains($0.identifier) }
    }

    func removeDelivered(with identifiers: [String]) async {
        removeDeliveredCalls.append(identifiers)
    }

    func removeAllPending() async {
        removeAllPendingCount += 1
        requests.removeAll()
    }

    func removeAllDelivered() async {
        removeAllDeliveredCount += 1
    }

    func removePendingInvocations() async -> [[String]] {
        removePendingCalls
    }

    func removeDeliveredInvocations() async -> [[String]] {
        removeDeliveredCalls
    }

    func removeAllPendingInvocationCount() async -> Int {
        removeAllPendingCount
    }

    func removeAllDeliveredInvocationCount() async -> Int {
        removeAllDeliveredCount
    }

    func setAuthorizationResult(_ result: Result<Bool, Error>) async {
        authorizationResult = result
    }

    func setStatus(_ newStatus: UNAuthorizationStatus) async {
        status = newStatus
    }
}
#endif
