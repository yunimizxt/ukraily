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
                .task {
                    await AppNotificationDelegate.shared.requestAuthorisation()
                    // Push Port credentials come from the same xcconfig as the SOAP key.
                    // For now connect unauthenticated — the feed is open for registered users.
                    PushPortWebSocketClient.shared.connect()
                }
        }
        .modelContainer(PersistenceController.shared.container)
    }

    private func handleDeepLink(_ url: URL) {
        // ukraily://journey/<uuid>
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
