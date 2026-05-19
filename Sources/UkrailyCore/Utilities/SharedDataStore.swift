import Foundation

/// Persists active journey snapshots in the App Group UserDefaults container
/// so the Widget extension and Watch app can read without SwiftData access.
public enum SharedDataStore {

    private static let suiteName  = "group.com.ukraily"
    private static let journeyKey = "activeJourneys"
    private static let updatedKey = "activeJourneysUpdatedAt"

    // MARK: - Write (iOS app only)

    public static func save(journeys: [TrackedJourneySnapshot]) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        if let data = try? JSONEncoder().encode(journeys) {
            defaults.set(data, forKey: journeyKey)
            defaults.set(Date.now.timeIntervalSince1970, forKey: updatedKey)
        }
    }

    // MARK: - Read (Widget + Watch)

    public static func loadJourneys() -> [TrackedJourneySnapshot] {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: journeyKey),
              let journeys = try? JSONDecoder().decode([TrackedJourneySnapshot].self, from: data)
        else { return [] }

        // Filter to only upcoming journeys
        return journeys
            .filter { !$0.isCancelled && $0.scheduledDeparture > .now.addingTimeInterval(-60 * 60) }
            .sorted { $0.scheduledDeparture < $1.scheduledDeparture }
    }

    public static func nextJourney() -> TrackedJourneySnapshot? {
        loadJourneys().first { $0.scheduledDeparture > .now }
    }

    public static var lastUpdated: Date? {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return nil }
        let t = defaults.double(forKey: updatedKey)
        return t > 0 ? Date(timeIntervalSince1970: t) : nil
    }
}
