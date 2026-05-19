import XCTest
@testable import UkrailyCore

final class SOAPParserTests: XCTestCase {

    private var fixtureData: Data {
        let url = Bundle.module.url(forResource: "GetDepartureBoardResponse", withExtension: "xml")!
        return try! Data(contentsOf: url)
    }

    func testParsesLocationName() throws {
        let parser = DarwinSOAPResponseParser()
        let result = try parser.parseDepartureBoard(data: fixtureData)
        XCTAssertEqual(result.locationName, "London Paddington")
    }

    func testParsesCRSCode() throws {
        let parser = DarwinSOAPResponseParser()
        let result = try parser.parseDepartureBoard(data: fixtureData)
        XCTAssertEqual(result.crs, "PAD")
    }

    func testParsesServiceCount() throws {
        let parser = DarwinSOAPResponseParser()
        let result = try parser.parseDepartureBoard(data: fixtureData)
        XCTAssertEqual(result.services.count, 2)
    }

    func testFirstServiceFields() throws {
        let parser = DarwinSOAPResponseParser()
        let result = try parser.parseDepartureBoard(data: fixtureData)
        let svc = result.services[0]
        XCTAssertEqual(svc.serviceID, "SVC001")
        XCTAssertEqual(svc.scheduledDeparture, "14:32")
        XCTAssertEqual(svc.estimatedDeparture, "On time")
        XCTAssertEqual(svc.platform, "3")
        XCTAssertEqual(svc.operatorName, "GWR")
        XCTAssertFalse(svc.isCancelled)
    }

    func testDelayedServiceFields() throws {
        let parser = DarwinSOAPResponseParser()
        let result = try parser.parseDepartureBoard(data: fixtureData)
        let svc = result.services[1]
        XCTAssertEqual(svc.estimatedDeparture, "14:52")
        XCTAssertNil(svc.platform)
    }

    func testGeneratedAtParsed() throws {
        let parser = DarwinSOAPResponseParser()
        let result = try parser.parseDepartureBoard(data: fixtureData)
        XCTAssertNotNil(result.generatedAt)
    }

    func testThrowsOnEmptyData() {
        let parser = DarwinSOAPResponseParser()
        XCTAssertThrowsError(try parser.parseDepartureBoard(data: Data()))
    }
}
