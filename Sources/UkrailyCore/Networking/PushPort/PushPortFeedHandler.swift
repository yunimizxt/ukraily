import Foundation
import Combine

public struct TrainStatusUpdate: Sendable {
    public let rid: String
    public let delayMinutes: Int?
    public let platform: String?
    public let isCancelled: Bool
}

final class PushPortFeedHandler {

    let updates = PassthroughSubject<TrainStatusUpdate, Never>()

    private let xmlParser = PushPortXMLParser()

    func handle(frame: STOMPFrame) {
        guard frame.command == .message, !frame.body.isEmpty else { return }
        guard let data = frame.body.data(using: .utf8) else { return }

        let messages: [TSMessage]
        do {
            messages = try xmlParser.parse(data: data)
        } catch {
            return  // malformed frame — discard silently
        }

        for msg in messages {
            let maxDelay = msg.locations.compactMap(\.delayMinutes).max()
            let platform = msg.locations.compactMap(\.platform).last
            let cancelled = msg.locations.contains(where: \.isCancelled)
            updates.send(TrainStatusUpdate(
                rid: msg.rid,
                delayMinutes: maxDelay,
                platform: platform,
                isCancelled: cancelled
            ))
        }
    }
}
