import Foundation
import UkrailyCore

enum LoadState {
    case idle
    case loading
    case loaded
    case error(Error)

    var isLoading: Bool { if case .loading = self { return true }; return false }
    var errorMessage: String? { if case .error(let e) = self { return e.localizedDescription }; return nil }
}

@MainActor
final class DepartureBoardViewModel: ObservableObject {

    @Published var services: [TrainService] = []
    @Published var loadState: LoadState = .idle

    let crs: String
    let stationName: String

    private let repository: LiveTrainRepository

    init(crs: String, stationName: String, repository: LiveTrainRepository = .shared) {
        self.crs = crs
        self.stationName = stationName
        self.repository = repository
    }

    func load() async {
        guard !loadState.isLoading else { return }
        loadState = .loading
        do {
            services = try await repository.fetchDepartureBoard(crs: crs, count: 10)
            loadState = .loaded
        } catch {
            loadState = .error(error)
        }
    }

    func refresh() async {
        loadState = .idle
        await load()
    }
}
