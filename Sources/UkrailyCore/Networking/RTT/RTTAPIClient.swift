import Foundation

enum RTTError: Error, LocalizedError {
    case missingCredentials
    case invalidResponse(Int)
    case parseFailure(Error)
    case networkFailure(Error)

    var errorDescription: String? {
        switch self {
        case .missingCredentials:         return "RTT credentials not configured."
        case .invalidResponse(let code):  return "RTT returned HTTP \(code)."
        case .parseFailure(let e):        return "Parse error: \(e.localizedDescription)"
        case .networkFailure(let e):      return "Network error: \(e.localizedDescription)"
        }
    }
}

final class RTTAPIClient {

    static let shared = RTTAPIClient()

    private static let baseURL = URL(string: "https://api.rtt.io/api/v1/json")!
    private static let timeout: TimeInterval = 10

    private let session: URLSession
    private let username: String
    private let password: String

    init(session: URLSession = .shared) {
        self.username = Bundle.main.object(forInfoDictionaryKey: "RTTUsername") as? String ?? ""
        self.password = Bundle.main.object(forInfoDictionaryKey: "RTTPassword") as? String ?? ""
        self.session = session
        print("[RTT] Username from bundle: '\(self.username)'")
        print("[RTT] Password from bundle: '\(self.password.isEmpty ? "EMPTY" : "SET")'")
    }

    init(username: String, password: String, session: URLSession = .shared) {
        self.username = username
        self.password = password
        self.session = session
    }

    // MARK: - Public API

    func fetchDepartures(crs: String) async throws -> RTTLocationResponse {
        try await get(path: "search/\(crs.uppercased())")
    }

    func fetchServiceDetails(serviceUid: String, runDate: String) async throws -> RTTServiceResponse {
        try await get(path: "service/\(serviceUid)/\(runDate)")
    }

    // MARK: - Private

    private func get<T: Decodable>(path: String) async throws -> T {
        guard !username.isEmpty, !password.isEmpty else {
            throw RTTError.missingCredentials
        }

        let url = Self.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url, timeoutInterval: Self.timeout)
        let cred = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(cred)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw RTTError.invalidResponse(-1)
            }
            guard (200..<300).contains(http.statusCode) else {
                throw RTTError.invalidResponse(http.statusCode)
            }
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch let e as RTTError {
            throw e
        } catch let e as DecodingError {
            throw RTTError.parseFailure(e)
        } catch {
            throw RTTError.networkFailure(error)
        }
    }
}
