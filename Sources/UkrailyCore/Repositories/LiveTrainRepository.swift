import Foundation
import Combine

public final class LiveTrainRepository {

    public static let shared = LiveTrainRepository()

    private let soapClient: DarwinSOAPClient
    private let pushPort: PushPortWebSocketClient
    private let stationLookup: CRSCodeLookup

    private var cancellables = Set<AnyCancellable>()

    // In-memory cache keyed by serviceID
    private var serviceCache: [String: TrainService] = [:]

    public var liveUpdates: AnyPublisher<TrainStatusUpdate, Never> {
        pushPort.updates
    }

    public init(
        soapClient: DarwinSOAPClient = .shared,
        pushPort: PushPortWebSocketClient = .shared,
        stationLookup: CRSCodeLookup = .shared
    ) {
        self.soapClient = soapClient
        self.pushPort = pushPort
        self.stationLookup = stationLookup
    }

    // MARK: - Public API

    public func fetchDepartureBoard(crs: String, count: Int = 10) async throws -> [TrainService] {
        let response = try await soapClient.fetchDepartureBoard(crs: crs, count: count)
        let station = stationLookup.station(forCRS: crs) ?? Station(crsCode: crs, name: response.locationName)
        return response.services.compactMap { summary in
            mapToTrainService(summary: summary, boardStation: station)
        }
    }

    public func fetchServiceDetails(serviceID: String, boardStation: Station) async throws -> TrainService {
        let response = try await soapClient.fetchServiceDetails(serviceID: serviceID)
        let service = mapDetailsToTrainService(response: response, serviceID: serviceID, boardStation: boardStation)
        serviceCache[serviceID] = service
        return service
    }

    public func cachedService(id: String) -> TrainService? {
        serviceCache[id]
    }

    // MARK: - Mapping

    private func mapToTrainService(
        summary: GetDepartureBoardResponse.ServiceSummary,
        boardStation: Station
    ) -> TrainService? {
        let destination = stationLookup.station(forCRS: summary.destinationCRS ?? "") ??
            Station(crsCode: summary.destinationCRS ?? "???", name: summary.destinationName)

        let scheduledDep = UkrailyDateFormatter.parseTime(summary.scheduledDeparture) ?? .now
        let estimatedDep: Date?
        if let etStr = summary.estimatedDeparture, etStr != "On time", etStr != "Delayed", etStr != "Cancelled" {
            estimatedDep = UkrailyDateFormatter.parseTime(etStr)
        } else if summary.estimatedDeparture == "On time" {
            estimatedDep = scheduledDep
        } else {
            estimatedDep = nil
        }

        return TrainService(
            serviceID: summary.serviceID,
            operatorName: summary.operatorName,
            scheduledDeparture: scheduledDep,
            estimatedDeparture: estimatedDep,
            platform: summary.platform,
            isCancelled: summary.isCancelled,
            origin: boardStation,
            destination: destination
        )
    }

    private func mapDetailsToTrainService(
        response: GetServiceDetailsResponse,
        serviceID: String,
        boardStation: Station
    ) -> TrainService {
        let callingPoints = response.callingPoints.map { cp -> CallingPoint in
            let station = stationLookup.station(forCRS: cp.crs ?? "") ??
                Station(crsCode: cp.crs ?? "???", name: cp.stationName)
            return CallingPoint(
                station: station,
                scheduledTime: UkrailyDateFormatter.parseTime(cp.scheduledTime) ?? .now,
                estimatedTime: cp.estimatedTime.flatMap(UkrailyDateFormatter.parseTime),
                actualTime: cp.actualTime.flatMap(UkrailyDateFormatter.parseTime),
                platform: cp.platform,
                isCancelled: cp.isCancelled
            )
        }

        let origin = callingPoints.first?.station ?? boardStation
        let destination = callingPoints.last?.station ?? boardStation

        return TrainService(
            serviceID: serviceID,
            operatorName: response.operatorName,
            scheduledDeparture: callingPoints.first?.scheduledTime ?? .now,
            estimatedDeparture: callingPoints.first?.estimatedTime,
            platform: response.platform,
            isCancelled: response.isCancelled,
            origin: origin,
            destination: destination,
            callingPoints: callingPoints
        )
    }
}
