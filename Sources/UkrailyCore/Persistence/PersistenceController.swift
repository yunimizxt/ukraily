import Foundation
import SwiftData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    init(inMemory: Bool = false) {
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
