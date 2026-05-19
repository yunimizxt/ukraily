import Foundation

enum DarwinError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse(Int)
    case parseFailure(Error)
    case networkFailure(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:          return "Darwin API key not configured."
        case .invalidResponse(let c): return "Darwin returned HTTP \(c)."
        case .parseFailure(let e):    return "Parse error: \(e.localizedDescription)"
        case .networkFailure(let e):  return "Network error: \(e.localizedDescription)"
        }
    }
}

final class DarwinSOAPClient {

    static let shared = DarwinSOAPClient()

    private static let endpoint = URL(string: "https://lite.realtime.nationalrail.co.uk/OpenLDBWS/ldb11.asmx")!
    private static let timeoutInterval: TimeInterval = 10

    private let session: URLSession
    private let requestBuilder: DarwinSOAPRequestBuilder

    init(session: URLSession = .shared) {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "DarwinAPIKey") as? String,
              !apiKey.isEmpty else {
            // Allow init to succeed; calls will throw .missingAPIKey
            self.session = session
            self.requestBuilder = DarwinSOAPRequestBuilder(apiKey: "")
            return
        }
        self.session = session
        self.requestBuilder = DarwinSOAPRequestBuilder(apiKey: apiKey)
    }

    // For unit testing with a mock API key
    init(apiKey: String, session: URLSession = .shared) {
        self.session = session
        self.requestBuilder = DarwinSOAPRequestBuilder(apiKey: apiKey)
    }

    // MARK: - Public API

    func fetchDepartureBoard(crs: String, count: Int = 10) async throws -> GetDepartureBoardResponse {
        let xml = requestBuilder.buildDepartureBoardRequest(crs: crs, count: count)
        let data = try await post(xml: xml, action: DarwinOperation.getDepartureBoard.soapAction)
        do {
            let parser = DarwinSOAPResponseParser()
            return try parser.parseDepartureBoard(data: data)
        } catch {
            throw DarwinError.parseFailure(error)
        }
    }

    func fetchStationBoardWithDetails(crs: String, count: Int = 10) async throws -> GetDepartureBoardResponse {
        let xml = requestBuilder.buildStationBoardWithDetailsRequest(crs: crs, count: count)
        let data = try await post(xml: xml, action: DarwinOperation.getStationBoardWithDetails.soapAction)
        do {
            let parser = DarwinSOAPResponseParser()
            return try parser.parseDepartureBoard(data: data)
        } catch {
            throw DarwinError.parseFailure(error)
        }
    }

    func fetchServiceDetails(serviceID: String) async throws -> GetServiceDetailsResponse {
        let xml = requestBuilder.buildServiceDetailsRequest(serviceID: serviceID)
        let data = try await post(xml: xml, action: DarwinOperation.getServiceDetails.soapAction)
        do {
            let parser = DarwinSOAPResponseParser()
            return try parser.parseServiceDetails(data: data)
        } catch {
            throw DarwinError.parseFailure(error)
        }
    }

    // MARK: - Private

    private func post(xml: String, action: String) async throws -> Data {
        guard let body = xml.data(using: .utf8) else {
            throw DarwinError.parseFailure(DarwinParseError.missingElement("request body"))
        }

        var request = URLRequest(url: Self.endpoint, timeoutInterval: Self.timeoutInterval)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("\"\"", forHTTPHeaderField: "SOAPAction")

        print("[Darwin] POST \(Self.endpoint)")
        print("[Darwin] SOAPAction: \"\(action)\"")
        print("[Darwin] Body:\n\(xml)")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw DarwinError.invalidResponse(-1)
            }
            guard (200..<300).contains(http.statusCode) else {
                // Log raw response body to help diagnose server errors
                if let body = String(data: data, encoding: .utf8) {
                    print("[Darwin] HTTP \(http.statusCode) response:\n\(body)")
                }
                throw DarwinError.invalidResponse(http.statusCode)
            }
            return data
        } catch let error as DarwinError {
            throw error
        } catch {
            throw DarwinError.networkFailure(error)
        }
    }
}
