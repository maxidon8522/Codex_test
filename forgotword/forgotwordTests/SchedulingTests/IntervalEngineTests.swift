import XCTest
@testable import forgotword

final class IntervalEngineTests: XCTestCase {
    func testDueDatesFollowProfileMultipliers() {
        let engine = IntervalEngine()
        let baseDays: [Double] = [0, 1, 3, 7, 16, 35, 90]
        let createdAt = Date(timeIntervalSinceReferenceDate: 0)

        for profile in MemoryProfile.allCases {
            for (index, base) in baseDays.enumerated() {
                let due = engine.dueDate(
                    createdAt: createdAt,
                    profile: profile,
                    intervalIndex: index
                )
                let expected = createdAt.addingTimeInterval(base * profile.multiplier * 86_400)
                XCTAssertEqual(due, expected, "Profile: \(profile), index: \(index)")
            }
        }
    }

    func testIntervalIndexIsClamped() {
        let engine = IntervalEngine()
        let createdAt = Date()
        let due = engine.dueDate(
            createdAt: createdAt,
            profile: .standard,
            intervalIndex: 999
        )
        let expected = engine.dueDate(
            createdAt: createdAt,
            profile: .standard,
            intervalIndex: 6
        )
        XCTAssertEqual(due, expected)
    }
}
