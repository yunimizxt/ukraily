import Foundation

public struct StationRecord: Codable, Sendable {
    public let crsCode: String
    public let name: String
    public let lat: Double
    public let lon: Double

    enum CodingKeys: String, CodingKey {
        case crsCode = "crs"
        case name
        case lat
        case lon
    }
}

public final class CRSCodeLookup: @unchecked Sendable {

    public static let shared = CRSCodeLookup()

    private var records: [StationRecord] = []

    public init() {
        load()
    }

    public func search(_ query: String, limit: Int = 10) -> [Station] {
        guard !query.isEmpty else { return Array(records.prefix(limit).map(\.station)) }
        let q = query.lowercased()
        return records
            .filter { $0.name.lowercased().contains(q) || $0.crsCode.lowercased() == q }
            .sorted { score($0, query: q) > score($1, query: q) }
            .prefix(limit)
            .map(\.station)
    }

    public func station(forCRS crs: String) -> Station? {
        records.first(where: { $0.crsCode.uppercased() == crs.uppercased() })?.station
    }

    // MARK: - Private

    private func load() {
        guard let url = Bundle.module.url(forResource: "Stations", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        records = (try? JSONDecoder().decode([StationRecord].self, from: data)) ?? []
    }

    private func score(_ record: StationRecord, query: String) -> Int {
        let name = record.name.lowercased()
        if name == query { return 3 }
        if name.hasPrefix(query) { return 2 }
        return 1
    }
}

extension StationRecord {
    var station: Station {
        Station(crsCode: crsCode, name: name, lat: lat, lon: lon)
    }
}
