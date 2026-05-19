import SwiftUI
import UkrailyCore

struct StatusBadge: View {

    let status: TrainStatus

    private var label: String {
        switch status {
        case .onTime:              return "On time"
        case .delayed(let m):      return "\(m) min late"
        case .cancelled:           return "Cancelled"
        case .unknown:             return "No info"
        }
    }

    private var color: Color {
        switch status {
        case .onTime:    return .green
        case .delayed:   return .orange
        case .cancelled: return .red
        case .unknown:   return .gray
        }
    }

    var body: some View {
        Text(label)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.85))
            .clipShape(Capsule())
    }
}
