import Foundation
import WatchConnectivity
import UkrailyCore

/// Transfers active journey snapshots from the iPhone app to the Watch.
public final class WatchConnectivityBridge: NSObject, WCSessionDelegate, ObservableObject {

    public static let shared = WatchConnectivityBridge()

    @Published public private(set) var receivedJourneys: [TrackedJourneySnapshot] = []

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - iOS → Watch push

    /// Call from the iOS app whenever a tracked journey's status changes.
    public func send(journeys: [TrackedJourneySnapshot]) {
        guard WCSession.default.activationState == .activated else { return }
        let payload = journeys.map(\.dictionaryRepresentation)
        try? WCSession.default.updateApplicationContext(["journeys": payload])
    }

    /// Send an immediate message for urgent events (platform change, cancellation).
    public func sendImmediate(event: JourneyEvent) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(event.dictionaryRepresentation, replyHandler: nil)
    }

    // MARK: - WCSessionDelegate

    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let raw = applicationContext["journeys"] as? [[String: Any]] else { return }
        let snapshots = raw.compactMap(TrackedJourneySnapshot.init(dictionary:))
        DispatchQueue.main.async { self.receivedJourneys = snapshots }
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Handled on Watch side
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif
}

// MARK: - Supporting types

public struct TrackedJourneySnapshot: Sendable, Identifiable {
    public let id: UUID
    public let serviceID: String
    public let originName: String
    public let destinationName: String
    public let scheduledDeparture: Date
    public let platform: String?
    public let delayMinutes: Int
    public let isCancelled: Bool

    public init(
        id: UUID = UUID(),
        serviceID: String,
        originName: String,
        destinationName: String,
        scheduledDeparture: Date,
        platform: String? = nil,
        delayMinutes: Int = 0,
        isCancelled: Bool = false
    ) {
        self.id = id
        self.serviceID = serviceID
        self.originName = originName
        self.destinationName = destinationName
        self.scheduledDeparture = scheduledDeparture
        self.platform = platform
        self.delayMinutes = delayMinutes
        self.isCancelled = isCancelled
    }

    init?(dictionary: [String: Any]) {
        guard let idStr = dictionary["id"] as? String, let id = UUID(uuidString: idStr),
              let serviceID = dictionary["serviceID"] as? String,
              let originName = dictionary["originName"] as? String,
              let destinationName = dictionary["destinationName"] as? String,
              let depInterval = dictionary["scheduledDeparture"] as? TimeInterval else { return nil }
        self.id = id
        self.serviceID = serviceID
        self.originName = originName
        self.destinationName = destinationName
        self.scheduledDeparture = Date(timeIntervalSince1970: depInterval)
        self.platform = dictionary["platform"] as? String
        self.delayMinutes = dictionary["delayMinutes"] as? Int ?? 0
        self.isCancelled = dictionary["isCancelled"] as? Bool ?? false
    }

    var dictionaryRepresentation: [String: Any] {
        var d: [String: Any] = [
            "id": id.uuidString,
            "serviceID": serviceID,
            "originName": originName,
            "destinationName": destinationName,
            "scheduledDeparture": scheduledDeparture.timeIntervalSince1970,
            "delayMinutes": delayMinutes,
            "isCancelled": isCancelled,
        ]
        if let p = platform { d["platform"] = p }
        return d
    }
}

public struct JourneyEvent: Sendable {
    public enum EventType: String { case platformChange, cancellation, delay }
    public let serviceID: String
    public let type: EventType
    public let detail: String

    var dictionaryRepresentation: [String: Any] {
        ["serviceID": serviceID, "type": type.rawValue, "detail": detail]
    }
}
