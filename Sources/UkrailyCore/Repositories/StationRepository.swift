import Foundation

final class StationRepository {

    static let shared = StationRepository()

    private let lookup = CRSCodeLookup.shared

    init() {}

    func search(_ query: String, limit: Int = 10) -> [Station] {
        lookup.search(query, limit: limit)
    }

    func station(forCRS crs: String) -> Station? {
        lookup.station(forCRS: crs)
    }
}
