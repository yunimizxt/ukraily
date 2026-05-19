import Foundation

enum DarwinOperation: String {
    case getDepartureBoard      = "GetDepartureBoard"
    case getArrivalBoard        = "GetArrivalBoard"
    case getStationBoardWithDetails = "GetStationBoardWithDetails"
    case getServiceDetails      = "GetServiceDetails"

    var soapAction: String {
        "http://thalesgroup.com/RTTI/2021-11-01/ldb/\(rawValue)"
    }
}

struct DarwinSOAPRequestBuilder {

    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func buildDepartureBoardRequest(crs: String, count: Int = 10, filterCRS: String? = nil) -> String {
        let filter = filterCRS.map { "<ldb:filterCrs>\($0)</ldb:filterCrs>" } ?? ""
        return envelope(body: """
        <ldb:GetDepartureBoardRequest>
            <ldb:numRows>\(count)</ldb:numRows>
            <ldb:crs>\(crs)</ldb:crs>
            \(filter)
        </ldb:GetDepartureBoardRequest>
        """)
    }

    func buildArrivalBoardRequest(crs: String, count: Int = 10) -> String {
        envelope(body: """
        <ldb:GetArrivalBoardRequest>
            <ldb:numRows>\(count)</ldb:numRows>
            <ldb:crs>\(crs)</ldb:crs>
        </ldb:GetArrivalBoardRequest>
        """)
    }

    func buildStationBoardWithDetailsRequest(crs: String, count: Int = 10) -> String {
        envelope(body: """
        <ldb:GetStationBoardWithDetailsRequest>
            <ldb:numRows>\(count)</ldb:numRows>
            <ldb:crs>\(crs)</ldb:crs>
        </ldb:GetStationBoardWithDetailsRequest>
        """)
    }

    func buildServiceDetailsRequest(serviceID: String) -> String {
        envelope(body: """
        <ldb:GetServiceDetailsRequest>
            <ldb:serviceID>\(serviceID)</ldb:serviceID>
        </ldb:GetServiceDetailsRequest>
        """)
    }

    // MARK: - Private

    private func envelope(body: String) -> String {
        """
        <?xml version="1.0" encoding="utf-8"?>
        <soap:Envelope
            xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
            xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
            xmlns:ldb="http://thalesgroup.com/RTTI/2021-11-01/ldb/"
            xmlns:typ="http://thalesgroup.com/RTTI/2013-11-28/Token/types">
          <soap:Header>
            <wsse:Security>
              <typ:AccessToken>
                <typ:TokenValue>\(apiKey)</typ:TokenValue>
              </typ:AccessToken>
            </wsse:Security>
          </soap:Header>
          <soap:Body>
            \(body)
          </soap:Body>
        </soap:Envelope>
        """
    }
}
