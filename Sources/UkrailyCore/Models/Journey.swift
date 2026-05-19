import Foundation

struct Journey: Identifiable, Sendable {
    let id: UUID
    let origin: Station
    let destination: Station
    let date: Date
    var resolvedService: TrainService?

    init(
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
