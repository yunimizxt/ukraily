import Foundation

public enum DelayCategory: Int, Sendable {
    case onTime    // 0 min
    case minor     // 1–4 min
    case moderate  // 5–14 min
    case severe    // 15–29 min
    case critical  // 30+ min
    case cancelled

    public static func from(minutes: Int) -> DelayCategory {
        switch minutes {
        case 0:       return .onTime
        case 1...4:   return .minor
        case 5...14:  return .moderate
        case 15...29: return .severe
        default:      return .critical
        }
    }
}

public struct DelayInfo: Sendable {
    public let minutes: Int
    public let reason: String?
    public let category: DelayCategory

    public init(minutes: Int, reason: String? = nil) {
        self.minutes = minutes
        self.reason = reason
        self.category = DelayCategory.from(minutes: minutes)
    }

    public static let none = DelayInfo(minutes: 0)
}
