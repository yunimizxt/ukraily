import Foundation
import Combine
import SwiftData
import WidgetKit

@MainActor
final class TrainCardViewModel: ObservableObject {

    @Published var service: TrainService?
    @Published var loadState: LoadState = .idle
    @Published var isTracked = false
    @Published var bannerMessage: String? = nil

    let serviceID: String
    private var boardStation: Station = .londonPaddington

    private let liveRepo: LiveTrainRepository
    private let journeyRepo: JourneyRepository
    private var cancellables = Set<AnyCancellable>()

    // Used to detect platform changes
    private var lastKnownPlatform: String? = nil

    init(
        serviceID: String,
        liveRepo: LiveTrainRepository = .shared,
        journeyRepo: JourneyRepository = .shared
    ) {
        self.serviceID = serviceID
        self.liveRepo = liveRepo
        self.journeyRepo = journeyRepo
        subscribeToLiveUpdates()
    }

    /// Preview / test initialiser with a pre-loaded service.
    init(previewService: TrainService) {
        self.serviceID = previewService.serviceID
        self.liveRepo = .shared
        self.journeyRepo = .shared
        self.service = previewService
        self.lastKnownPlatform = previewService.platform
        self.loadState = .loaded
    }

    // MARK: - Loading

    func load(context: ModelContext) async {
        checkTrackedState(context: context)

        if let cached = liveRepo.cachedService(id: serviceID) {
            service = cached
            lastKnownPlatform = cached.platform
            loadState = .loaded
            return
        }
        loadState = .loading
        do {
            let fetched = try await liveRepo.fetchServiceDetails(
                serviceID: serviceID,
                boardStation: boardStation
            )
            service = fetched
            lastKnownPlatform = fetched.platform
            loadState = .loaded
        } catch {
            loadState = .error(error)
        }
    }

    // MARK: - Tracking

    func toggleTracking(context: ModelContext) {
        guard let service else { return }
        if isTracked {
            untrack(serviceID: serviceID, context: context)
        } else {
            journeyRepo.track(service: service, context: context)
            isTracked = true
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Private

    private func checkTrackedState(context: ModelContext) {
        let id = serviceID
        let descriptor = FetchDescriptor<TrackedJourney>(
            predicate: #Predicate { $0.serviceID == id }
        )
        isTracked = (try? context.fetch(descriptor))?.isEmpty == false
    }

    private func untrack(serviceID: String, context: ModelContext) {
        let id = serviceID
        let descriptor = FetchDescriptor<TrackedJourney>(
            predicate: #Predicate { $0.serviceID == id }
        )
        if let journeys = try? context.fetch(descriptor) {
            journeys.forEach { context.delete($0) }
        }
        isTracked = false
    }

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
        guard let current = service else { return }

        // Detect platform change
        if let newPlatform = update.platform,
           let oldPlatform = lastKnownPlatform,
           newPlatform != oldPlatform {
            bannerMessage = "Platform changed: now departing from Platform \(newPlatform)"
        } else if let newPlatform = update.platform, lastKnownPlatform == nil {
            bannerMessage = "Platform confirmed: Platform \(newPlatform)"
        }

        // Detect cancellation
        if update.isCancelled && !current.isCancelled {
            bannerMessage = "This service has been cancelled"
        }

        let delay = update.delayMinutes ?? current.status.delayMinutes
        let platform = update.platform ?? current.platform
        lastKnownPlatform = platform

        let estimatedDep: Date?
        if update.isCancelled {
            estimatedDep = nil
        } else if delay > 0 {
            estimatedDep = current.scheduledDeparture.addingTimeInterval(Double(delay) * 60)
        } else {
            estimatedDep = current.scheduledDeparture
        }

        service = TrainService(
            serviceID: current.serviceID,
            operatorName: current.operatorName,
            scheduledDeparture: current.scheduledDeparture,
            estimatedDeparture: estimatedDep,
            platform: platform,
            isCancelled: update.isCancelled,
            origin: current.origin,
            destination: current.destination,
            callingPoints: current.callingPoints
        )
    }
}
