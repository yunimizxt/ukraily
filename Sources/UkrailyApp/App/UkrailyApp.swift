import SwiftUI
import SwiftData
import UkrailyCore

@main
struct UkrailyApp: App {

    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(environment)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(PersistenceController.shared.container)
    }

    private func handleDeepLink(_ url: URL) {
        // ukraily://journey/<id>
        guard url.scheme == "ukraily",
              url.host == "journey",
              let idString = url.pathComponents.dropFirst().first,
              let id = UUID(uuidString: idString) else { return }
        NotificationCenter.default.post(name: .openJourney, object: id)
    }
}

extension Notification.Name {
    static let openJourney = Notification.Name("com.ukraily.openJourney")
}
