import Foundation
import SwiftUI
import UkrailyCore

@MainActor
final class HomeViewModel: ObservableObject {

    @Published var savedStations: [SavedStation] = []
    @Published var searchQuery = ""
    @Published var searchResults: [Station] = []

    private let stationRepo: StationRepository

    init(stationRepo: StationRepository = .shared) {
        self.stationRepo = stationRepo
    }

    func updateSearch(_ query: String) {
        searchQuery = query
        searchResults = stationRepo.search(query, limit: 8)
    }
}
