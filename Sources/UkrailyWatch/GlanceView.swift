import SwiftUI

struct GlanceView: View {

    let journey: TrackedJourneySnapshot

    private var statusColor: Color {
        switch journey.statusColor {
        case "red":    return .red
        case "orange": return .orange
        default:       return .green
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            countdownRing
            routeLabel
            metaRow
        }
        .padding()
    }

    // MARK: - Sub-views

    private var countdownRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 6)
                .frame(width: 72, height: 72)

            // Progress arc — fills as departure approaches (within 60 min window)
            let progress = min(1.0, max(0.0, 1.0 - Double(journey.minutesToDeparture) / 60.0))
            Circle()
                .trim(from: 0, to: progress)
                .stroke(statusColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)

            VStack(spacing: 0) {
                Text("\(journey.minutesToDeparture)")
                    .font(.system(size: 24, weight: .bold, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText(countsDown: true))
                Text("min")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var routeLabel: some View {
        VStack(spacing: 1) {
            Text(journey.scheduledDeparture, format: .dateTime.hour().minute())
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(.secondary)
            Text(shortRoute)
                .font(.footnote.bold())
                .lineLimit(1)
                .multilineTextAlignment(.center)
        }
    }

    private var metaRow: some View {
        HStack(spacing: 10) {
            if let platform = journey.platform {
                Label("Plt \(platform)", systemImage: "tram")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if journey.delayMinutes > 0 {
                Text("+\(journey.delayMinutes) min")
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
            }
            if journey.isCancelled {
                Text("CANCELLED")
                    .font(.caption2.bold())
                    .foregroundStyle(.red)
            }
        }
    }

    private var shortRoute: String {
        let o = journey.originName.components(separatedBy: " ").prefix(2).joined(separator: " ")
        let d = journey.destinationName.components(separatedBy: " ").prefix(2).joined(separator: " ")
        return "\(o) → \(d)"
    }
}

#Preview {
    GlanceView(journey: TrackedJourneySnapshot(
        serviceID: "MOCK",
        originName: "London Paddington",
        destinationName: "Bristol Temple Meads",
        scheduledDeparture: Date.now.addingTimeInterval(12 * 60),
        platform: "3",
        delayMinutes: 0
    ))
}
