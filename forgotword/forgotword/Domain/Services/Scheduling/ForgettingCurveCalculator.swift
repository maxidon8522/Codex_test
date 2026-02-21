import Foundation

/// Generates forgetting-curve retention estimates for study items using
/// the classic Ebbinghaus data points as a baseline.
struct ForgettingCurveCalculator {
    struct Sample: Identifiable {
        let date: Date
        let retention: Double

        var id: Date { date }
    }

    private struct CurvePoint {
        let time: TimeInterval
        let retention: Double
    }

    private let day: TimeInterval = 86_400
    private let ebbinghausCurve: [CurvePoint] = [
        .init(time: 0, retention: 1.0),
        .init(time: 20 * 60, retention: 0.58),
        .init(time: 60 * 60, retention: 0.44),
        .init(time: 24 * 60 * 60, retention: 0.34),
        .init(time: 6 * 24 * 60 * 60, retention: 0.25),
        .init(time: 30 * 24 * 60 * 60, retention: 0.21)
    ]

    var tailRetentionFloor: Double = 0.10
    var tailHalfLifeDays: Double = 60
    var minimumInterval: TimeInterval = 15 * 60

    func retentionPercentage(for item: StudyItem, at date: Date) -> Double {
        let lastReview = item.history.last?.timestamp ?? item.createdAt
        let elapsed = max(0, date.timeIntervalSince(lastReview))
        if elapsed <= 0 { return 100 }

        let adjustedElapsed = adjustedElapsed(for: item, elapsed: elapsed)
        let retention = retentionValue(forElapsed: adjustedElapsed)
        return max(0, min(100, retention * 100))
    }

    func samples(
        for item: StudyItem,
        now: Date,
        sampleCount: Int = 24,
        horizonMultiplier: Double = 0.5
    ) -> [Sample] {
        guard sampleCount > 1 else { return [] }

        let lastReview = item.history.last?.timestamp ?? item.createdAt
        let due = item.nextDueAt
        let baseInterval = max(due.timeIntervalSince(lastReview), minimumInterval)
        let horizonInterval = baseInterval * max(1.0 + horizonMultiplier, 1.0)
        let horizonDate = lastReview.addingTimeInterval(horizonInterval)
        let finalEnd = max(horizonDate, now)

        let totalInterval = finalEnd.timeIntervalSince(lastReview)
        guard totalInterval > 0 else { return [] }

        let step = totalInterval / Double(sampleCount - 1)
        return (0..<sampleCount).map { index in
            let pointDate = lastReview.addingTimeInterval(Double(index) * step)
            let retention = retentionPercentage(for: item, at: pointDate)
            return Sample(date: pointDate, retention: retention)
        }
    }

    private func adjustedElapsed(for item: StudyItem, elapsed: TimeInterval) -> TimeInterval {
        let multiplier = max(item.profile.multiplier, 0.25)
        return elapsed / multiplier
    }

    private func retentionValue(forElapsed elapsed: TimeInterval) -> Double {
        guard let first = ebbinghausCurve.first else { return 1.0 }
        if elapsed <= first.time { return first.retention }

        for index in 1..<ebbinghausCurve.count {
            let current = ebbinghausCurve[index]
            let previous = ebbinghausCurve[index - 1]
            if elapsed <= current.time {
                let ratio = (elapsed - previous.time) / (current.time - previous.time)
                let interpolated = previous.retention + (current.retention - previous.retention) * ratio
                return max(0, min(1, interpolated))
            }
        }

        guard let last = ebbinghausCurve.last else { return 0 }
        let tailElapsed = elapsed - last.time
        if tailElapsed <= 0 { return last.retention }

        let halfLife = max(tailHalfLifeDays * day, day)
        let lambda = log(2) / halfLife
        let decayed = last.retention * exp(-lambda * tailElapsed)
        return max(tailRetentionFloor, min(1, decayed))
    }
}
