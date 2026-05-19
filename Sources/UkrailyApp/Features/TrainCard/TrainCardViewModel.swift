import Foundation
import Combine
import UkrailyCore

@MainActor
final class TrainCardViewModel: ObservableObject {

    @Published var service: TrainService?
    @Published var loadState: LoadState = .idle
    @Published var isTracked = false

    let serviceID: String
    private var boardStation: Station = .londonPaddington

    private let liveRepo: LiveTrainRepository
    private let journeyRepo: JourneyRepository
    private var cancellables = Set<AnyCancellable>()

    init(serviceID: String, liveRepo: LiveTrainRepository = .shared, journeyRepo: JourneyRepository = .shared) {
        self.serviceID = serviceID
        self.liveRepo = liveRepo
        self.journeyRepo = journeyRepo
        subscribeToLiveUpdates()
    }

    func load() async {
        if let cached = liveRepo.cachedService(id: serviceID) {
            service = cached
            loadState = .loaded
            return
        }
        loadState = .loading
        do {
            service = try await liveRepo.fetchServiceDetails(serviceID: serviceID, boardStation: boardStation)
            loadState = .loaded
        } catch {
            loadState = .error(error)
        }
    }

    func toggleTracking(context: any ModelContext) {
        // Simplified toggle — full SwiftData context injection handled in the view
        isTracked.toggle()
    }

    // MARK: - Private

    private func subscribeToLiveUpdates() {
        liveRepo.liveUpdates
            .filter { [weak self] update in update.rid == self?.serviceID }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.applyLiveUpdate(update)
            }
            .store(in: &cancellables)
    }

    private func applyLiveUpdate(_ update: TrainStatusUpdate) {
        guard var current = service else { return }
        let delay = update.delayMinutes ?? current.status.delayMinutes
        let platform = update.platform ?? current.platform
        let cancelled = update.isCancelled
        let estimated = delay > 0 ? current.scheduledDeparture.addingTimeInterval(Double(delay) * 60) : current.scheduledDeparture
        service = TrainService(
            serviceID: current.serviceID,
            operatorName: current.operatorName,
            scheduledDeparture: current.scheduledDeparture,
            estimatedDeparture: estimated,
            platform: platform,
            isCancelled: cancelled,
            origin: current.origin,
            destination: current.destination,
            callingPoints: current.callingPoints
        )
    }
}
