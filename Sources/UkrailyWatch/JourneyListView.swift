import SwiftUI
import UkrailyCore

struct JourneyListView: View {

    @EnvironmentObject private var dataManager: WatchDataManager

    var body: some View {
        NavigationStack {
            Group {
                if dataManager.journeys.isEmpty {
                    emptyState
                } else {
                    journeyList
                }
            }
            .navigationTitle("Ukraily")
            .navigationDestination(for: TrackedJourneySnapshot.self) { journey in
                JourneyDetailView(journey: journey)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dataManager.reload()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.footnote)
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tram")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No tracked trains")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let updated = dataManager.lastRefreshed {
                Text("Updated \(updated, style: .relative) ago")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var journeyList: some View {
        List(dataManager.journeys) { journey in
            NavigationLink(value: journey) {
                JourneyRowView(journey: journey)
            }
        }
        .listStyle(.carousel)
    }
}

struct JourneyRowView: View {
    let journey: TrackedJourneySnapshot

    private var statusColor: Color {
        switch journey.statusColor {
        case "red":    return .red
        case "orange": return .orange
        default:       return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                Text(journey.scheduledDeparture, format: .dateTime.hour().minute())
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(journey.minutesToDeparture) min")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(statusColor)
            }
            Text(shortRoute(journey))
                .font(.footnote.bold())
                .lineLimit(1)
            if let platform = journey.platform {
                Text("Platform \(platform)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func shortRoute(_ j: TrackedJourneySnapshot) -> String {
        let origin = j.originName.components(separatedBy: " ").prefix(2).joined(separator: " ")
        let dest   = j.destinationName.components(separatedBy: " ").prefix(2).joined(separator: " ")
        return "\(origin) → \(dest)"
    }
}
