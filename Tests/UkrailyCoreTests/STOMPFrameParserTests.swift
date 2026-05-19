import XCTest
@testable import UkrailyCore

final class STOMPFrameParserTests: XCTestCase {

    let parser = STOMPFrameParser()

    func testParsesConnectFrame() throws {
        let raw = "CONNECT\naccept-version:1.2\nheart-beat:25000,0\n\n\0"
        let frame = try parser.parse(raw)
        XCTAssertEqual(frame.command, .connect)
        XCTAssertEqual(frame.headers["accept-version"], "1.2")
        XCTAssertEqual(frame.headers["heart-beat"], "25000,0")
    }

    func testParsesConnectedFrame() throws {
        let raw = "CONNECTED\nversion:1.2\nheart-beat:0,0\n\n\0"
        let frame = try parser.parse(raw)
        XCTAssertEqual(frame.command, .connected)
        XCTAssertEqual(frame.headers["version"], "1.2")
    }

    func testParsesMessageFrameWithBody() throws {
        let raw = "MESSAGE\ndestination:/topic/darwin.pushport-v16\n\n<xml>body</xml>\0"
        let frame = try parser.parse(raw)
        XCTAssertEqual(frame.command, .message)
        XCTAssertEqual(frame.body, "<xml>body</xml>")
    }

    func testParsesErrorFrame() throws {
        let raw = "ERROR\nmessage:auth failed\n\n\0"
        let frame = try parser.parse(raw)
        XCTAssertEqual(frame.command, .error)
        XCTAssertEqual(frame.headers["message"], "auth failed")
    }

    func testUnknownCommandParsed() throws {
        let raw = "WEIRDCOMMAND\n\n\0"
        let frame = try parser.parse(raw)
        XCTAssertEqual(frame.command, .unknown)
    }

    func testThrowsOnEmptyInput() {
        XCTAssertThrowsError(try parser.parse(""))
    }

    func testRoundTrip() throws {
        let original = STOMPFrame.connect(login: "user", passcode: "pass")
        let serialised = original.serialise()
        let parsed = try parser.parse(serialised)
        XCTAssertEqual(parsed.command, .connect)
        XCTAssertEqual(parsed.headers["login"], "user")
        XCTAssertEqual(parsed.headers["passcode"], "pass")
    }

    func testBodyWithoutNullTerminator() throws {
        let raw = "MESSAGE\n\n<data>hello</data>"
        let frame = try parser.parse(raw)
        XCTAssertEqual(frame.body, "<data>hello</data>")
    }
}
