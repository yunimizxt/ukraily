import Foundation

struct TSMessage: Sendable {
    let rid: String             // RTTI service ID
    let uid: String             // UID
    let trainDate: String       // "YYYY-MM-DD"
    let locations: [TSLocation]

    struct TSLocation: Sendable {
        let tiploc: String
        let workingScheduledPassTime: String?
        let workingScheduledArrivalTime: String?
        let workingScheduledDepartureTime: String?
        let estimatedArrival: String?
        let estimatedDeparture: String?
        let actualArrival: String?
        let actualDeparture: String?
        let platform: String?
        let isCancelled: Bool

        var delayMinutes: Int? {
            guard let sched = workingScheduledDepartureTime ?? workingScheduledArrivalTime,
                  let est = estimatedDeparture ?? estimatedArrival else { return nil }
            return minutesDifference(from: sched, to: est)
        }

        private func minutesDifference(from: String, to: String) -> Int? {
            let fmt = DateFormatter()
            fmt.dateFormat = "HH:mm"
            guard let d1 = fmt.date(from: from), let d2 = fmt.date(from: to) else { return nil }
            return max(0, Int(d2.timeIntervalSince(d1) / 60))
        }
    }
}
