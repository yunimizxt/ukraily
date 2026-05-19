import XCTest
import UserNotifications
@testable import UkrailyCore

// MARK: - Mock notification centre

final class MockNotificationCentre: NotificationCentreProtocol, @unchecked Sendable {

    private(set) var added: [UNNotificationRequest] = []
    private(set) var removedIDs: [String] = []

    func add(_ request: UNNotificationRequest) async throws {
        added.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIDs.append(contentsOf: identifiers)
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        added
    }

    func reset() { added = []; removedIDs = [] }
}

// MARK: - Helpers

private func makeJourney(
    id: UUID = UUID(),
    serviceID: String = "SVC001",
    delayMinutes: Int = 0,
    platform: String? = "3",
    lastNotifiedThreshold: Int = 0,
    statusRaw: Int = 0,
    departureOffset: TimeInterval = 35 * 60  // 35 min from now
) -> TrackedJourney {
    TrackedJourney(
        id: id,
        serviceID: serviceID,
        originCRS: "PAD",
        originName: "London Paddington",
        destinationCRS: "BRI",
        destinationName: "Bristol Temple Meads",
        scheduledDeparture: Date.now.addingTimeInterval(departureOffset),
        lastStatusRaw: statusRaw,
        lastKnownPlatform: platform,
        lastKnownDelayMinutes: delayMinutes,
        lastNotifiedDelayThreshold: lastNotifiedThreshold
    )
}

// MARK: - Tests

final class NotificationSchedulerTests: XCTestCase {

    var centre: MockNotificationCentre!
    var scheduler: NotificationScheduler!

    override func setUp() {
        super.setUp()
        centre = MockNotificationCentre()
        scheduler = NotificationScheduler(centre: centre)
        // Enable all notification types for tests
        UserDefaults.standard.set(true, forKey: "notif.preDeparture")
        UserDefaults.standard.set(true, forKey: "notif.delays")
        UserDefaults.standard.set(true, forKey: "notif.platformChange")
        UserDefaults.standard.set(true, forKey: "notif.cancellations")
    }

    override func tearDown() {
        super.tearDown()
        for key in ["notif.preDeparture", "notif.delays", "notif.platformChange", "notif.cancellations"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - Pre-departure reminders

    func testSchedulesT30AndT10() async {
        let journey = makeJourney(departureOffset: 35 * 60)
        await scheduler.schedulePreDepartureReminders(for: journey)
        XCTAssertEqual(centre.added.count, 2)
        let ids = Set(centre.added.map(\.identifier))
        XCTAssertTrue(ids.contains { $0.contains("preDeparture30") })
        XCTAssertTrue(ids.contains { $0.contains("preDeparture10") })
    }

    func testSkipsT30WhenDepartureIsLessThan30MinAway() async {
        let journey = makeJourney(departureOffset: 25 * 60)  // only 25 min away
        await scheduler.schedulePreDepartureReminders(for: journey)
        // Only T-10 should be scheduled (T-30 fire date is in the past)
        XCTAssertEqual(centre.added.count, 1)
        XCTAssertTrue(centre.added[0].identifier.contains("preDeparture10"))
    }

    func testSkipsBothWhenDepartureAlreadyPassed() async {
        let journey = makeJourney(departureOffset: -5 * 60)  // already departed
        await scheduler.schedulePreDepartureReminders(for: journey)
        XCTAssertEqual(centre.added.count, 0)
    }

    func testPreDepartureTriggerIsCalendarType() async {
        let journey = makeJourney(departureOffset: 35 * 60)
        await scheduler.schedulePreDepartureReminders(for: journey)
        for request in centre.added {
            XCTAssertTrue(
                request.trigger is UNCalendarNotificationTrigger,
                "Expected calendar trigger for \(request.identifier)"
            )
        }
    }

    func testPreDepartureTriggerFiresAtCorrectTime() async {
        let journey = makeJourney(departureOffset: 35 * 60)
        await scheduler.schedulePreDepartureReminders(for: journey)
        let t30Request = centre.added.first { $0.identifier.contains("preDeparture30") }!
        let trigger = t30Request.trigger as! UNCalendarNotificationTrigger
        let fireDate = Calendar.current.date(from: trigger.dateComponents)!
        let expected = journey.scheduledDeparture.addingTimeInterval(-30 * 60)
        XCTAssertEqual(fireDate.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 60)
    }

    // MARK: - Platform change

    func testSchedulesPlatformChangeImmediately() async {
        let journey = makeJourney(platform: "3")
        await scheduler.schedulePlatformChange(journey: journey, newPlatform: "7", oldPlatform: "3")
        XCTAssertEqual(centre.added.count, 1)
        XCTAssertNil(centre.added[0].trigger, "Platform change should fire immediately (nil trigger)")
        XCTAssertTrue(centre.added[0].identifier.contains("platformChange"))
    }

    func testPlatformChangeBodyContainsNewPlatform() async {
        let journey = makeJourney(platform: "3")
        await scheduler.schedulePlatformChange(journey: journey, newPlatform: "12", oldPlatform: "3")
        let body = centre.added[0].content.body
        XCTAssertTrue(body.contains("12"), "Body should mention new platform: \(body)")
        XCTAssertTrue(body.contains("was 3"), "Body should mention old platform: \(body)")
    }

    // MARK: - Delay thresholds

    func testFiresAt5MinThreshold() async {
        let journey = makeJourney(lastNotifiedThreshold: 0)
        await scheduler.scheduleDelayIfNeeded(journey: journey, delayMinutes: 6)
        XCTAssertEqual(centre.added.count, 1)
        XCTAssertTrue(centre.added[0].identifier.contains("delay5"))
    }

    func testFiresAt15MinThreshold() async {
        let journey = makeJourney(lastNotifiedThreshold: 5)
        await scheduler.scheduleDelayIfNeeded(journey: journey, delayMinutes: 17)
        XCTAssertEqual(centre.added.count, 1)
        XCTAssertTrue(centre.added[0].identifier.contains("delay15"))
    }

    func testFiresAt30MinThreshold() async {
        let journey = makeJourney(lastNotifiedThreshold: 15)
        await scheduler.scheduleDelayIfNeeded(journey: journey, delayMinutes: 32)
        XCTAssertEqual(centre.added.count, 1)
        XCTAssertTrue(centre.added[0].identifier.contains("delay30"))
    }

    func testDoesNotRepeatAlreadyNotifiedThreshold() async {
        let journey = makeJourney(lastNotifiedThreshold: 5)
        await scheduler.scheduleDelayIfNeeded(journey: journey, delayMinutes: 7)  // still in 5-min band
        XCTAssertEqual(centre.added.count, 0, "Should not re-fire at a threshold already notified")
    }

    func testNoNotificationBelowMinimumThreshold() async {
        let journey = makeJourney(lastNotifiedThreshold: 0)
        await scheduler.scheduleDelayIfNeeded(journey: journey, delayMinutes: 3)
        XCTAssertEqual(centre.added.count, 0)
    }

    func testDelayNotificationIsImmediate() async {
        let journey = makeJourney(lastNotifiedThreshold: 0)
        await scheduler.scheduleDelayIfNeeded(journey: journey, delayMinutes: 8)
        XCTAssertNil(centre.added[0].trigger, "Delay notification should fire immediately")
    }

    // MARK: - Cancellation

    func testSchedulesCancellationImmediately() async {
        let journey = makeJourney()
        await scheduler.scheduleCancellation(journey: journey)
        XCTAssertEqual(centre.added.count, 1)
        XCTAssertNil(centre.added[0].trigger)
        XCTAssertTrue(centre.added[0].identifier.contains("cancellation"))
    }

    func testCancellationBodyContainsDestination() async {
        let journey = makeJourney()
        await scheduler.scheduleCancellation(journey: journey)
        XCTAssertTrue(centre.added[0].content.body.contains("Bristol"))
    }

    // MARK: - Cancel all

    func testCancelAllRemovesAllJourneyNotifications() async {
        let id = UUID()
        let journey = makeJourney(id: id, departureOffset: 35 * 60)
        await scheduler.schedulePreDepartureReminders(for: journey)
        await scheduler.schedulePlatformChange(journey: journey, newPlatform: "5", oldPlatform: "3")

        scheduler.cancelAllNotifications(for: id)
        // Give the internal Task a moment to run
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(centre.removedIDs.count, 3, "Expected 3 pending IDs removed")
        for removedID in centre.removedIDs {
            XCTAssertTrue(removedID.contains(id.uuidString))
        }
    }

    // MARK: - User preference gates

    func testPreDepartureRespectsPref() async {
        UserDefaults.standard.set(false, forKey: "notif.preDeparture")
        let journey = makeJourney(departureOffset: 35 * 60)
        await scheduler.schedulePreDepartureReminders(for: journey)
        XCTAssertEqual(centre.added.count, 0, "Should not schedule when pref is off")
    }

    func testPlatformChangeRespectsPref() async {
        UserDefaults.standard.set(false, forKey: "notif.platformChange")
        let journey = makeJourney()
        await scheduler.schedulePlatformChange(journey: journey, newPlatform: "7", oldPlatform: "3")
        XCTAssertEqual(centre.added.count, 0)
    }

    func testCancellationRespectsPref() async {
        UserDefaults.standard.set(false, forKey: "notif.cancellations")
        let journey = makeJourney()
        await scheduler.scheduleCancellation(journey: journey)
        XCTAssertEqual(centre.added.count, 0)
    }

    func testDelayRespectsPref() async {
        UserDefaults.standard.set(false, forKey: "notif.delays")
        let journey = makeJourney(lastNotifiedThreshold: 0)
        await scheduler.scheduleDelayIfNeeded(journey: journey, delayMinutes: 8)
        XCTAssertEqual(centre.added.count, 0)
    }

    // MARK: - Threshold helper

    func testNextUnnotifiedThresholdEdgeCases() {
        XCTAssertNil(scheduler.nextUnnotifiedThreshold(current: 3, last: 0))
        XCTAssertEqual(scheduler.nextUnnotifiedThreshold(current: 5, last: 0), 5)
        XCTAssertEqual(scheduler.nextUnnotifiedThreshold(current: 15, last: 5), 15)
        XCTAssertEqual(scheduler.nextUnnotifiedThreshold(current: 31, last: 15), 30)
        XCTAssertNil(scheduler.nextUnnotifiedThreshold(current: 45, last: 30))
    }

    // MARK: - Payload userInfo

    func testPayloadUserInfoContainsJourneyID() async {
        let journey = makeJourney()
        await scheduler.scheduleCancellation(journey: journey)
        let info = centre.added[0].content.userInfo
        XCTAssertEqual(info["journeyID"] as? String, journey.id.uuidString)
        XCTAssertEqual(info["eventType"] as? String, NotificationEventType.cancellation.rawValue)
    }

    func testRequestIdentifierContainsJourneyID() {
        let id = UUID()
        let journey = makeJourney(id: id)
        let payload = NotificationPayload.cancellation(journey: journey)
        XCTAssertTrue(payload.requestIdentifier.contains(id.uuidString))
    }
}
