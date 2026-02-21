import Foundation

/// Temporary scheduling implementation that will be replaced with the production logic in later steps.
struct StubSchedulingService: SchedulingService {
    func computeSchedule(request: SchedulingRequest) -> SchedulingResult {
        SchedulingResult(nextDueAt: request.createdAt, projectedSchedule: [request.createdAt])
    }

    func alignToNextBatch(date: Date, settings: UserSettings) -> Date {
        date
    }
}
