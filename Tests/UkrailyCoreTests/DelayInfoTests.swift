import XCTest
@testable import UkrailyCore

final class DelayInfoTests: XCTestCase {

    func testZeroMinutesIsOnTime() {
        XCTAssertEqual(DelayCategory.from(minutes: 0), .onTime)
    }

    func testOneToFourIsMinor() {
        XCTAssertEqual(DelayCategory.from(minutes: 1), .minor)
        XCTAssertEqual(DelayCategory.from(minutes: 4), .minor)
    }

    func testFiveToFourteenIsModerate() {
        XCTAssertEqual(DelayCategory.from(minutes: 5), .moderate)
        XCTAssertEqual(DelayCategory.from(minutes: 14), .moderate)
    }

    func testFifteenToTwentyNineIsSevere() {
        XCTAssertEqual(DelayCategory.from(minutes: 15), .severe)
        XCTAssertEqual(DelayCategory.from(minutes: 29), .severe)
    }

    func testThirtyPlusIsCritical() {
        XCTAssertEqual(DelayCategory.from(minutes: 30), .critical)
        XCTAssertEqual(DelayCategory.from(minutes: 120), .critical)
    }

    func testDelayInfoNone() {
        XCTAssertEqual(DelayInfo.none.minutes, 0)
        XCTAssertEqual(DelayInfo.none.category, .onTime)
    }

    func testTrainStatusOnTime() {
        let status = TrainStatus.onTime
        XCTAssertFalse(status.isDisrupted)
        XCTAssertEqual(status.delayMinutes, 0)
    }

    func testTrainStatusDelayed() {
        let status = TrainStatus.delayed(minutes: 10)
        XCTAssertTrue(status.isDisrupted)
        XCTAssertEqual(status.delayMinutes, 10)
    }

    func testTrainStatusCancelled() {
        let status = TrainStatus.cancelled
        XCTAssertTrue(status.isDisrupted)
    }
}
