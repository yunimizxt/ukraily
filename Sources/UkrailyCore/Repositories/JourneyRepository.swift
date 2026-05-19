import Foundation
import SwiftData

public final class JourneyRepository {

    public static let shared = JourneyRepository()

    private let liveTrains: LiveTrainRepository
    private let stationLookup: CRSCodeLookup

    public init(
        liveTrains: LiveTrainRepository = .shared,
        stationLookup: CRSCodeLookup = .shared
    ) {
        self.liveTrains = liveTrains
        self.stationLookup = stationLookup
    }

    // MARK: - Journey search

    public func searchJourneys(from originCRS: String, to destinationCRS: String, on date: Date = .now) async throws -> [TrainService] {
        // Fetch board from origin, filter by destination
        let board = try await liveTrains.fetchDepartureBoard(crs: originCRS, count: 10)
        return board.filter { service in
            // Check if destination is in calling points or is the terminal destination
            service.destination.crsCode == destinationCRS ||
            service.callingPoints.contains(where: { $0.station.crsCode == destinationCRS })
        }
    }

    // MARK: - Tracked journeys

    public func track(service: TrainService, context: ModelContext) {
        let journey = TrackedJourney(
            serviceID: service.serviceID,
            originCRS: service.origin.crsCode,
            originName: service.origin.name,
            destinationCRS: service.destination.crsCode,
            destinationName: service.destination.name,
            scheduledDeparture: service.scheduledDeparture,
            lastKnownPlatform: service.platform,
            lastKnownDelayMinutes: service.status.delayMinutes
        )
        context.insert(journey)
    }

    public func untrack(journey: TrackedJourney, context: ModelContext) {
        context.delete(journey)
    }

    public func refresh(journey: TrackedJourney, context: ModelContext) async throws -> TrainService {
        let station = stationLookup.station(forCRS: journey.originCRS) ?? journey.origin
        let service = try await liveTrains.fetchServiceDetails(serviceID: journey.serviceID, boardStation: station)

        journey.lastKnownDelayMinutes = service.status.delayMinutes
        journey.lastKnownPlatform = service.platform
        journey.lastStatusRaw = service.isCancelled ? 2 : (service.status.delayMinutes > 0 ? 1 : 0)
        return service
    }
}
