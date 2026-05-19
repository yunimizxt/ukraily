import Foundation

public struct Station: Hashable, Sendable, Identifiable, Codable {
    public let crsCode: String
    public let name: String
    public let lat: Double
    public let lon: Double

    public var id: String { crsCode }

    public init(crsCode: String, name: String, lat: Double = 0, lon: Double = 0) {
        self.crsCode = crsCode
        self.name = name
        self.lat = lat
        self.lon = lon
    }
}

extension Station {
    public static let londonPaddington = Station(crsCode: "PAD", name: "London Paddington", lat: 51.5154, lon: -0.1755)
    public static let londonKingsCross = Station(crsCode: "KGX", name: "London Kings Cross", lat: 51.5309, lon: -0.1233)
    public static let londonWaterloo  = Station(crsCode: "WAT", name: "London Waterloo", lat: 51.5036, lon: -0.1114)
    public static let manchester      = Station(crsCode: "MAN", name: "Manchester Piccadilly", lat: 53.4772, lon: -2.2309)
    public static let bristol         = Station(crsCode: "BRI", name: "Bristol Temple Meads", lat: 51.4490, lon: -2.5810)
}
