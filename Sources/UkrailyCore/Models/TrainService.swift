import Foundation

struct TrainService: Identifiable, Sendable {
    let serviceID: String
    let operatorName: String
    let scheduledDeparture: Date
    let estimatedDeparture: Date?
    let platform: String?
    let isCancelled: Bool
    let origin: Station
    let destination: Station
    let callingPoints: [CallingPoint]

    var id: String { serviceID }

    init(
        serviceID: String,
        operatorName: String,
        scheduledDeparture: Date,
        estimatedDeparture: Date? = nil,
        platform: String? = nil,
        isCancelled: Bool = false,
        origin: Station,
        destination: Station,
        callingPoints: [CallingPoint] = []
    ) {
        self.serviceID = serviceID
        self.operatorName = operatorName
        self.scheduledDeparture = scheduledDeparture
        self.estimatedDeparture = estimatedDeparture
        self.platform = platform
        self.isCancelled = isCancelled
        self.origin = origin
        self.destination = destination
        self.callingPoints = callingPoints
    }

    var status: TrainStatus {
        if isCancelled { return .cancelled }
        guard let estimated = estimatedDeparture else { return .unknown }
        let delaySeconds = estimated.timeIntervalSince(scheduledDeparture)
        let delayMinutes = Int(delaySeconds / 60)
        return delayMinutes > 0 ? .delayed(minutes: delayMinutes) : .onTime
    }

    var delayInfo: DelayInfo {
        DelayInfo(minutes: status.delayMinutes)
    }

    var scheduledArrival: Date? {
        callingPoints.last(where: { $0.station.crsCode == destination.crsCode })?.scheduledTime
    }

    var estimatedArrival: Date? {
        callingPoints.last(where: { $0.station.crsCode == destination.crsCode })?.estimatedTime
    }
}
