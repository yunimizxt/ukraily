import Foundation

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
