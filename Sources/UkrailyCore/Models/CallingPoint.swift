import Foundation

public struct CallingPoint: Identifiable, Sendable {
    public let id: UUID
    public let station: Station
    public let scheduledTime: Date
    public let estimatedTime: Date?
    public let actualTime: Date?
    public let platform: String?
    public let isCancelled: Bool

    public init(
        id: UUID = UUID(),
        station: Station,
        scheduledTime: Date,
        estimatedTime: Date? = nil,
        actualTime: Date? = nil,
        platform: String? = nil,
        isCancelled: Bool = false
    ) {
        self.id = id
        self.station = station
        self.scheduledTime = scheduledTime
        self.estimatedTime = estimatedTime
        self.actualTime = actualTime
        self.platform = platform
        self.isCancelled = isCancelled
    }

    public var effectiveTime: Date {
        actualTime ?? estimatedTime ?? scheduledTime
    }

    public var delayMinutes: Int {
        let reference = actualTime ?? estimatedTime ?? scheduledTime
        return max(0, Int(reference.timeIntervalSince(scheduledTime) / 60))
    }
}
