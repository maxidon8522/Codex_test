import Foundation

/// Domain model representing a single study item (deck + range + page).
struct StudyItem: Identifiable, Equatable {
    struct ReviewHistoryEntry: Equatable, Identifiable, Codable {
        enum Result: String, Codable {
            case bad
            case good
            case great
        }

        let id: UUID
        var timestamp: Date
        var result: Result
    }

    let id: UUID
    var deck: String
    var rangeText: String
    var page: String?
    var profile: MemoryProfile
    var createdAt: Date
    var nextDueAt: Date
    var intervalIndex: Int
    var history: [ReviewHistoryEntry]
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        deck: String,
        rangeText: String,
        page: String? = nil,
        profile: MemoryProfile,
        createdAt: Date = Date(),
        nextDueAt: Date,
        intervalIndex: Int = 0,
        history: [ReviewHistoryEntry] = [],
        isArchived: Bool = false
    ) {
        self.id = id
        self.deck = deck
        self.rangeText = rangeText
        self.page = page
        self.profile = profile
        self.createdAt = createdAt
        self.nextDueAt = nextDueAt
        self.intervalIndex = intervalIndex
        self.history = history
        self.isArchived = isArchived
    }
}
