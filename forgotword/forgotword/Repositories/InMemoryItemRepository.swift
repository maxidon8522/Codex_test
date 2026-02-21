import Foundation

actor InMemoryItemRepository: ItemRepository {
    private struct StreamEntry {
        let token: UUID
        let includeArchived: Bool
        let continuation: AsyncStream<[StudyItem]>.Continuation
    }

    private var items: [UUID: StudyItem] = [:]
    private var streams: [UUID: StreamEntry] = [:]

    func fetchAllItems(includeArchived: Bool) async throws -> [StudyItem] {
        currentItems(includeArchived: includeArchived)
    }

    func fetchDueItems(until: Date) async throws -> [StudyItem] {
        items.values
            .filter { !$0.isArchived && $0.nextDueAt <= until }
            .sorted { lhs, rhs in lhs.nextDueAt < rhs.nextDueAt }
    }

    func item(with id: UUID) async throws -> StudyItem? {
        items[id]
    }

    func save(_ item: StudyItem) async throws {
        items[item.id] = item
        broadcast()
    }

    func delete(id: UUID) async throws {
        items.removeValue(forKey: id)
        broadcast()
    }

    nonisolated func observeItems(includeArchived: Bool) -> AsyncStream<[StudyItem]> {
        AsyncStream { continuation in
            Task { await self.registerObserver(includeArchived: includeArchived, continuation: continuation) }
        }
    }

    private func registerObserver(
        includeArchived: Bool,
        continuation: AsyncStream<[StudyItem]>.Continuation
    ) async {
        let token = UUID()
        let entry = StreamEntry(token: token, includeArchived: includeArchived, continuation: continuation)
        streams[token] = entry
        continuation.onTermination = { [weak self] _ in
            guard let self else { return }
            Task { await self.removeStream(token: token) }
        }
        continuation.yield(currentItems(includeArchived: includeArchived))
    }

    private func removeStream(token: UUID) async {
        streams.removeValue(forKey: token)
    }

    private func broadcast() {
        for entry in streams.values {
            entry.continuation.yield(currentItems(includeArchived: entry.includeArchived))
        }
    }

    private func currentItems(includeArchived: Bool) -> [StudyItem] {
        items.values
            .filter { includeArchived || !$0.isArchived }
            .sorted { lhs, rhs in lhs.nextDueAt < rhs.nextDueAt }
    }
}
