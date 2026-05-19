import SwiftUI
import UkrailyCore

struct CallingPointRow: View {

    let callingPoint: CallingPoint
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isFirst ? Color.clear : Color.white.opacity(0.2))
                    .frame(width: 2)
                Circle()
                    .fill(circleColor)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1))
                Rectangle()
                    .fill(isLast ? Color.clear : Color.white.opacity(0.2))
                    .frame(width: 2)
            }
            .frame(width: 10)

            // Station name + times
            HStack {
                Text(callingPoint.station.name)
                    .font(.subheadline)
                    .foregroundStyle(callingPoint.isCancelled ? .secondary : .white)
                    .strikethrough(callingPoint.isCancelled)
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(callingPoint.scheduledTime, format: .dateTime.hour().minute())
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.white)
                    if let est = callingPoint.estimatedTime, est != callingPoint.scheduledTime {
                        Text(est, format: .dateTime.hour().minute())
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var circleColor: Color {
        if callingPoint.isCancelled { return .red }
        if callingPoint.actualTime != nil { return .green }
        return .white.opacity(0.6)
    }
}

#Preview {
    let points = MockData.onTimeService.callingPoints
    return VStack(spacing: 0) {
        ForEach(Array(points.enumerated()), id: \.element.id) { index, cp in
            CallingPointRow(callingPoint: cp, isFirst: index == 0, isLast: index == points.count - 1)
                .padding(.horizontal)
        }
    }
    .background(Color.ukrailyCard)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .padding()
    .background(Color.ukrailyBackground)
}
