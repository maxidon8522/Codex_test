import Foundation

struct SettingsSnapshot {
    var settings: UserSettings
}

/// Persisted user settings abstraction (UserDefaults, CoreData, etc.).
protocol SettingsStore {
    func loadSettings() async throws -> UserSettings
    func loadSnapshot() async throws -> SettingsSnapshot
    func save(settings: UserSettings) async throws
    func observeSettings() -> AsyncStream<UserSettings>
}
