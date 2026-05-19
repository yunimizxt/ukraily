import SwiftUI

struct JourneyDetailView: View {

    let journey: TrackedJourneySnapshot

    private var minutesToDeparture: Int {
        max(0, Int(journey.scheduledDeparture.timeIntervalSinceNow / 60))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                GlanceView(journey: journey)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    detailRow(label: "Operator", value: "GWR")
                    detailRow(
                        label: "Departs",
                        value: journey.scheduledDeparture.formatted(date: .omitted, time: .shortened)
                    )
                    if let platform = journey.platform {
                        detailRow(label: "Platform", value: platform)
                    }
                    if journey.delayMinutes > 0 {
                        detailRow(label: "Delay", value: "+\(journey.delayMinutes) min")
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Journey")
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
    }
}
