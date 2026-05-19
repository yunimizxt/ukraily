import XCTest
@testable import UkrailyCore

final class TrainStatusUpdateTests: XCTestCase {

    func testTrainStatusUpdateCarriesPlatform() {
        let update = TrainStatusUpdate(rid: "ABC123", delayMinutes: 5, platform: "7", isCancelled: false)
        XCTAssertEqual(update.rid, "ABC123")
        XCTAssertEqual(update.delayMinutes, 5)
        XCTAssertEqual(update.platform, "7")
        XCTAssertFalse(update.isCancelled)
    }

    func testTrainStatusUpdateCancellation() {
        let update = TrainStatusUpdate(rid: "ABC123", delayMinutes: nil, platform: nil, isCancelled: true)
        XCTAssertTrue(update.isCancelled)
        XCTAssertNil(update.delayMinutes)
    }

    func testTrainServiceStatusOnTime() {
        let service = MockData.onTimeService
        if case .onTime = service.status { } else {
            XCTFail("Expected .onTime, got \(service.status)")
        }
        XCTAssertFalse(service.status.isDisrupted)
    }

    func testTrainServiceStatusDelayed() {
        let service = MockData.delayedService
        if case .delayed(let mins) = service.status {
            XCTAssertEqual(mins, 7)
        } else {
            XCTFail("Expected .delayed(7), got \(service.status)")
        }
        XCTAssertTrue(service.status.isDisrupted)
    }

    func testTrainServiceStatusCancelled() {
        let service = MockData.cancelledService
        XCTAssertEqual(service.status, .cancelled)
        XCTAssertTrue(service.status.isDisrupted)
    }

    func testCallingPointDelayMinutes() {
        let delayed = MockData.delayedService
        let firstPoint = delayed.callingPoints.first!
        XCTAssertEqual(firstPoint.delayMinutes, 7)
    }

    func testCallingPointNoDelayWhenOnTime() {
        let onTime = MockData.onTimeService
        let firstPoint = onTime.callingPoints.first!
        XCTAssertEqual(firstPoint.delayMinutes, 0)
    }

    func testScheduledArrivalReturnsLastCallingPoint() {
        let service = MockData.onTimeService
        XCTAssertNotNil(service.scheduledArrival)
        XCTAssertEqual(service.scheduledArrival, service.callingPoints.last?.scheduledTime)
    }
}
