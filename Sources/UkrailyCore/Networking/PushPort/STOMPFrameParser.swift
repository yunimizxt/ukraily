import Foundation

enum STOMPParseError: Error {
    case emptyInput
    case unknownCommand(String)
    case malformedHeader(String)
}

struct STOMPFrameParser {

    func parse(_ raw: String) throws -> STOMPFrame {
        guard !raw.isEmpty else { throw STOMPParseError.emptyInput }

        // Strip NULL terminator
        let trimmed = raw.hasSuffix(STOMPFrame.nullByte)
            ? String(raw.dropLast())
            : raw

        var lines = trimmed.components(separatedBy: "\n")
        guard let commandLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines),
              !commandLine.isEmpty else {
            throw STOMPParseError.emptyInput
        }
        lines.removeFirst()

        let command = STOMPFrame.Command(rawValue: commandLine) ?? .unknown

        var headers: [String: String] = [:]
        var bodyLines: [String] = []
        var parsingHeaders = true

        for line in lines {
            if parsingHeaders {
                if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    parsingHeaders = false
                    continue
                }
                let parts = line.split(separator: ":", maxSplits: 1)
                guard parts.count == 2 else { continue }
                headers[String(parts[0])] = String(parts[1])
            } else {
                bodyLines.append(line)
            }
        }

        let body = bodyLines.joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return STOMPFrame(command: command, headers: headers, body: body)
    }
}
