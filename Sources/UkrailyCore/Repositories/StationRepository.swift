import Foundation

public final class StationRepository {

    public static let shared = StationRepository()

    private let lookup = CRSCodeLookup.shared

    public init() {}

    public func search(_ query: String, limit: Int = 10) -> [Station] {
        lookup.search(query, limit: limit)
    }

    public func station(forCRS crs: String) -> Station? {
        lookup.station(forCRS: crs)
    }
}
