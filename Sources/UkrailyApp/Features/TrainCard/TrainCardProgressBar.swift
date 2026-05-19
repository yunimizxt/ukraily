import SwiftUI

struct TrainCardProgressBar: View {

    let service: TrainService

    private var progress: Double {
        guard let arrival = service.scheduledArrival else { return 0 }
        let total = arrival.timeIntervalSince(service.scheduledDeparture)
        guard total > 0 else { return 0 }
        let elapsed = Date.now.timeIntervalSince(service.scheduledDeparture)
        return min(max(elapsed / total, 0), 1)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 60)) { _ in
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 4)

                    // Progress fill
                    Capsule()
                        .fill(Color.ukrailyAccent)
                        .frame(width: geo.size.width * progress, height: 4)
                        .animation(.linear(duration: 0.5), value: progress)

                    // Calling point dots
                    if let arrival = service.scheduledArrival {
                        let total = arrival.timeIntervalSince(service.scheduledDeparture)
                        ForEach(service.callingPoints) { cp in
                            let cpProgress = total > 0
                                ? min(max(cp.scheduledTime.timeIntervalSince(service.scheduledDeparture) / total, 0), 1)
                                : 0
                            Circle()
                                .fill(cp.actualTime != nil ? Color.green : Color.white.opacity(0.5))
                                .frame(width: 6, height: 6)
                                .offset(x: geo.size.width * cpProgress - 3)
                        }
                    }

                    // Train dot
                    Circle()
                        .fill(Color.white)
                        .frame(width: 10, height: 10)
                        .offset(x: geo.size.width * progress - 5)
                        .shadow(color: .ukrailyAccent, radius: 4)
                        .animation(.linear(duration: 0.5), value: progress)
                }
                .frame(height: 10)
            }
            .frame(height: 10)
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        TrainCardProgressBar(service: MockData.onTimeService)  // not yet departed
        TrainCardProgressBar(service: MockData.departedService) // in progress
    }
    .padding()
    .background(Color.ukrailyBackground)
}
