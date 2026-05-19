import SwiftUI
import SwiftData

@main
struct UkrailyApp: App {

    @StateObject private var environment = AppEnvironment()

    init() {
        // Must be registered before WindowGroup body is evaluated
        BackgroundRefreshManager.shared.registerTask()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(environment)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .task {
                    await AppNotificationDelegate.shared.requestAuthorisation()
                    PushPortWebSocketClient.shared.connect()
                    BackgroundRefreshManager.shared.scheduleNext()
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
