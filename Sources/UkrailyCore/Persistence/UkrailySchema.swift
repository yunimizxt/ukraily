import Foundation
import SwiftData

@Model
final class TrackedJourney {
    var id: UUID
    var serviceID: String
    var originCRS: String
    var originName: String
    var destinationCRS: String
    var destinationName: String
    var scheduledDeparture: Date
    var isActive: Bool
    var lastStatusRaw: Int
    var lastKnownPlatform: String?
    var lastKnownDelayMinutes: Int
    var lastNotifiedDelayThreshold: Int
    var addedAt: Date

    init(
        id: UUID = UUID(),
        serviceID: String,
        originCRS: String,
        originName: String,
        destinationCRS: String,
        destinationName: String,
        scheduledDeparture: Date,
        isActive: Bool = true,
        lastStatusRaw: Int = 0,
        lastKnownPlatform: String? = nil,
        lastKnownDelayMinutes: Int = 0,
        lastNotifiedDelayThreshold: Int = 0,
        addedAt: Date = .now
    ) {
        self.id = id
        self.serviceID = serviceID
        self.originCRS = originCRS
        self.originName = originName
        self.destinationCRS = destinationCRS
        self.destinationName = destinationName
        self.scheduledDeparture = scheduledDeparture
        self.isActive = isActive
        self.lastStatusRaw = lastStatusRaw
        self.lastKnownPlatform = lastKnownPlatform
        self.lastKnownDelayMinutes = lastKnownDelayMinutes
        self.lastNotifiedDelayThreshold = lastNotifiedDelayThreshold
        self.addedAt = addedAt
    }
}

extension TrackedJourney {
    var origin: Station {
        Station(crsCode: originCRS, name: originName)
    }

    var destination: Station {
        Station(crsCode: destinationCRS, name: destinationName)
    }
}

@Model
final class SavedStation {
    var crsCode: String
    var name: String
    var addedAt: Date

    init(crsCode: String, name: String, addedAt: Date = .now) {
        self.crsCode = crsCode
        self.name = name
        self.addedAt = addedAt
    }

    var station: Station {
        Station(crsCode: crsCode, name: name)
    }
}
