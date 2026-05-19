import WidgetKit
import SwiftUI
import UkrailyCore

// MARK: - Timeline provider

struct WatchComplicationProvider: TimelineProvider {

    typealias Entry = WatchComplicationEntry

    func placeholder(in context: Context) -> WatchComplicationEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchComplicationEntry) -> Void) {
        completion(buildEntry(from: SharedDataStore.nextJourney()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchComplicationEntry>) -> Void) {
        let journey = SharedDataStore.nextJourney()
        var entries: [WatchComplicationEntry] = []
        let now = Date.now
        entries.append(buildEntry(from: journey, at: now))

        if let j = journey {
            // Complication entries at T-10 and departure
            for offset in [-10 * 60.0, 0.0] {
                let date = j.scheduledDeparture.addingTimeInterval(offset)
                if date > now { entries.append(buildEntry(from: journey, at: date)) }
            }
            let expiry = j.scheduledDeparture.addingTimeInterval(90 * 60)
            completion(Timeline(entries: entries, policy: .after(expiry)))
        } else {
            completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(15 * 60))))
        }
    }

    private func buildEntry(from journey: TrackedJourneySnapshot?, at date: Date = .now) -> WatchComplicationEntry {
        guard let j = journey else { return .empty }
        return WatchComplicationEntry(date: date, journey: j)
    }
}

// MARK: - Entry

struct WatchComplicationEntry: TimelineEntry {
    let date: Date
    let journey: TrackedJourneySnapshot?

    static var placeholder: WatchComplicationEntry {
        WatchComplicationEntry(
            date: .now,
            journey: TrackedJourneySnapshot(
                serviceID: "PLACEHOLDER",
                originName: "London Paddington",
                destinationName: "Bristol Temple Meads",
                scheduledDeparture: Date.now.addingTimeInterval(14 * 60),
                platform: "3"
            )
        )
    }

    static var empty: WatchComplicationEntry {
        WatchComplicationEntry(date: .now, journey: nil)
    }
}

// MARK: - Views

struct WatchComplicationView: View {

    @Environment(\.widgetFamily) private var family
    let entry: WatchComplicationEntry

    var body: some View {
        if let journey = entry.journey {
            switch family {
            case .accessoryCircular:   circularView(journey)
            case .accessoryCorner:     cornerView(journey)
            case .accessoryRectangular: rectangularView(journey)
            case .accessoryInline:     inlineView(journey)
            default:                   circularView(journey)
            }
        } else {
            Image(systemName: "tram")
                .font(.title3)
                .containerBackground(.clear, for: .widget)
        }
    }

    // ○ Circular — dominant countdown number
    private func circularView(_ j: TrackedJourneySnapshot) -> some View {
        ZStack {
            let progress = min(1.0, max(0.0, 1.0 - Double(j.minutesToDeparture) / 60.0))
            AccessoryCircularProgressView(progress: progress)
                .tint(tint(j))
            VStack(spacing: 0) {
                Text("\(j.minutesToDeparture)")
                    .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                Text("m")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.clear, for: .widget)
    }

    // ◻ Rectangular — two lines of text
    private func rectangularView(_ j: TrackedJourneySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(j.scheduledDeparture, format: .dateTime.hour().minute())
                    .font(.caption.monospacedDigit().bold())
                if let platform = j.platform {
                    Text("· Plt \(platform)")
                        .font(.caption)
                }
                Spacer()
                Text("\(j.minutesToDeparture) min")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(tint(j))
            }
            Text(shortRoute(j))
                .font(.caption2)
                .lineLimit(1)
            statusLine(j)
        }
        .containerBackground(.clear, for: .widget)
    }

    // ⬡ Corner — icon + gauge value
    private func cornerView(_ j: TrackedJourneySnapshot) -> some View {
        ZStack {
            Image(systemName: "tram")
                .font(.body)
        }
        .widgetLabel {
            Text("\(j.minutesToDeparture) min")
                .foregroundStyle(tint(j))
        }
        .containerBackground(.clear, for: .widget)
    }

    // — Inline — single line
    private func inlineView(_ j: TrackedJourneySnapshot) -> some View {
        Text("\(j.minutesToDeparture)min · \(shortRoute(j))")
            .containerBackground(.clear, for: .widget)
    }

    // MARK: - Helpers

    private func statusLine(_ j: TrackedJourneySnapshot) -> some View {
        Group {
            if j.isCancelled {
                Text("Cancelled").foregroundStyle(.red)
            } else if j.delayMinutes > 0 {
                Text("+\(j.delayMinutes) min").foregroundStyle(.orange)
            } else {
                Text("On time").foregroundStyle(.green)
            }
        }
        .font(.caption2.bold())
    }

    private func shortRoute(_ j: TrackedJourneySnapshot) -> String {
        let o = j.originName.components(separatedBy: " ").first ?? j.originName
        let d = j.destinationName.components(separatedBy: " ").first ?? j.destinationName
        return "\(o)→\(d)"
    }

    private func tint(_ j: TrackedJourneySnapshot) -> Color {
        switch j.statusColor {
        case "red":    return .red
        case "orange": return .orange
        default:       return .green
        }
    }
}

// Circular progress view using ProgressView gauge style
private struct AccessoryCircularProgressView: View {
    let progress: Double
    var body: some View {
        ProgressView(value: progress)
            .progressViewStyle(.circular)
    }
}

// MARK: - Widget

struct NextTrainComplication: Widget {
    static let kind = "NextTrainComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: WatchComplicationProvider()) { entry in
            WatchComplicationView(entry: entry)
        }
        .configurationDisplayName("Next Train")
        .description("Shows your next tracked train on the watch face.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

// MARK: - Previews

#Preview("Circular", as: .accessoryCircular) {
    NextTrainComplication()
} timeline: {
    WatchComplicationEntry.placeholder
    WatchComplicationEntry.empty
}

#Preview("Rectangular", as: .accessoryRectangular) {
    NextTrainComplication()
} timeline: {
    WatchComplicationEntry.placeholder
}

#Preview("Corner", as: .accessoryCorner) {
    NextTrainComplication()
} timeline: {
    WatchComplicationEntry.placeholder
}

#Preview("Inline", as: .accessoryInline) {
    NextTrainComplication()
} timeline: {
    WatchComplicationEntry.placeholder
}
