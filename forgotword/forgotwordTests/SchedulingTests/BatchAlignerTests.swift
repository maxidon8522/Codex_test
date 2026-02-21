import XCTest
@testable import forgotword

final class BatchAlignerTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 9 * 3_600)!
        return calendar
    }()

    private lazy var settings: UserSettings = {
        let window = UserSettings.NotificationWindow(
            startHour: 7,
            endHour: 22,
            dailyBatches: 3,
            batchTimes: [
                DateComponents(hour: 8, minute: 0),
                DateComponents(hour: 13, minute: 0),
                DateComponents(hour: 20, minute: 0)
            ]
        )
        return UserSettings(notificationWindow: window, defaultProfile: .standard, badgeEnabled: true)
    }()

    func testAlignsWithinWindowToNextBatch() {
        var aligner = BatchAligner()
        aligner.calendar = calendar

        let raw = date(year: 2024, month: 1, day: 1, hour: 7, minute: 30)
        let aligned = aligner.align(date: raw, settings: settings)
        let expected = date(year: 2024, month: 1, day: 1, hour: 8, minute: 0)
        XCTAssertEqual(aligned, expected)
    }

    func testAlignsMiddayToUpcomingBatch() {
        var aligner = BatchAligner()
        aligner.calendar = calendar

        let raw = date(year: 2024, month: 1, day: 1, hour: 12, minute: 59)
        let aligned = aligner.align(date: raw, settings: settings)
        let expected = date(year: 2024, month: 1, day: 1, hour: 13, minute: 0)
        XCTAssertEqual(aligned, expected)
    }

    func testAlignsLateNightToNextDayFirstBatch() {
        var aligner = BatchAligner()
        aligner.calendar = calendar

        let raw = date(year: 2024, month: 1, day: 1, hour: 21, minute: 50)
        let aligned = aligner.align(date: raw, settings: settings)
        let expected = date(year: 2024, month: 1, day: 2, hour: 8, minute: 0)
        XCTAssertEqual(aligned, expected)
    }

    private func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        comps.timeZone = calendar.timeZone
        return calendar.date(from: comps)!
    }
}
