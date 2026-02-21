import Foundation

struct SchedulingRequest {
    var createdAt: Date
    var currentIndex: Int
    var profile: MemoryProfile
    var userSettings: UserSettings
}

struct SchedulingResult {
    var nextDueAt: Date
    var projectedSchedule: [Date]
}

protocol SchedulingService {
    func computeSchedule(request: SchedulingRequest) -> SchedulingResult
}

/// Handles review completion, interval progression, and notification refresh.
struct ReviewService {
    enum Error: Swift.Error, Equatable {
        case itemNotFound
        case itemArchived
    }

    private let itemRepository: any ItemRepository
    private let schedulingService: any SchedulingService
    private let settingsStore: any SettingsStore
    private let regenerateNotifications: @Sendable (Date) async throws -> Void

    init(
        itemRepository: any ItemRepository,
        schedulingService: any SchedulingService,
        settingsStore: any SettingsStore,
        regenerateNotifications: @escaping @Sendable (Date) async throws -> Void
    ) {
        self.itemRepository = itemRepository
        self.schedulingService = schedulingService
        self.settingsStore = settingsStore
        self.regenerateNotifications = regenerateNotifications
    }

    /// Records the review result, advances the interval, and refreshes notifications.
    func record(
        itemID: UUID,
        feedback: StudyItem.ReviewHistoryEntry.Result,
        now: Date = Date()
    ) async throws {
        guard var item = try await itemRepository.item(with: itemID) else {
            throw Error.itemNotFound
        }
        guard !item.isArchived else {
            throw Error.itemArchived
        }

        let updatedIndex: Int
        switch feedback {
        case .bad:
            updatedIndex = max(0, item.intervalIndex - 1)
        case .good:
            updatedIndex = item.intervalIndex + 1
        case .great:
            updatedIndex = item.intervalIndex + 2
        }

        let historyEntry = StudyItem.ReviewHistoryEntry(
            id: UUID(),
            timestamp: now,
            result: feedback
        )

        let settings = try await settingsStore.loadSettings()
        let schedule = schedulingService.computeSchedule(
            request: SchedulingRequest(
                createdAt: item.createdAt,
                currentIndex: updatedIndex,
                profile: item.profile,
                userSettings: settings
            )
        )

        item.intervalIndex = updatedIndex
        item.nextDueAt = schedule.nextDueAt
        item.history.append(historyEntry)

        try await itemRepository.save(item)
        try await regenerateNotifications(now)
    }
}

/// Creates new study items applying scheduling rules and notification refresh.
struct ItemCreationService {
    enum Error: Swift.Error, Equatable {
        case deckRequired
        case rangeRequired
        case limitReached
    }

    private let itemRepository: any ItemRepository
    private let schedulingService: any SchedulingService
    private let settingsStore: any SettingsStore
    private let regenerateNotifications: @Sendable (Date) async throws -> Void
    private let maxActiveItems: Int

    init(
        itemRepository: any ItemRepository,
        schedulingService: any SchedulingService,
        settingsStore: any SettingsStore,
        regenerateNotifications: @escaping @Sendable (Date) async throws -> Void,
        maxActiveItems: Int = 10
    ) {
        self.itemRepository = itemRepository
        self.schedulingService = schedulingService
        self.settingsStore = settingsStore
        self.regenerateNotifications = regenerateNotifications
        self.maxActiveItems = maxActiveItems
    }

    func createItem(
        deck: String,
        rangeText: String,
        page: String?,
        profile: MemoryProfile,
        now: Date = Date()
    ) async throws {
        let trimmedDeck = deck.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRange = rangeText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPage = page?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedDeck.isEmpty else { throw Error.deckRequired }
        guard !trimmedRange.isEmpty else { throw Error.rangeRequired }

        let currentItems = try await itemRepository.fetchAllItems(includeArchived: false)
        guard currentItems.count < maxActiveItems else { throw Error.limitReached }

        let settings = try await settingsStore.loadSettings()
        let schedule = schedulingService.computeSchedule(
            request: SchedulingRequest(
                createdAt: now,
                currentIndex: 0,
                profile: profile,
                userSettings: settings
            )
        )

        let item = StudyItem(
            deck: trimmedDeck,
            rangeText: trimmedRange,
            page: trimmedPage?.isEmpty == true ? nil : trimmedPage,
            profile: profile,
            createdAt: now,
            nextDueAt: schedule.nextDueAt,
            intervalIndex: 0,
            history: []
        )

        try await itemRepository.save(item)
        try await regenerateNotifications(now)
    }
}

