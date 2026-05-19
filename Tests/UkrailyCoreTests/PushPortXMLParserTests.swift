import XCTest
@testable import UkrailyCore

final class PushPortXMLParserTests: XCTestCase {

    private var fixtureData: Data {
        let url = Bundle.module.url(forResource: "TSMessage", withExtension: "xml")!
        return try! Data(contentsOf: url)
    }

    func testParsesRID() throws {
        let parser = PushPortXMLParser()
        let messages = try parser.parse(data: fixtureData)
        XCTAssertFalse(messages.isEmpty)
        XCTAssertEqual(messages[0].rid, "202605191234567")
    }

    func testParsesUID() throws {
        let parser = PushPortXMLParser()
        let messages = try parser.parse(data: fixtureData)
        XCTAssertEqual(messages[0].uid, "G12345")
    }

    func testParsesLocationCount() throws {
        let parser = PushPortXMLParser()
        let messages = try parser.parse(data: fixtureData)
        XCTAssertEqual(messages[0].locations.count, 3)
    }

    func testFirstLocationTiploc() throws {
        let parser = PushPortXMLParser()
        let messages = try parser.parse(data: fixtureData)
        XCTAssertEqual(messages[0].locations[0].tiploc, "PADTON")
    }

    func testFirstLocationEstimatedDeparture() throws {
        let parser = PushPortXMLParser()
        let messages = try parser.parse(data: fixtureData)
        XCTAssertEqual(messages[0].locations[0].estimatedDeparture, "14:37")
    }

    func testFirstLocationDelayMinutes() throws {
        let parser = PushPortXMLParser()
        let messages = try parser.parse(data: fixtureData)
        let delay = messages[0].locations[0].delayMinutes
        XCTAssertEqual(delay, 5, "Expected 5 min delay (14:32 → 14:37)")
    }

    func testPassesThroughNonGzipData() throws {
        let parser = PushPortXMLParser()
        XCTAssertNoThrow(try parser.parse(data: fixtureData))
    }
}
