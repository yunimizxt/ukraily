import SwiftUI

@main
struct UkrailyWatchApp: App {

    @StateObject private var bridge = WatchConnectivityBridge.shared

    var body: some Scene {
        WindowGroup {
            JourneyListView()
                .environmentObject(bridge)
        }
    }
}
