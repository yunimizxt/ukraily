import Foundation
import SwiftData

public final class JourneyRepository {

    public static let shared = JourneyRepository()

    private let liveTrains: LiveTrainRepository
    private let stationLookup: CRSCodeLookup
    private let notificationScheduler: NotificationScheduler

    public init(
        liveTrains: LiveTrainRepository = .shared,
        stationLookup: CRSCodeLookup = .shared,
        notificationScheduler: NotificationScheduler = .shared
    ) {
        self.liveTrains = liveTrains
        self.stationLookup = stationLookup
        self.notificationScheduler = notificationScheduler
    }

    // MARK: - Journey search

    public func searchJourneys(
        from originCRS: String,
        to destinationCRS: String,
        on date: Date = .now
    ) async throws -> [TrainService] {
        let board = try await liveTrains.fetchDepartureBoard(crs: originCRS, count: 10)
        return board.filter { service in
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
        Task {
            await notificationScheduler.schedulePreDepartureReminders(for: journey)
        }
    }

    public func untrack(journey: TrackedJourney, context: ModelContext) {
        notificationScheduler.cancelAllNotifications(for: journey.id)
        context.delete(journey)
    }

    public func refresh(journey: TrackedJourney, context: ModelContext) async throws -> TrainService {
        let station = stationLookup.station(forCRS: journey.originCRS) ?? journey.origin
        let service = try await liveTrains.fetchServiceDetails(serviceID: journey.serviceID, boardStation: station)

        let newDelay = service.status.delayMinutes
        let newPlatform = service.platform
        let isCancelled = service.isCancelled

        // Cancellation
        if isCancelled && journey.lastStatusRaw != 2 {
            await notificationScheduler.scheduleCancellation(journey: journey)
            journey.lastStatusRaw = 2
        }

        // Delay threshold
        if !isCancelled && newDelay != journey.lastKnownDelayMinutes {
            await notificationScheduler.scheduleDelayIfNeeded(journey: journey, delayMinutes: newDelay)
            if let threshold = notificationScheduler.nextUnnotifiedThreshold(
                current: newDelay,
                last: journey.lastNotifiedDelayThreshold
            ) {
                journey.lastNotifiedDelayThreshold = threshold
            }
            journey.lastKnownDelayMinutes = newDelay
        }

        // Platform change
        if let new = newPlatform, new != journey.lastKnownPlatform, !isCancelled {
            await notificationScheduler.schedulePlatformChange(
                journey: journey,
                newPlatform: new,
                oldPlatform: journey.lastKnownPlatform
            )
            journey.lastKnownPlatform = new
        }

        journey.lastStatusRaw = isCancelled ? 2 : (newDelay > 0 ? 1 : 0)
        return service
    }
}
