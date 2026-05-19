import Foundation

struct TrackedJourneySnapshot: Sendable, Identifiable, Codable, Hashable {
    let id: UUID
    let serviceID: String
    let originName: String
    let destinationName: String
    let scheduledDeparture: Date
    let platform: String?
    let delayMinutes: Int
    let isCancelled: Bool

    init(
        id: UUID = UUID(),
        serviceID: String,
        originName: String,
        destinationName: String,
        scheduledDeparture: Date,
        platform: String? = nil,
        delayMinutes: Int = 0,
        isCancelled: Bool = false
    ) {
        self.id = id
        self.serviceID = serviceID
        self.originName = originName
        self.destinationName = destinationName
        self.scheduledDeparture = scheduledDeparture
        self.platform = platform
        self.delayMinutes = delayMinutes
        self.isCancelled = isCancelled
    }

    var statusColor: String {
        if isCancelled { return "red" }
        if delayMinutes > 0 { return "orange" }
        return "green"
    }

    var minutesToDeparture: Int {
        max(0, Int(scheduledDeparture.timeIntervalSinceNow / 60))
    }
}

