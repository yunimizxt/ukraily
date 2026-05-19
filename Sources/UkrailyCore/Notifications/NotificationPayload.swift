import Foundation
import UserNotifications

// MARK: - Event types

enum NotificationEventType: String, Sendable {
    case preDeparture30  = "preDeparture30"
    case preDeparture10  = "preDeparture10"
    case platformChange  = "platformChange"
    case delay5          = "delay5"
    case delay15         = "delay15"
    case delay30         = "delay30"
    case cancellation    = "cancellation"
}

// MARK: - Payload

struct NotificationPayload: Sendable {

    let journeyID: UUID
    let serviceID: String
    let eventType: NotificationEventType
    let title: String
    let body: String

    var requestIdentifier: String {
        "ukraily.journey.\(journeyID.uuidString).\(eventType.rawValue)"
    }

    func makeContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = [
            "journeyID": journeyID.uuidString,
            "serviceID": serviceID,
            "eventType": eventType.rawValue,
        ]
        return content
    }
}

// MARK: - Factories

extension NotificationPayload {

    static func preDeparture(
        journey: TrackedJourney,
        minutesBefore: Int
    ) -> NotificationPayload {
        let eventType: NotificationEventType = minutesBefore == 30 ? .preDeparture30 : .preDeparture10
        return NotificationPayload(
            journeyID: journey.id,
            serviceID: journey.serviceID,
            eventType: eventType,
            title: "\(minutesBefore) min to departure",
            body: "\(journey.scheduledDeparture.formatted(date: .omitted, time: .shortened)) \(journey.originName) → \(journey.destinationName)"
                + (journey.lastKnownPlatform.map { " · Platform \($0)" } ?? "")
        )
    }

    static func platformChange(
        journey: TrackedJourney,
        newPlatform: String,
        oldPlatform: String?
    ) -> NotificationPayload {
        let from = oldPlatform.map { " (was \($0))" } ?? ""
        return NotificationPayload(
            journeyID: journey.id,
            serviceID: journey.serviceID,
            eventType: .platformChange,
            title: "Platform changed",
            body: "Your \(journey.scheduledDeparture.formatted(date: .omitted, time: .shortened)) to \(journey.destinationName) now departs from Platform \(newPlatform)\(from)"
        )
    }

    static func delay(
        journey: TrackedJourney,
        delayMinutes: Int
    ) -> NotificationPayload? {
        let eventType: NotificationEventType
        switch delayMinutes {
        case 5..<15:  eventType = .delay5
        case 15..<30: eventType = .delay15
        case 30...:   eventType = .delay30
        default:      return nil
        }
        return NotificationPayload(
            journeyID: journey.id,
            serviceID: journey.serviceID,
            eventType: eventType,
            title: "\(delayMinutes) minute delay",
            body: "Your \(journey.scheduledDeparture.formatted(date: .omitted, time: .shortened)) \(journey.originName) → \(journey.destinationName) is running \(delayMinutes) minutes late"
        )
    }

    static func cancellation(journey: TrackedJourney) -> NotificationPayload {
        NotificationPayload(
            journeyID: journey.id,
            serviceID: journey.serviceID,
            eventType: .cancellation,
            title: "Train cancelled",
            body: "Your \(journey.scheduledDeparture.formatted(date: .omitted, time: .shortened)) \(journey.originName) → \(journey.destinationName) has been cancelled"
        )
    }
}
