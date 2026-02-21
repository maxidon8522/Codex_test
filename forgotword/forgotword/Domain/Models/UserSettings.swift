import Foundation

/// Domain representation of notification and preference settings the user can configure.
struct UserSettings: Equatable {
    struct NotificationWindow: Equatable {
        var startHour: Int
        var endHour: Int
        var dailyBatches: Int
        var batchTimes: [DateComponents]

        static let `default` = NotificationWindow(
            startHour: 7,
            endHour: 22,
            dailyBatches: 1,
            batchTimes: [DateComponents(hour: 8)]
        )
    }

    var notificationWindow: NotificationWindow
    var defaultProfile: MemoryProfile
    var badgeEnabled: Bool

    static let `default` = UserSettings(
        notificationWindow: .default,
        defaultProfile: .standard,
        badgeEnabled: true
    )
}
