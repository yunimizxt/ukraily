import Foundation

struct STOMPFrame: Sendable {

    enum Command: String, Sendable {
        case connect    = "CONNECT"
        case connected  = "CONNECTED"
        case subscribe  = "SUBSCRIBE"
        case send       = "SEND"
        case message    = "MESSAGE"
        case disconnect = "DISCONNECT"
        case error      = "ERROR"
        case receipt    = "RECEIPT"
        case unknown
    }

    let command: Command
    let headers: [String: String]
    let body: String

    // STOMP NULL byte terminator
    static let nullByte = "\0"

    func serialise() -> String {
        var lines = [command.rawValue]
        for (key, value) in headers {
            lines.append("\(key):\(value)")
        }
        lines.append("")  // blank line separates headers from body
        lines.append(body)
        lines.append(Self.nullByte)
        return lines.joined(separator: "\n")
    }

    static func connect(login: String = "", passcode: String = "", heartbeat: String = "25000,0") -> STOMPFrame {
        STOMPFrame(
            command: .connect,
            headers: [
                "accept-version": "1.2",
                "login": login,
                "passcode": passcode,
                "heart-beat": heartbeat,
            ],
            body: ""
        )
    }

    static func subscribe(destination: String, id: String) -> STOMPFrame {
        STOMPFrame(
            command: .subscribe,
            headers: ["destination": destination, "id": id, "ack": "auto"],
            body: ""
        )
    }

    static func heartbeat() -> STOMPFrame {
        STOMPFrame(command: .send, headers: ["destination": "/topic/heartbeat"], body: "")
    }

    static func disconnect() -> STOMPFrame {
        STOMPFrame(command: .disconnect, headers: [:], body: "")
    }
}
