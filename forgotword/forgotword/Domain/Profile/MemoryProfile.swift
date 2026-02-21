import Foundation

/// Represents the five forgetting curve profiles with their corresponding multipliers.
enum MemoryProfile: Int, CaseIterable, Identifiable, Codable {
    case ultraForgetful = 0
    case forgetful = 1
    case standard = 2
    case smart = 3
    case ultraSmart = 4

    var id: Int { rawValue }

    /// Multiplier applied to the base interval sequence.
    var multiplier: Double {
        switch self {
        case .ultraForgetful: return 0.5
        case .forgetful: return 0.75
        case .standard: return 1.0
        case .smart: return 1.5
        case .ultraSmart: return 2.0
        }
    }

    /// Localized title for display.
    var title: String {
        switch self {
        case .ultraForgetful: return "超忘れっぽい"
        case .forgetful: return "忘れっぽい"
        case .standard: return "普通"
        case .smart: return "頭いい"
        case .ultraSmart: return "超頭いい"
        }
    }

    /// Suggested interval sequence in days after rounding.
    var suggestedDays: [Int] {
        switch self {
        case .ultraForgetful:
            return [0, 0, 1, 2, 4, 8, 16]
        case .forgetful:
            return [0, 1, 2, 4, 9, 18, 40]
        case .standard:
            return [0, 1, 3, 7, 16, 35, 90]
        case .smart:
            return [0, 2, 5, 11, 24, 53, 135]
        case .ultraSmart:
            return [0, 2, 6, 14, 32, 70, 180]
        }
    }
}
