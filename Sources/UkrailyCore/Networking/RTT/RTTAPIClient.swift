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

private struct RTTAccessTokenResponse: Decodable {
    let token: String?
    let accessToken: String?
    let validUntil: String?

    var resolvedToken: String? { token ?? accessToken }
}

final class RTTAPIClient {

    static let shared = RTTAPIClient()

    private static let baseURL = URL(string: "https://data.rtt.io")!
    private static let timeout: TimeInterval = 10

    private let session: URLSession
    private let refreshToken: String

    private var accessToken: String?
    private var accessTokenExpiry: Date?

    init(session: URLSession = .shared) {
        self.refreshToken = Bundle.main.object(forInfoDictionaryKey: "RTTAPIToken") as? String ?? ""
        self.session = session
        print("[RTT] Refresh token from bundle: '\(self.refreshToken.isEmpty ? "EMPTY" : "SET (length \(self.refreshToken.count))")'")
    }

    init(refreshToken: String, session: URLSession = .shared) {
        self.refreshToken = refreshToken
        self.session = session
    }

    // MARK: - Public API

    func debugFetchStops() async {
        guard let token = try? await validAccessToken() else { return }
        var components = URLComponents(url: Self.baseURL.appendingPathComponent("data/stops"), resolvingAgainstBaseURL: false)!
        var request = URLRequest(url: components.url!, timeoutInterval: Self.timeout)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, _) = try? await session.data(for: request) else { return }
        let body = String(data: data, encoding: .utf8) ?? ""
        print("[RTT] Stops preview: \(body.prefix(1000))")
    }

    func fetchDepartures(crs: String) async throws -> RTTLocationResponse {
        try await get(path: "rtt/location", params: ["code": "gb-nr:\(crs.uppercased())"])
    }

    func fetchServiceDetails(serviceUid: String, runDate: String) async throws -> RTTServiceResponse {
        // runDate is "yyyy-MM-dd"; uniqueIdentity format: gb-nr:uid:date
        try await get(path: "rtt/service", params: [
            "uniqueIdentity": "gb-nr:\(serviceUid):\(runDate)"
        ])
    }

    // MARK: - Token exchange

    private func validAccessToken() async throws -> String {
        if let token = accessToken, let expiry = accessTokenExpiry, expiry > Date().addingTimeInterval(60) {
            return token
        }

        guard !refreshToken.isEmpty else { throw RTTError.missingCredentials }

        var components = URLComponents(url: Self.baseURL.appendingPathComponent("api/get_access_token"), resolvingAgainstBaseURL: false)!
        let url = components.url!
        var request = URLRequest(url: url, timeoutInterval: Self.timeout)
        request.httpMethod = "GET"
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        print("[RTT] Exchanging refresh token for access token at \(url)")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw RTTError.invalidResponse(-1) }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("[RTT] Token exchange HTTP \(http.statusCode): \(body.prefix(300))")
            throw RTTError.invalidResponse(http.statusCode)
        }

        let body = String(data: data, encoding: .utf8) ?? ""
        print("[RTT] Token exchange response: \(body.prefix(300))")

        let decoded = try JSONDecoder().decode(RTTAccessTokenResponse.self, from: data)
        guard let token = decoded.resolvedToken else {
            throw RTTError.parseFailure(NSError(domain: "RTT", code: 0, userInfo: [NSLocalizedDescriptionKey: "No token in response"]))
        }

        accessToken = token
        if let validUntilStr = decoded.validUntil,
           let expiry = ISO8601DateFormatter().date(from: validUntilStr) {
            accessTokenExpiry = expiry
        } else {
            accessTokenExpiry = Date().addingTimeInterval(3600)
        }

        print("[RTT] Access token obtained, valid until \(accessTokenExpiry!)")
        return token
    }

    // MARK: - Private

    private func get<T: Decodable>(path: String, params: [String: String] = [:]) async throws -> T {
        let token = try await validAccessToken()

        var components = URLComponents(url: Self.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !params.isEmpty {
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw RTTError.invalidResponse(-1) }

        print("[RTT] Requesting: \(url.absoluteString)")
        var request = URLRequest(url: url, timeoutInterval: Self.timeout)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw RTTError.invalidResponse(-1)
            }
            guard (200..<300).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                print("[RTT] HTTP \(http.statusCode): \(body.prefix(300))")
                throw RTTError.invalidResponse(http.statusCode)
            }
            let body = String(data: data, encoding: .utf8) ?? ""
            print("[RTT] Response preview: \(body.prefix(500))")
            return try JSONDecoder().decode(T.self, from: data)
        } catch let e as RTTError {
            throw e
        } catch let e as DecodingError {
            print("[RTT] Decode error: \(e)")
            throw RTTError.parseFailure(e)
        } catch {
            throw RTTError.networkFailure(error)
        }
    }
}
