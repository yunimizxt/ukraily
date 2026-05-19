import Foundation
import BackgroundTasks
import SwiftData
import UkrailyCore

final class BackgroundRefreshManager {

    static let shared = BackgroundRefreshManager()
    static let taskIdentifier = "com.ukraily.refresh"
    private static let minimumRefreshInterval: TimeInterval = 15 * 60  // 15 min

    private let liveTrains: LiveTrainRepository
    private let scheduler: NotificationScheduler

    private init(
        liveTrains: LiveTrainRepository = .shared,
        scheduler: NotificationScheduler = .shared
    ) {
        self.liveTrains = liveTrains
        self.scheduler = scheduler
    }

    // MARK: - Registration (call once at app init)

    func registerTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handle(task: task as! BGAppRefreshTask)
        }
    }

    func scheduleNext() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: Self.minimumRefreshInterval)
        try? BGTaskScheduler.shared.submit(request)
    }

    // MARK: - Task handler

    private func handle(task: BGAppRefreshTask) {
        // Schedule the next refresh immediately so we keep the chain going
        scheduleNext()

        let taskTask = Task {
            await refreshTrackedJourneys()
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            taskTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    // MARK: - Refresh logic

    @MainActor
    func refreshTrackedJourneys() async {
        guard let container = try? ModelContainer(
            for: TrackedJourney.self,
            configurations: ModelConfiguration(
                url: FileManager.default
                    .containerURL(forSecurityApplicationGroupIdentifier: "group.com.ukraily")?
                    .appendingPathComponent("Ukraily.store") ?? URL.documentsDirectory
            )
        ) else { return }

        let context = ModelContext(container)
        let now = Date.now
        let descriptor = FetchDescriptor<TrackedJourney>(
            predicate: #Predicate<TrackedJourney> { $0.isActive && $0.scheduledDeparture > now }
        )
        guard let journeys = try? context.fetch(descriptor) else { return }

        await withTaskGroup(of: Void.self) { group in
            for journey in journeys {
                group.addTask { [weak self] in
                    await self?.refresh(journey: journey, context: context)
                }
            }
        }

        try? context.save()
    }

    private func refresh(journey: TrackedJourney, context: ModelContext) async {
        let station = CRSCodeLookup.shared.station(forCRS: journey.originCRS) ?? journey.origin
        guard let service = try? await liveTrains.fetchServiceDetails(
            serviceID: journey.serviceID,
            boardStation: station
        ) else { return }

        let newDelay = service.status.delayMinutes
        let newPlatform = service.platform
        let isCancelled = service.isCancelled

        // Cancellation alert
        if isCancelled && journey.lastStatusRaw != 2 {
            await scheduler.scheduleCancellation(journey: journey)
            journey.lastStatusRaw = 2
        }

        // Delay threshold alert
        if !isCancelled && newDelay != journey.lastKnownDelayMinutes {
            await scheduler.scheduleDelayIfNeeded(journey: journey, delayMinutes: newDelay)
            // Advance the notified threshold if we sent one
            if let threshold = scheduler.nextUnnotifiedThreshold(
                current: newDelay,
                last: journey.lastNotifiedDelayThreshold
            ) {
                journey.lastNotifiedDelayThreshold = threshold
            }
            journey.lastKnownDelayMinutes = newDelay
        }

        // Platform change alert
        if let new = newPlatform, new != journey.lastKnownPlatform, !isCancelled {
            await scheduler.schedulePlatformChange(
                journey: journey,
                newPlatform: new,
                oldPlatform: journey.lastKnownPlatform
            )
            journey.lastKnownPlatform = new
        }

        // Pre-departure reminders (idempotent — re-scheduled each refresh)
        await scheduler.schedulePreDepartureReminders(for: journey)
    }
}
