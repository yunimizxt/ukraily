import WidgetKit
import SwiftUI

struct NextTrainTimelineProvider: TimelineProvider {

    typealias Entry = NextTrainEntry

    func placeholder(in context: Context) -> NextTrainEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (NextTrainEntry) -> Void) {
        completion(buildEntry(from: SharedDataStore.nextJourney()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextTrainEntry>) -> Void) {
        let journey = SharedDataStore.nextJourney()
        var entries: [NextTrainEntry] = []

        let now = Date.now
        entries.append(buildEntry(from: journey, at: now))

        if let j = journey {
            // Refresh at T-10 min, departure, and approx arrival
            let tMinus10 = j.scheduledDeparture.addingTimeInterval(-10 * 60)
            let departure = j.scheduledDeparture
            let arrival   = j.scheduledDeparture.addingTimeInterval(90 * 60)

            for date in [tMinus10, departure, arrival] where date > now {
                entries.append(buildEntry(from: journey, at: date))
            }

            completion(Timeline(entries: entries, policy: .after(arrival)))
        } else {
            completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(15 * 60))))
        }
    }

    // MARK: - Private

    private func buildEntry(from journey: TrackedJourneySnapshot?, at date: Date = .now) -> NextTrainEntry {
        guard let j = journey else { return .empty }
        let mins = max(0, Int(j.scheduledDeparture.timeIntervalSince(date) / 60))
        return NextTrainEntry(
            date: date,
            journey: j,
            minutesToDeparture: mins,
            platform: j.platform,
            delayMinutes: j.delayMinutes,
            isCancelled: j.isCancelled
        )
    }
}

struct NextTrainWidget: Widget {
    static let kind = "NextTrainWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: NextTrainTimelineProvider()) { entry in
            NextTrainWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Train")
        .description("Shows your next tracked train departure.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryCircular,
        ])
    }
}
