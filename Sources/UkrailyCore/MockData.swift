import Foundation

// Preview and test fixtures — not compiled into release builds
public enum MockData {

    public static let now = Date()

    public static let paddington = Station.londonPaddington
    public static let bristol    = Station.bristol
    public static let reading    = Station(crsCode: "RDG", name: "Reading", lat: 51.4591, lon: -0.9724)
    public static let swindon    = Station(crsCode: "SWI", name: "Swindon", lat: 51.5646, lon: -1.7846)

    public static var onTimeService: TrainService {
        TrainService(
            serviceID: "MOCK001",
            operatorName: "GWR",
            scheduledDeparture: now.addingTimeInterval(12 * 60),
            estimatedDeparture: now.addingTimeInterval(12 * 60),
            platform: "3",
            isCancelled: false,
            origin: paddington,
            destination: bristol,
            callingPoints: mockCallingPoints(departureOffset: 12 * 60)
        )
    }

    public static var delayedService: TrainService {
        TrainService(
            serviceID: "MOCK002",
            operatorName: "GWR",
            scheduledDeparture: now.addingTimeInterval(5 * 60),
            estimatedDeparture: now.addingTimeInterval(12 * 60),
            platform: "7",
            isCancelled: false,
            origin: paddington,
            destination: bristol,
            callingPoints: mockCallingPoints(departureOffset: 12 * 60, delayMinutes: 7)
        )
    }

    public static var cancelledService: TrainService {
        TrainService(
            serviceID: "MOCK003",
            operatorName: "GWR",
            scheduledDeparture: now.addingTimeInterval(20 * 60),
            estimatedDeparture: nil,
            platform: nil,
            isCancelled: true,
            origin: paddington,
            destination: bristol,
            callingPoints: []
        )
    }

    public static var departedService: TrainService {
        TrainService(
            serviceID: "MOCK004",
            operatorName: "GWR",
            scheduledDeparture: now.addingTimeInterval(-30 * 60),
            estimatedDeparture: now.addingTimeInterval(-29 * 60),
            platform: "1",
            isCancelled: false,
            origin: paddington,
            destination: bristol,
            callingPoints: mockCallingPoints(departureOffset: -30 * 60)
        )
    }

    // MARK: - Helpers

    private static func mockCallingPoints(departureOffset: TimeInterval, delayMinutes: Int = 0) -> [CallingPoint] {
        let delay = Double(delayMinutes) * 60
        let stops: [(Station, TimeInterval)] = [
            (paddington, departureOffset),
            (reading,    departureOffset + 25 * 60),
            (swindon,    departureOffset + 55 * 60),
            (bristol,    departureOffset + 85 * 60),
        ]
        return stops.map { station, offset in
            CallingPoint(
                station: station,
                scheduledTime: now.addingTimeInterval(offset),
                estimatedTime: delayMinutes > 0 ? now.addingTimeInterval(offset + delay) : nil,
                actualTime: offset + delay < 0 ? now.addingTimeInterval(offset + delay) : nil,
                platform: station == paddington ? "3" : nil
            )
        }
    }
}
