import Foundation
import Combine

final class LiveTrainRepository {

    static let shared = LiveTrainRepository()

    private let rtt: RTTAPIClient
    private let pushPort: PushPortWebSocketClient
    private let stationLookup: CRSCodeLookup

    private var cancellables = Set<AnyCancellable>()
    private var serviceCache: [String: TrainService] = [:]

    var liveUpdates: AnyPublisher<TrainStatusUpdate, Never> {
        pushPort.updates
    }

    init(
        rtt: RTTAPIClient = .shared,
        pushPort: PushPortWebSocketClient = .shared,
        stationLookup: CRSCodeLookup = .shared
    ) {
        self.rtt = rtt
        self.pushPort = pushPort
        self.stationLookup = stationLookup
    }

    // MARK: - Public API

    func fetchDepartureBoard(crs: String, count: Int = 10) async throws -> [TrainService] {
        let response = try await rtt.fetchDepartures(crs: crs)
        let boardStation = stationLookup.station(forCRS: crs)
            ?? Station(crsCode: crs, name: response.location.name)
        return (response.services ?? [])
            .filter { $0.isPassenger == true }
            .prefix(count)
            .compactMap { mapService($0, boardStation: boardStation) }
    }

    func fetchServiceDetails(serviceID: String, boardStation: Station) async throws -> TrainService {
        // serviceID is "uid/runDate" e.g. "W12345/2024-01-15"
        let parts = serviceID.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { throw RTTError.invalidResponse(-1) }
        let response = try await rtt.fetchServiceDetails(serviceUid: parts[0], runDate: parts[1])
        let service = mapServiceDetails(response, serviceID: serviceID, boardStation: boardStation)
        serviceCache[serviceID] = service
        return service
    }

    func cachedService(id: String) -> TrainService? {
        serviceCache[id]
    }

    // MARK: - Mapping

    private func mapService(_ s: RTTService, boardStation: Station) -> TrainService? {
        let detail = s.locationDetail
        guard let scheduledStr = detail.gbttBookedDeparture,
              let scheduled = parseTime(scheduledStr, on: s.runDate) else { return nil }

        let estimated = parseTime(detail.realtimeDeparture, on: s.runDate)
        let isCancelled = detail.displayAs == "CANCELLED_CALL"
        let dest = s.destination?.first
        let destStation = stationLookup.station(forCRS: dest?.tiploc ?? "")
            ?? Station(crsCode: "", name: dest?.description ?? "Unknown")

        return TrainService(
            serviceID: "\(s.serviceUid)/\(s.runDate)",
            operatorName: s.atocName ?? s.atocCode ?? "",
            scheduledDeparture: scheduled,
            estimatedDeparture: isCancelled ? nil : estimated,
            platform: detail.platform,
            isCancelled: isCancelled,
            origin: boardStation,
            destination: destStation
        )
    }

    private func mapServiceDetails(
        _ r: RTTServiceResponse,
        serviceID: String,
        boardStation: Station
    ) -> TrainService {
        let callingPoints: [CallingPoint] = (r.locations ?? [])
            .filter { $0.isPublicCall == true || $0.isCall == true }
            .compactMap { loc in
                guard let name = loc.description else { return nil }
                let station = stationLookup.station(forCRS: loc.crs ?? "")
                    ?? Station(crsCode: loc.crs ?? "", name: name)
                guard let schTime = parseTime(loc.gbttBookedDeparture ?? loc.gbttBookedArrival, on: r.runDate)
                else { return nil }
                let estTime = parseTime(loc.realtimeDeparture ?? loc.realtimeArrival, on: r.runDate)
                let isCancelled = loc.cancelReasonCode != nil
                return CallingPoint(
                    station: station,
                    scheduledTime: schTime,
                    estimatedTime: estTime,
                    actualTime: loc.realtimeDepartureActual == true ? estTime : nil,
                    platform: loc.platform,
                    isCancelled: isCancelled
                )
            }

        let origin = callingPoints.first?.station ?? boardStation
        let destination = callingPoints.last?.station ?? boardStation
        let firstLoc = r.locations?.first(where: { $0.isPublicCall == true || $0.isCall == true })
        let isCancelled = r.locations?.allSatisfy { $0.cancelReasonCode != nil } ?? false

        return TrainService(
            serviceID: serviceID,
            operatorName: r.atocName ?? r.atocCode ?? "",
            scheduledDeparture: callingPoints.first?.scheduledTime ?? .now,
            estimatedDeparture: callingPoints.first?.estimatedTime,
            platform: firstLoc?.platform,
            isCancelled: isCancelled,
            origin: origin,
            destination: destination,
            callingPoints: callingPoints
        )
    }

    // MARK: - Time parsing

    private func parseTime(_ hhmm: String?, on dateStr: String) -> Date? {
        guard let hhmm = hhmm, hhmm.count >= 4 else { return nil }
        let h = hhmm.prefix(2)
        let m = hhmm.dropFirst(2).prefix(2)
        guard let hour = Int(h), let minute = Int(m) else { return nil }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "Europe/London")
        guard let base = fmt.date(from: dateStr) else { return nil }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/London")!
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: base)
    }
}
