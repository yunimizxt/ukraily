import WidgetKit
import SwiftUI
import SwiftData
import UkrailyCore

struct NextTrainTimelineProvider: TimelineProvider {

    typealias Entry = NextTrainEntry

    func placeholder(in context: Context) -> NextTrainEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (NextTrainEntry) -> Void) {
        completion(buildEntry(from: nextTrackedJourney()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextTrainEntry>) -> Void) {
        let journey = nextTrackedJourney()
        var entries: [NextTrainEntry] = []

        let now = Date.now
        entries.append(buildEntry(from: journey, at: now))

        if let j = journey {
            // Refresh at T-10 min, departure, and arrival
            let tMinus10 = j.scheduledDeparture.addingTimeInterval(-10 * 60)
            let departure = j.scheduledDeparture
            let arrival   = j.scheduledDeparture.addingTimeInterval(90 * 60) // approx

            for date in [tMinus10, departure, arrival] where date > now {
                entries.append(buildEntry(from: journey, at: date))
            }

            let policy = TimelineReloadPolicy.after(arrival)
            completion(Timeline(entries: entries, policy: policy))
        } else {
            // No journey — reload in 15 min
            completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(15 * 60))))
        }
    }

    // MARK: - Private

    private func nextTrackedJourney() -> TrackedJourneySnapshot? {
        // Read from the shared App Group SwiftData store
        guard let container = try? ModelContainer(
            for: TrackedJourney.self,
            configurations: ModelConfiguration(
                url: FileManager.default
                    .containerURL(forSecurityApplicationGroupIdentifier: "group.com.ukraily")?
                    .appendingPathComponent("Ukraily.store") ?? URL.documentsDirectory
            )
        ) else { return nil }

        let context = ModelContext(container)
        let now = Date.now
        let descriptor = FetchDescriptor<TrackedJourney>(
            predicate: #Predicate { $0.isActive && $0.scheduledDeparture > now },
            sortBy: [SortDescriptor(\.scheduledDeparture)]
        )
        guard let journeys = try? context.fetch(descriptor),
              let next = journeys.first else { return nil }

        return TrackedJourneySnapshot(
            id: next.id,
            serviceID: next.serviceID,
            originName: next.originName,
            destinationName: next.destinationName,
            scheduledDeparture: next.scheduledDeparture,
            platform: next.lastKnownPlatform,
            delayMinutes: next.lastKnownDelayMinutes,
            isCancelled: next.lastStatusRaw == 2
        )
    }

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
