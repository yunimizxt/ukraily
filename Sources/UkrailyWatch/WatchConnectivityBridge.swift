import Foundation
import WatchConnectivity
import UkrailyCore

/// WCSession bridge — kept for future use but Watch UI no longer depends on it.
/// The Watch reads journey data from SharedDataStore (App Group UserDefaults) instead.
public final class WatchConnectivityBridge: NSObject, WCSessionDelegate, ObservableObject {

    public static let shared = WatchConnectivityBridge()

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - WCSessionDelegate

    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        // Write incoming context into SharedDataStore so Watch UI picks it up automatically
        guard let raw = applicationContext["journeys"] as? Data,
              let snapshots = try? JSONDecoder().decode([TrackedJourneySnapshot].self, from: raw)
        else { return }
        SharedDataStore.save(journeys: snapshots)
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif
}
