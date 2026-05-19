import Foundation

public struct Journey: Identifiable, Sendable {
    public let id: UUID
    public let origin: Station
    public let destination: Station
    public let date: Date
    public var resolvedService: TrainService?

    public init(
        id: UUID = UUID(),
        origin: Station,
        destination: Station,
        date: Date,
        resolvedService: TrainService? = nil
    ) {
        self.id = id
        self.origin = origin
        self.destination = destination
        self.date = date
        self.resolvedService = resolvedService
    }
}
