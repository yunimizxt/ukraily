import SwiftUI
import UkrailyCore

struct DelayBadgeView: View {

    let status: TrainStatus

    private var delayMinutes: Int {
        status.delayMinutes
    }

    var body: some View {
        if case .delayed(let minutes) = status {
            HStack(spacing: 4) {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.caption)
                Text("+\(minutes) min")
                    .font(.caption.bold().monospacedDigit())
                    .contentTransition(.numericText(countsDown: false))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.orange.opacity(0.85))
            .clipShape(Capsule())
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        DelayBadgeView(status: .onTime)
        DelayBadgeView(status: .delayed(minutes: 5))
        DelayBadgeView(status: .delayed(minutes: 23))
        DelayBadgeView(status: .cancelled)
    }
    .padding()
    .background(Color.ukrailyBackground)
}
