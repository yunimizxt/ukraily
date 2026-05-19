import Foundation

struct CallingPoint: Identifiable, Sendable {
    let id: UUID
    let station: Station
    let scheduledTime: Date
    let estimatedTime: Date?
    let actualTime: Date?
    let platform: String?
    let isCancelled: Bool

    init(
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

    var effectiveTime: Date {
        actualTime ?? estimatedTime ?? scheduledTime
    }

    var delayMinutes: Int {
        let reference = actualTime ?? estimatedTime ?? scheduledTime
        return max(0, Int(reference.timeIntervalSince(scheduledTime) / 60))
    }
}
