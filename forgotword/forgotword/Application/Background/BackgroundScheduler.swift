import Foundation

final class BackgroundScheduler {
    static let refreshIdentifier = "com.forgotword.refresh"

    private let planner: NotificationPlanner

    init(planner: NotificationPlanner) {
        self.planner = planner
    }

    func register() {
        #if canImport(BackgroundTasks)
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.refreshIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handle(refreshTask)
        }
        #endif
    }

    func scheduleAppRefresh() {
        #if canImport(BackgroundTasks)
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Ignore submission errors in early development builds.
        }
        #endif
    }

    func handleAppLaunch() {
        register()
        scheduleAppRefresh()
        Task {
            try? await planner.regeneratePendingNotifications(now: Date())
        }
    }

    func handleForeground() {
        scheduleAppRefresh()
        Task {
            try? await planner.regeneratePendingNotifications(now: Date())
        }
    }

    #if canImport(BackgroundTasks)
    private func handle(_ task: BGAppRefreshTask) {
        scheduleAppRefresh()
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task {
            do {
                try await planner.regeneratePendingNotifications(now: Date())
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
    #endif
}

#if canImport(BackgroundTasks)
import BackgroundTasks
#endif
