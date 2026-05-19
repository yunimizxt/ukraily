import Foundation
import SwiftData

@Model
public final class TrackedJourney {
    public var id: UUID
    public var serviceID: String
    public var originCRS: String
    public var originName: String
    public var destinationCRS: String
    public var destinationName: String
    public var scheduledDeparture: Date
    public var isActive: Bool
    public var lastStatusRaw: Int
    public var lastKnownPlatform: String?
    public var lastKnownDelayMinutes: Int
    public var lastNotifiedDelayThreshold: Int
    public var addedAt: Date

    public init(
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
    public var origin: Station {
        Station(crsCode: originCRS, name: originName)
    }

    public var destination: Station {
        Station(crsCode: destinationCRS, name: destinationName)
    }
}

@Model
public final class SavedStation {
    public var crsCode: String
    public var name: String
    public var addedAt: Date

    public init(crsCode: String, name: String, addedAt: Date = .now) {
        self.crsCode = crsCode
        self.name = name
        self.addedAt = addedAt
    }

    public var station: Station {
        Station(crsCode: crsCode, name: name)
    }
}
