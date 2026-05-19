import Foundation

public struct TrainService: Identifiable, Sendable {
    public let serviceID: String
    public let operatorName: String
    public let scheduledDeparture: Date
    public let estimatedDeparture: Date?
    public let platform: String?
    public let isCancelled: Bool
    public let origin: Station
    public let destination: Station
    public let callingPoints: [CallingPoint]

    public var id: String { serviceID }

    public init(
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

    public var status: TrainStatus {
        if isCancelled { return .cancelled }
        guard let estimated = estimatedDeparture else { return .unknown }
        let delaySeconds = estimated.timeIntervalSince(scheduledDeparture)
        let delayMinutes = Int(delaySeconds / 60)
        return delayMinutes > 0 ? .delayed(minutes: delayMinutes) : .onTime
    }

    public var delayInfo: DelayInfo {
        DelayInfo(minutes: status.delayMinutes)
    }

    public var scheduledArrival: Date? {
        callingPoints.last(where: { $0.station.crsCode == destination.crsCode })?.scheduledTime
    }

    public var estimatedArrival: Date? {
        callingPoints.last(where: { $0.station.crsCode == destination.crsCode })?.estimatedTime
    }
}
