import Foundation

actor InMemorySettingsStore: SettingsStore {
    private var settings: UserSettings
    private var observers: [UUID: AsyncStream<UserSettings>.Continuation] = [:]

    init(initial: UserSettings = .default) {
        self.settings = initial
    }

    func loadSettings() async throws -> UserSettings {
        settings
    }

    func loadSnapshot() async throws -> SettingsSnapshot {
        SettingsSnapshot(settings: settings)
    }

    func save(settings: UserSettings) async throws {
        self.settings = settings
        broadcast()
    }

    nonisolated func observeSettings() -> AsyncStream<UserSettings> {
        AsyncStream { continuation in
            Task { await self.registerObserver(continuation: continuation) }
        }
    }

    private func registerObserver(continuation: AsyncStream<UserSettings>.Continuation) {
        let token = UUID()
        observers[token] = continuation
        continuation.onTermination = { [weak self] _ in
            guard let self else { return }
            Task { await self.removeObserver(token: token) }
        }
        continuation.yield(settings)
    }

    private func broadcast() {
        for continuation in observers.values {
            continuation.yield(settings)
        }
    }

    private func removeObserver(token: UUID) {
        observers.removeValue(forKey: token)
    }
}
