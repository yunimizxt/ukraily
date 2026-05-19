import SwiftUI

struct JourneyListView: View {

    @EnvironmentObject private var bridge: WatchConnectivityBridge

    var body: some View {
        NavigationStack {
            Group {
                if bridge.receivedJourneys.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tram")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No tracked journeys")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    List(bridge.receivedJourneys) { journey in
                        NavigationLink(value: journey) {
                            JourneyRowView(journey: journey)
                        }
                    }
                    .listStyle(.carousel)
                }
            }
            .navigationTitle("Ukraily")
            .navigationDestination(for: TrackedJourneySnapshot.self) { journey in
                JourneyDetailView(journey: journey)
            }
        }
    }
}

extension TrackedJourneySnapshot: Hashable {
    public static func == (lhs: TrackedJourneySnapshot, rhs: TrackedJourneySnapshot) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct JourneyRowView: View {
    let journey: TrackedJourneySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(journey.scheduledDeparture, format: .dateTime.hour().minute())
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(.secondary)
            Text("\(journey.originName.components(separatedBy: " ").first ?? "") → \(journey.destinationName.components(separatedBy: " ").first ?? "")")
                .font(.footnote.bold())
                .lineLimit(1)
            if journey.delayMinutes > 0 {
                Text("+\(journey.delayMinutes) min")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
    }
}
