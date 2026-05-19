import XCTest
@testable import UkrailyCore

final class CRSCodeLookupTests: XCTestCase {

    let lookup = CRSCodeLookup()

    func testSearchByPartialName() {
        let results = lookup.search("paddington")
        XCTAssertFalse(results.isEmpty, "Expected results for 'paddington'")
        XCTAssertEqual(results[0].crsCode, "PAD")
    }

    func testSearchByPrefix() {
        let results = lookup.search("bristo")
        XCTAssertTrue(results.contains(where: { $0.crsCode == "BRI" }), "Bristol should appear for 'bristo'")
    }

    func testSearchByCRS() {
        let results = lookup.search("KGX")
        XCTAssertTrue(results.contains(where: { $0.crsCode == "KGX" }))
    }

    func testStationForCRS() {
        let station = lookup.station(forCRS: "MAN")
        XCTAssertNotNil(station)
        XCTAssertEqual(station?.name, "Manchester Piccadilly")
    }

    func testCRSLookupCaseInsensitive() {
        let lower = lookup.station(forCRS: "pad")
        let upper = lookup.station(forCRS: "PAD")
        XCTAssertEqual(lower?.crsCode, upper?.crsCode)
    }

    func testEmptyQueryReturnsPopular() {
        let results = lookup.search("", limit: 5)
        XCTAssertEqual(results.count, 5)
    }

    func testUnknownCRSReturnsNil() {
        XCTAssertNil(lookup.station(forCRS: "ZZZ"))
    }

    func testResultsRespectLimit() {
        let results = lookup.search("london", limit: 3)
        XCTAssertLessThanOrEqual(results.count, 3)
    }
}
