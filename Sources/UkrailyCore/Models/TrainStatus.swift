import Foundation

enum TrainStatus: Equatable, Sendable {
    case onTime
    case delayed(minutes: Int)
    case cancelled
    case unknown

    var isDisrupted: Bool {
        switch self {
        case .onTime, .unknown: return false
        case .delayed, .cancelled: return true
        }
    }

    var delayMinutes: Int {
        if case .delayed(let minutes) = self { return minutes }
        return 0
    }
}
