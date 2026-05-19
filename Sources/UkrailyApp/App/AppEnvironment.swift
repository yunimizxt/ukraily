import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let stationRepository: StationRepository
    let liveTrainRepository: LiveTrainRepository
    let journeyRepository: JourneyRepository
    let networkMonitor: NetworkMonitor

    init() {
        stationRepository = .shared
        liveTrainRepository = .shared
        journeyRepository = .shared
        networkMonitor = .shared
    }
}
