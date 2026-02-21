import Foundation

struct DefaultSchedulingService: SchedulingService {
    private let intervalEngine: IntervalEngine
    private let batchAligner: BatchAligner

    init(intervalEngine: IntervalEngine = IntervalEngine(), batchAligner: BatchAligner = BatchAligner()) {
        self.intervalEngine = intervalEngine
        self.batchAligner = batchAligner
    }

    func computeSchedule(request: SchedulingRequest) -> SchedulingResult {
        let rawNext = intervalEngine.dueDate(
            createdAt: request.createdAt,
            profile: request.profile,
            intervalIndex: request.currentIndex
        )
        let alignedNext = batchAligner.align(date: rawNext, settings: request.userSettings)

        let projectedRaw = intervalEngine.fullSchedule(
            createdAt: request.createdAt,
            profile: request.profile
        )

        let projected = projectedRaw.map { batchAligner.align(date: $0, settings: request.userSettings) }

        return SchedulingResult(nextDueAt: alignedNext, projectedSchedule: projected)
    }
}
