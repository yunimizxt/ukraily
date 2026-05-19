import SwiftUI
import SwiftData
import UkrailyCore

struct TrackedJourneysView: View {

    @Query(sort: \TrackedJourney.scheduledDeparture)
    private var journeys: [TrackedJourney]

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var coordinator: RootCoordinator

    var body: some View {
        ZStack {
            Color.ukrailyBackground.ignoresSafeArea()

            if journeys.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tram")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No tracked journeys")
                        .foregroundStyle(.secondary)
                    Text("Search for a train and tap Track to add it here.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(journeys) { journey in
                            TrackedJourneyRow(journey: journey) {
                                coordinator.push(.trainCard(serviceID: journey.serviceID))
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    context.delete(journey)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("My Trains")
    }
}

struct TrackedJourneyRow: View {
    let journey: TrackedJourney
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(journey.originName) → \(journey.destinationName)")
                        .font(.body.bold())
                        .foregroundStyle(.white)
                    Text(journey.scheduledDeparture, format: .dateTime.weekday().day().month().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if journey.lastKnownDelayMinutes > 0 {
                    Text("+\(journey.lastKnownDelayMinutes) min")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color.ukrailyCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
