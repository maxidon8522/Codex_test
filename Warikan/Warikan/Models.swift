//
//  Models.swift
//  Warikan
//
//  Created by AI Coding Assistant on 2025/12/15.
//

import Foundation

/// Party member who participates in a Warikan event.
struct Member: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var contactInfo: String?
    var note: String?
    /// Default weight used when splitting unevenly. Minimum is 1.
    var defaultShareWeight: Int
    var isArchived: Bool
    var colorHex: String

    init(
        id: UUID = UUID(),
        name: String,
        contactInfo: String? = nil,
        note: String? = nil,
        defaultShareWeight: Int = 1,
        isArchived: Bool = false,
        colorHex: String = Member.randomColorHex()
    ) {
        self.id = id
        self.name = name
        self.contactInfo = contactInfo
        self.note = note
        self.defaultShareWeight = max(defaultShareWeight, 1)
        self.isArchived = isArchived
        self.colorHex = colorHex
    }

    static let defaultColorPalette: [String] = [
        "#F94144", "#F3722C", "#F8961E", "#F9844A", "#F9C74F",
        "#90BE6D", "#43AA8B", "#577590", "#277DA1", "#9B5DE5"
    ]

    static func randomColorHex() -> String {
        defaultColorPalette.randomElement() ?? "#43AA8B"
    }
}

/// Expense item that belongs to an event.
struct Item: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    /// Monetary amount stored as Int to avoid precision loss.
    var amount: Int
    /// Total quantity multiplied by amount gives the total due.
    var quantity: Int
    var payerIDs: [Member.ID]
    /// Participants who share the item. Empty array means all members.
    var participantIDs: [Member.ID]
    /// Optional custom weights per participant. Absent values default to 1.
    var weightOverrides: [Member.ID: Int]
    var createdAt: Date
    var memo: String?

    init(
        id: UUID = UUID(),
        name: String,
        amount: Int,
        quantity: Int = 1,
        payerIDs: [Member.ID],
        participantIDs: [Member.ID] = [],
        weightOverrides: [Member.ID: Int] = [:],
        createdAt: Date = Date(),
        memo: String? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.quantity = max(quantity, 1)
        self.payerIDs = payerIDs
        self.participantIDs = participantIDs
        self.weightOverrides = weightOverrides
        self.createdAt = createdAt
        self.memo = memo
    }

    var totalCost: Int {
        amount * max(quantity, 1)
    }

    func resolvedPayers(fallbackID: Member.ID?) -> [Member.ID] {
        if payerIDs.isEmpty, let fallback = fallbackID {
            return [fallback]
        }
        return payerIDs.isEmpty ? [] : payerIDs
    }

    func resolvedParticipants(allMemberIDs: [Member.ID]) -> [Member.ID] {
        participantIDs.isEmpty ? allMemberIDs : participantIDs
    }

    func weight(for memberID: Member.ID, defaultWeight: Int) -> Int {
        max(weightOverrides[memberID] ?? defaultWeight, 1)
    }
}

/// Event that groups members, items, and charge settings.
struct Event: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var date: Date
    var members: [Member]
    var items: [Item]
    var currencyCode: String
    var charges: EventCharges
    var note: String?

    init(
        id: UUID = UUID(),
        title: String,
        date: Date = Date(),
        members: [Member],
        items: [Item] = [],
        currencyCode: String,
        charges: EventCharges = EventCharges(),
        note: String? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.members = members
        self.items = items
        self.currencyCode = currencyCode
        self.charges = charges
        self.note = note
    }

    var memberIDs: [Member.ID] {
        members.map(\.id)
    }

    var subtotal: Int {
        items.reduce(0) { $0 + $1.totalCost }
    }

    var totalAmount: Int {
        subtotal + charges.serviceFeeAmount(forSubtotal: subtotal) + charges.fixedSurcharge
    }

    func member(by id: Member.ID) -> Member? {
        members.first { $0.id == id }
    }
}

/// Additional adjustments applied when calculating settlements.
struct EventCharges: Codable, Hashable {
    /// Ratio (e.g. 0.1 = 10%) applied to the subtotal.
    var serviceFeeRate: Double
    /// Flat amount (positive surcharge or negative discount).
    var fixedSurcharge: Int
    var roundingRule: RoundingRule
    /// Future manual tweaks per member (UI only for now).
    var manualAdjustments: [Member.ID: Int] = [:]

    init(
        serviceFeeRate: Double = 0,
        fixedSurcharge: Int = 0,
        roundingRule: RoundingRule = .none,
        manualAdjustments: [Member.ID: Int] = [:]
    ) {
        self.serviceFeeRate = serviceFeeRate
        self.fixedSurcharge = fixedSurcharge
        self.roundingRule = roundingRule
        self.manualAdjustments = manualAdjustments
    }

    func serviceFeeAmount(forSubtotal subtotal: Int) -> Int {
        guard serviceFeeRate > 0, subtotal > 0 else { return 0 }
        return Int((Double(subtotal) * serviceFeeRate).rounded())
    }
}

/// Rule used to round member-level debts.
enum RoundingRule: Codable, Equatable {
    case none
    case up(step: Int)
    case down(step: Int)
    case nearest(step: Int)

    private enum CodingKeys: String, CodingKey {
        case type
        case step
    }

    private enum RuleType: String, Codable {
        case none
        case up
        case down
        case nearest
    }

    func apply(to amount: Int) -> Int {
        guard amount > 0 else { return amount }
        switch self {
        case .none:
            return amount
        case .up(let step):
            let normalized = max(step, 1)
            return ((amount + normalized - 1) / normalized) * normalized
        case .down(let step):
            let normalized = max(step, 1)
            return (amount / normalized) * normalized
        case .nearest(let step):
            let normalized = max(step, 1)
            let quotient = Double(amount) / Double(normalized)
            return Int((quotient.rounded()) * Double(normalized))
        }
    }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(RuleType.self, forKey: .type)
        switch type {
        case .none:
            self = .none
        case .up:
            self = .up(step: try container.decode(Int.self, forKey: .step))
        case .down:
            self = .down(step: try container.decode(Int.self, forKey: .step))
        case .nearest:
            self = .nearest(step: try container.decode(Int.self, forKey: .step))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encode(RuleType.none, forKey: .type)
        case .up(let step):
            try container.encode(RuleType.up, forKey: .type)
            try container.encode(step, forKey: .step)
        case .down(let step):
            try container.encode(RuleType.down, forKey: .type)
            try container.encode(step, forKey: .step)
        case .nearest(let step):
            try container.encode(RuleType.nearest, forKey: .type)
            try container.encode(step, forKey: .step)
        }
    }
}

/// Transfer instruction representing a payment from one member to another.
struct Transfer: Codable, Identifiable, Hashable {
    let id: UUID
    let fromMemberID: Member.ID
    let toMemberID: Member.ID
    let amount: Int

    init(id: UUID = UUID(), fromMemberID: Member.ID, toMemberID: Member.ID, amount: Int) {
        self.id = id
        self.fromMemberID = fromMemberID
        self.toMemberID = toMemberID
        self.amount = amount
    }
}

/// App-wide configuration persisted via UserDefaults.
struct UserSettings: Codable, Equatable {
    var defaultCurrencyCode: String
    var defaultServiceFeeRate: Double
    var defaultRoundingRule: RoundingRule
    /// Maximum number of history entries for the free plan.
    var freeHistoryLimit: Int
    var preferredLocaleIdentifier: String
    var lastOpenedEventID: Event.ID?

    init(
        defaultCurrencyCode: String = Locale.current.currency?.identifier ?? "JPY",
        defaultServiceFeeRate: Double = 0,
        defaultRoundingRule: RoundingRule = .none,
        freeHistoryLimit: Int = 3,
        preferredLocaleIdentifier: String = Locale.current.identifier,
        lastOpenedEventID: Event.ID? = nil
    ) {
        self.defaultCurrencyCode = defaultCurrencyCode
        self.defaultServiceFeeRate = defaultServiceFeeRate
        self.defaultRoundingRule = defaultRoundingRule
        self.freeHistoryLimit = max(freeHistoryLimit, 1)
        self.preferredLocaleIdentifier = preferredLocaleIdentifier
        self.lastOpenedEventID = lastOpenedEventID
    }

    static var `default`: UserSettings { UserSettings() }
}
