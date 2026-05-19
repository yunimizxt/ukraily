import Foundation
import UserNotifications

// Protocol abstraction for testability
protocol NotificationCentreProtocol {
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers: [String])
    func pendingNotificationRequests() async -> [UNNotificationRequest]
}

extension UNUserNotificationCenter: NotificationCentreProtocol {}

// MARK: - Scheduler

final class NotificationScheduler: @unchecked Sendable {

    static let shared = NotificationScheduler()

    private let centre: any NotificationCentreProtocol

    init(centre: any NotificationCentreProtocol = UNUserNotificationCenter.current()) {
        self.centre = centre
    }

    // MARK: - Schedule pre-departure reminders

    /// Schedules T-30 and T-10 calendar triggers for a tracked journey.
    /// Safe to call multiple times — existing requests are replaced.
    func schedulePreDepartureReminders(for journey: TrackedJourney) async {
        guard UserDefaults.standard.bool(forKey: "notif.preDeparture") else { return }
        for minutes in [30, 10] {
            let fireDate = journey.scheduledDeparture.addingTimeInterval(-Double(minutes) * 60)
            guard fireDate > .now else { continue }

            let payload = NotificationPayload.preDeparture(journey: journey, minutesBefore: minutes)
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: fireDate
                ),
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: payload.requestIdentifier,
                content: payload.makeContent(),
                trigger: trigger
            )
            try? await centre.add(request)
        }
    }

    // MARK: - Platform change (immediate)

    func schedulePlatformChange(
        journey: TrackedJourney,
        newPlatform: String,
        oldPlatform: String?
    ) async {
        guard UserDefaults.standard.bool(forKey: "notif.platformChange") else { return }
        let payload = NotificationPayload.platformChange(
            journey: journey,
            newPlatform: newPlatform,
            oldPlatform: oldPlatform
        )
        let request = UNNotificationRequest(
            identifier: payload.requestIdentifier,
            content: payload.makeContent(),
            trigger: nil  // nil = fire immediately
        )
        try? await centre.add(request)
    }

    // MARK: - Delay thresholds

    /// Fires when the delay first crosses the 5 / 15 / 30 minute thresholds.
    /// Uses `journey.lastNotifiedDelayThreshold` to avoid duplicate alerts.
    func scheduleDelayIfNeeded(
        journey: TrackedJourney,
        delayMinutes: Int
    ) async {
        guard UserDefaults.standard.bool(forKey: "notif.delays") else { return }
        let threshold = nextUnnotifiedThreshold(current: delayMinutes, last: journey.lastNotifiedDelayThreshold)
        guard let threshold, let payload = NotificationPayload.delay(journey: journey, delayMinutes: threshold) else {
            return
        }
        let request = UNNotificationRequest(
            identifier: payload.requestIdentifier,
            content: payload.makeContent(),
            trigger: nil
        )
        try? await centre.add(request)
        // Caller must persist the new threshold on the journey object
    }

    // MARK: - Cancellation (immediate)

    func scheduleCancellation(journey: TrackedJourney) async {
        guard UserDefaults.standard.bool(forKey: "notif.cancellations") else { return }
        let payload = NotificationPayload.cancellation(journey: journey)
        let request = UNNotificationRequest(
            identifier: payload.requestIdentifier,
            content: payload.makeContent(),
            trigger: nil
        )
        try? await centre.add(request)
    }

    // MARK: - Cancel

    /// Removes all pending notifications for a journey.
    func cancelAllNotifications(for journeyID: UUID) {
        let prefix = "ukraily.journey.\(journeyID.uuidString)."
        Task {
            let pending = await centre.pendingNotificationRequests()
            let ids = pending.compactMap { req -> String? in
                req.identifier.hasPrefix(prefix) ? req.identifier : nil
            }
            centre.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Private

    /// Returns the lowest threshold that hasn't been notified yet.
    /// Thresholds: 5, 15, 30 minutes.
    func nextUnnotifiedThreshold(current: Int, last: Int) -> Int? {
        for threshold in [5, 15, 30] {
            if current >= threshold && last < threshold {
                return threshold
            }
        }
        return nil
    }
}
