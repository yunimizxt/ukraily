import Foundation

struct Station: Hashable, Sendable, Identifiable, Codable {
    let crsCode: String
    let name: String
    let lat: Double
    let lon: Double

    var id: String { crsCode }

    init(crsCode: String, name: String, lat: Double = 0, lon: Double = 0) {
        self.crsCode = crsCode
        self.name = name
        self.lat = lat
        self.lon = lon
    }
}

extension Station {
    static let londonPaddington = Station(crsCode: "PAD", name: "London Paddington", lat: 51.5154, lon: -0.1755)
    static let londonKingsCross = Station(crsCode: "KGX", name: "London Kings Cross", lat: 51.5309, lon: -0.1233)
    static let londonWaterloo  = Station(crsCode: "WAT", name: "London Waterloo", lat: 51.5036, lon: -0.1114)
    static let manchester      = Station(crsCode: "MAN", name: "Manchester Piccadilly", lat: 53.4772, lon: -2.2309)
    static let bristol         = Station(crsCode: "BRI", name: "Bristol Temple Meads", lat: 51.4490, lon: -2.5810)
}
