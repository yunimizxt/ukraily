import SwiftUI

struct CountdownLabel: View {

    let targetDate: Date

    @State private var minutesRemaining: Int = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(countdownText)
            .contentTransition(.numericText(countsDown: true))
            .onReceive(timer) { _ in
                updateCountdown()
            }
            .onAppear { updateCountdown() }
    }

    private var countdownText: String {
        if minutesRemaining <= 0 { return "Now" }
        if minutesRemaining < 60 { return "\(minutesRemaining) min" }
        let h = minutesRemaining / 60
        let m = minutesRemaining % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    private func updateCountdown() {
        minutesRemaining = max(0, Int(targetDate.timeIntervalSinceNow / 60))
    }
}
