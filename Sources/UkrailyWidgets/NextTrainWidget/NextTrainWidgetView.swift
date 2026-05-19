import SwiftUI
import WidgetKit
import UkrailyCore

struct NextTrainWidgetView: View {

    @Environment(\.widgetFamily) private var family
    let entry: NextTrainEntry

    var body: some View {
        if let journey = entry.journey {
            switch family {
            case .systemSmall:   smallView(journey: journey)
            case .systemMedium:  mediumView(journey: journey)
            case .accessoryRectangular: accessoryRectangular(journey: journey)
            case .accessoryCircular:    accessoryCircular
            default:             smallView(journey: journey)
            }
        } else {
            emptyView
        }
    }

    // MARK: - Sizes

    private func smallView(journey: TrackedJourneySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Spacer()
                Text(journey.scheduledDeparture, format: .dateTime.hour().minute())
                    .font(.caption2.bold().monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text("\(entry.minutesToDeparture) min")
                .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)

            Spacer()

            Text(routeText(journey))
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .lineLimit(2)

            if let platform = entry.platform {
                Text("Plt \(platform)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .containerBackground(Color(red: 0.07, green: 0.07, blue: 0.10), for: .widget)
        .widgetURL(journeyURL(journey))
    }

    private func mediumView(journey: TrackedJourneySnapshot) -> some View {
        HStack(spacing: 16) {
            // Left: countdown
            VStack(alignment: .leading, spacing: 4) {
                Text(journey.scheduledDeparture, format: .dateTime.hour().minute())
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.secondary)
                Text("\(entry.minutesToDeparture)")
                    .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                Text("min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80)

            Divider().background(Color.white.opacity(0.1))

            // Right: details
            VStack(alignment: .leading, spacing: 6) {
                Text(routeText(journey))
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if let platform = entry.platform {
                    Label("Platform \(platform)", systemImage: "tram")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if entry.delayMinutes > 0 {
                    Label("+\(entry.delayMinutes) min delay", systemImage: "clock.badge.exclamationmark")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if entry.isCancelled {
                    Label("Cancelled", systemImage: "xmark.circle")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                }
            }
            Spacer()
        }
        .padding()
        .containerBackground(Color(red: 0.07, green: 0.07, blue: 0.10), for: .widget)
        .widgetURL(journeyURL(journey))
    }

    private func accessoryRectangular(journey: TrackedJourneySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(journey.scheduledDeparture, format: .dateTime.hour().minute())
                    .font(.caption.monospacedDigit())
                if let platform = entry.platform {
                    Text("· Plt \(platform)")
                        .font(.caption)
                }
                Spacer()
            }
            Text(routeText(journey))
                .font(.caption.bold())
                .lineLimit(1)
            Text(statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.clear, for: .widget)
        .widgetURL(journeyURL(journey))
    }

    private var accessoryCircular: some View {
        ZStack {
            Circle().strokeBorder(.white.opacity(0.2), lineWidth: 2)
            VStack(spacing: 0) {
                Text("\(entry.minutesToDeparture)")
                    .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                Text("min")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.clear, for: .widget)
    }

    private var emptyView: some View {
        VStack(spacing: 4) {
            Image(systemName: "tram")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("No trains")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(Color(red: 0.07, green: 0.07, blue: 0.10), for: .widget)
    }

    // MARK: - Helpers

    private var statusColor: Color {
        if entry.isCancelled { return .red }
        if entry.delayMinutes > 0 { return .orange }
        return .green
    }

    private var statusText: String {
        if entry.isCancelled { return "Cancelled" }
        if entry.delayMinutes > 0 { return "+\(entry.delayMinutes) min" }
        return "On time"
    }

    private func routeText(_ j: TrackedJourneySnapshot) -> String {
        "\(j.originName.components(separatedBy: " ").prefix(2).joined(separator: " ")) → \(j.destinationName.components(separatedBy: " ").prefix(2).joined(separator: " "))"
    }

    private func journeyURL(_ j: TrackedJourneySnapshot) -> URL {
        URL(string: "ukraily://journey/\(j.id.uuidString)") ?? URL(string: "ukraily://")!
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    NextTrainWidget()
} timeline: {
    NextTrainEntry.placeholder
    NextTrainEntry.empty
}

#Preview("Medium", as: .systemMedium) {
    NextTrainWidget()
} timeline: {
    NextTrainEntry.placeholder
}

#Preview("Lock screen rectangular", as: .accessoryRectangular) {
    NextTrainWidget()
} timeline: {
    NextTrainEntry.placeholder
}

#Preview("Lock screen circular", as: .accessoryCircular) {
    NextTrainWidget()
} timeline: {
    NextTrainEntry.placeholder
}
