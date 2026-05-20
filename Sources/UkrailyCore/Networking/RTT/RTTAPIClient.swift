import Foundation

enum RTTError: Error, LocalizedError {
    case missingCredentials
    case invalidResponse(Int)
    case parseFailure(Error)
    case networkFailure(Error)

    var errorDescription: String? {
        switch self {
        case .missingCredentials:         return "RTT API token not configured."
        case .invalidResponse(let code):  return "RTT returned HTTP \(code)."
        case .parseFailure(let e):        return "Parse error: \(e.localizedDescription)"
        case .networkFailure(let e):      return "Network error: \(e.localizedDescription)"
        }
    }
}

final class RTTAPIClient {

    static let shared = RTTAPIClient()

    private static let baseURL = URL(string: "https://data.rtt.io/api/v1/json")!
    private static let timeout: TimeInterval = 10

    private let session: URLSession
    private let apiToken: String

    init(session: URLSession = .shared) {
        self.apiToken = Bundle.main.object(forInfoDictionaryKey: "RTTAPIToken") as? String ?? ""
        self.session = session
        print("[RTT] API token from bundle: '\(self.apiToken.isEmpty ? "EMPTY" : "SET (length \(self.apiToken.count))")'")
    }

    init(apiToken: String, session: URLSession = .shared) {
        self.apiToken = apiToken
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
        guard !apiToken.isEmpty else {
            throw RTTError.missingCredentials
        }

        let url = Self.baseURL.appendingPathComponent(path)
        print("[RTT] Requesting: \(url.absoluteString)")
        var request = URLRequest(url: url, timeoutInterval: Self.timeout)
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw RTTError.invalidResponse(-1)
            }
            guard (200..<300).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                print("[RTT] HTTP \(http.statusCode): \(body.prefix(200))")
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
