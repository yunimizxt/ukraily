import SwiftUI

struct JourneyDetailView: View {

    let journey: TrackedJourneySnapshot
    @EnvironmentObject private var dataManager: WatchDataManager

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                GlanceView(journey: journey)
                    .padding(.top, -8)

                Divider()
                    .background(Color.white.opacity(0.1))

                detailGrid
            }
        }
        .navigationTitle("Journey")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { dataManager.reload() }
    }

    private var detailGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            detailRow(
                icon: "clock",
                label: "Departs",
                value: journey.scheduledDeparture.formatted(date: .omitted, time: .shortened)
            )
            if let platform = journey.platform {
                detailRow(icon: "tram", label: "Platform", value: platform)
            }
            if journey.delayMinutes > 0 {
                detailRow(
                    icon: "exclamationmark.circle",
                    label: "Delay",
                    value: "+\(journey.delayMinutes) min",
                    valueColor: .orange
                )
            }
            if journey.isCancelled {
                detailRow(
                    icon: "xmark.circle",
                    label: "Status",
                    value: "Cancelled",
                    valueColor: .red
                )
            } else if journey.delayMinutes == 0 {
                detailRow(
                    icon: "checkmark.circle",
                    label: "Status",
                    value: "On time",
                    valueColor: .green
                )
            }
        }
        .padding(.horizontal, 4)
    }

    private func detailRow(
        icon: String,
        label: String,
        value: String,
        valueColor: Color = .white
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 14)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption2.bold())
                .foregroundStyle(valueColor)
        }
    }
}
