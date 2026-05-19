import SwiftUI

struct GlanceView: View {

    let journey: TrackedJourneySnapshot

    private var minutesToDeparture: Int {
        max(0, Int(journey.scheduledDeparture.timeIntervalSinceNow / 60))
    }

    private var statusColor: Color {
        if journey.isCancelled { return .red }
        if journey.delayMinutes > 0 { return .orange }
        return .green
    }

    var body: some View {
        VStack(spacing: 6) {
            // Countdown ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 70, height: 70)
                Circle()
                    .trim(from: 0, to: min(CGFloat(minutesToDeparture) / 60.0, 1.0))
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(minutesToDeparture)")
                        .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                    Text("min")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Text(journey.scheduledDeparture, format: .dateTime.hour().minute())
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Text("\(journey.originName) → \(journey.destinationName)")
                .font(.footnote.bold())
                .lineLimit(1)
                .multilineTextAlignment(.center)

            if let platform = journey.platform {
                Text("Plt \(platform)")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }

            if journey.delayMinutes > 0 {
                Text("+\(journey.delayMinutes) min late")
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
            }

            if journey.isCancelled {
                Text("CANCELLED")
                    .font(.caption2.bold())
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }
}

#Preview {
    GlanceView(journey: TrackedJourneySnapshot(
        serviceID: "MOCK001",
        originName: "London Paddington",
        destinationName: "Bristol Temple Meads",
        scheduledDeparture: Date.now.addingTimeInterval(12 * 60),
        platform: "3",
        delayMinutes: 0
    ))
}
