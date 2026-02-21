import Foundation

/// Abstraction over persistence for reading and mutating study items.
protocol ItemRepository {
    func fetchAllItems(includeArchived: Bool) async throws -> [StudyItem]
    func fetchDueItems(until: Date) async throws -> [StudyItem]
    func item(with id: UUID) async throws -> StudyItem?
    func save(_ item: StudyItem) async throws
    func delete(id: UUID) async throws
    func observeItems(includeArchived: Bool) -> AsyncStream<[StudyItem]>
}
