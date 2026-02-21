import Foundation

/// Calculates raw due dates for study items based on the forgetting curve profile.
struct IntervalEngine {
    private let baseDays: [Double] = [0, 1, 3, 7, 16, 35, 90]

    func dueDate(
        createdAt: Date,
        profile: MemoryProfile,
        intervalIndex: Int
    ) -> Date {
        let clampedIndex = max(0, min(intervalIndex, baseDays.count - 1))
        let days = baseDays[clampedIndex] * profile.multiplier
        let interval = days * 86_400
        return createdAt.addingTimeInterval(interval)
    }

    func fullSchedule(
        createdAt: Date,
        profile: MemoryProfile
    ) -> [Date] {
        baseDays.enumerated().map { index, _ in
            dueDate(createdAt: createdAt, profile: profile, intervalIndex: index)
        }
    }
}
