import SwiftUI

@main
struct UkrailyWatchApp: App {

    @StateObject private var dataManager = WatchDataManager.shared

    var body: some Scene {
        WindowGroup {
            JourneyListView()
                .environmentObject(dataManager)
        }
    }
}
