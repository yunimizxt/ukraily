import WidgetKit
import UkrailyCore

struct NextTrainEntry: TimelineEntry {
    let date: Date
    let journey: TrackedJourneySnapshot?
    let minutesToDeparture: Int
    let platform: String?
    let delayMinutes: Int
    let isCancelled: Bool

    static var placeholder: NextTrainEntry {
        NextTrainEntry(
            date: .now,
            journey: TrackedJourneySnapshot(
                serviceID: "PLACEHOLDER",
                originName: "London Paddington",
                destinationName: "Bristol Temple Meads",
                scheduledDeparture: Date.now.addingTimeInterval(14 * 60),
                platform: "3",
                delayMinutes: 0
            ),
            minutesToDeparture: 14,
            platform: "3",
            delayMinutes: 0,
            isCancelled: false
        )
    }

    static var empty: NextTrainEntry {
        NextTrainEntry(date: .now, journey: nil, minutesToDeparture: 0, platform: nil, delayMinutes: 0, isCancelled: false)
    }
}
