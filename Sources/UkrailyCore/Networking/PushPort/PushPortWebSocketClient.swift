import Foundation
import Combine

final class PushPortWebSocketClient {

    static let shared = PushPortWebSocketClient()

    private static let endpoint = URL(string: "wss://datafeeds.networkrail.co.uk/topic/darwin.pushport-v16")!
    private static let destination = "/topic/darwin.pushport-v16"
    private static let heartbeatInterval: TimeInterval = 25 * 60

    private var task: URLSessionWebSocketTask?
    private var heartbeatTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?
    private var reconnectAttempt = 0

    private let feedHandler = PushPortFeedHandler()
    private let frameParser = STOMPFrameParser()

    var updates: AnyPublisher<TrainStatusUpdate, Never> {
        feedHandler.updates.eraseToAnyPublisher()
    }

    func connect(username: String = "", password: String = "") {
        guard !username.isEmpty, !password.isEmpty else {
            print("[PushPort] Skipping connection — no Network Rail credentials provided.")
            return
        }
        reconnectAttempt = 0
        startConnection(username: username, password: password)
    }

    func disconnect() {
        receiveTask?.cancel()
        heartbeatTask?.cancel()
        sendFrame(STOMPFrame.disconnect())
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
    }

    // MARK: - Private

    private func startConnection(username: String, password: String) {
        let session = URLSession(configuration: .default)
        task = session.webSocketTask(with: Self.endpoint)
        task?.resume()

        sendFrame(STOMPFrame.connect(login: username, passcode: password))
        sendFrame(STOMPFrame.subscribe(destination: Self.destination, id: "ukraily-0"))

        receiveTask = Task { [weak self] in
            await self?.receiveLoop()
        }

        heartbeatTask = Task { [weak self] in
            await self?.heartbeatLoop()
        }
    }

    private func receiveLoop() async {
        while !Task.isCancelled {
            do {
                guard let task else { return }
                let message = try await task.receive()
                switch message {
                case .string(let text):
                    if let frame = try? frameParser.parse(text) {
                        feedHandler.handle(frame: frame)
                    }
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8),
                       let frame = try? frameParser.parse(text) {
                        feedHandler.handle(frame: frame)
                    }
                @unknown default:
                    break
                }
            } catch {
                guard !Task.isCancelled else { return }
                await scheduleReconnect()
                return
            }
        }
    }

    private func heartbeatLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Self.heartbeatInterval))
            guard !Task.isCancelled else { return }
            sendFrame(STOMPFrame.heartbeat())
        }
    }

    private func scheduleReconnect() async {
        let delay = min(pow(2.0, Double(reconnectAttempt)), 30)
        reconnectAttempt += 1
        try? await Task.sleep(for: .seconds(delay))
        guard !Task.isCancelled else { return }
        startConnection(username: "", password: "")
    }

    @discardableResult
    private func sendFrame(_ frame: STOMPFrame) -> Bool {
        guard let task else { return false }
        task.send(.string(frame.serialise())) { _ in }
        return true
    }
}
