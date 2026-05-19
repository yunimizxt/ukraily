import Foundation
import SwiftData

public final class PersistenceController {
    public static let shared = PersistenceController()

    public let container: ModelContainer

    public init(inMemory: Bool = false) {
        let schema = Schema([TrackedJourney.self, SavedStation.self])
        let storeURL: URL
        if inMemory {
            storeURL = URL(fileURLWithPath: "/dev/null")
        } else if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.ukraily"
        ) {
            storeURL = groupURL.appendingPathComponent("Ukraily.store")
        } else {
            storeURL = URL.documentsDirectory.appendingPathComponent("Ukraily.store")
        }
        let config = ModelConfiguration(schema: schema, url: storeURL)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
