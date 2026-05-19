import Foundation

public enum TrainStatus: Equatable, Sendable {
    case onTime
    case delayed(minutes: Int)
    case cancelled
    case unknown

    public var isDisrupted: Bool {
        switch self {
        case .onTime, .unknown: return false
        case .delayed, .cancelled: return true
        }
    }

    public var delayMinutes: Int {
        if case .delayed(let minutes) = self { return minutes }
        return 0
    }
}
