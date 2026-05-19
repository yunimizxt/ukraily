import Foundation
import Combine

/// Drives the Watch UI. Reads from SharedDataStore (App Group UserDefaults)
/// and refreshes on a 60-second timer — no WCSession required.
@MainActor
final class WatchDataManager: ObservableObject {

    static let shared = WatchDataManager()

    @Published private(set) var journeys: [TrackedJourneySnapshot] = []
    @Published private(set) var lastRefreshed: Date? = nil

    private var timer: Timer?

    private init() {
        reload()
        startTimer()
    }

    // MARK: - Public

    func reload() {
        journeys = SharedDataStore.loadJourneys()
        lastRefreshed = SharedDataStore.lastUpdated
    }

    var nextJourney: TrackedJourneySnapshot? {
        journeys.first { $0.scheduledDeparture > .now }
    }

    // MARK: - Private

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.reload() }
        }
    }
}
