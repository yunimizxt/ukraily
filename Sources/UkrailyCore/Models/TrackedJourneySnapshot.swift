import Foundation

public struct TrackedJourneySnapshot: Sendable, Identifiable, Codable, Hashable {
    public let id: UUID
    public let serviceID: String
    public let originName: String
    public let destinationName: String
    public let scheduledDeparture: Date
    public let platform: String?
    public let delayMinutes: Int
    public let isCancelled: Bool

    public init(
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

    public var statusColor: String {
        if isCancelled { return "red" }
        if delayMinutes > 0 { return "orange" }
        return "green"
    }

    public var minutesToDeparture: Int {
        max(0, Int(scheduledDeparture.timeIntervalSinceNow / 60))
    }
}

extension TrackedJourneySnapshot {
    public static func from(_ journey: TrackedJourney) -> TrackedJourneySnapshot {
        TrackedJourneySnapshot(
            id: journey.id,
            serviceID: journey.serviceID,
            originName: journey.originName,
            destinationName: journey.destinationName,
            scheduledDeparture: journey.scheduledDeparture,
            platform: journey.lastKnownPlatform,
            delayMinutes: journey.lastKnownDelayMinutes,
            isCancelled: journey.lastStatusRaw == 2
        )
    }
}
