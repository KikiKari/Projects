import XCTest
@testable import TikTokLiveCompanion

final class BridgeValidatorTests: XCTestCase {
    private let ready = #"{"version":1,"type":"bridge-ready","streamId":"","sequence":1,"timestamp":"2026-07-18T12:00:00Z","payload":{}}"#.data(using: .utf8)!

    func testAcceptsMainFrameTikTokEnvelope() throws {
        XCTAssertEqual(try BridgeValidator.decode(data: ready, origin: "https://www.tiktok.com", isMainFrame: true).type, "bridge-ready")
    }

    func testRejectsWrongOrigin() {
        XCTAssertThrowsError(try BridgeValidator.decode(data: ready, origin: "https://evil.example", isMainFrame: true))
    }

    func testAcceptsSameOriginSubframe() throws {
        XCTAssertEqual(try BridgeValidator.decode(data: ready, origin: "https://www.tiktok.com", isMainFrame: false).type, "bridge-ready")
    }

    func testAcceptsNewDiagnosticTypes() throws {
        for type in ["socket-open", "force-return"] {
            let data = String(data: ready, encoding: .utf8)!.replacingOccurrences(of: "bridge-ready", with: type).data(using: .utf8)!
            XCTAssertEqual(try BridgeValidator.decode(data: data, origin: "https://www.tiktok.com", isMainFrame: true).type, type)
        }
    }

    func testOnlyAllowsHTTPSResultLinks() {
        XCTAssertNotNil(BridgeValidator.validatedHTTPS("https://www.shazam.com/song/1"))
        XCTAssertNil(BridgeValidator.validatedHTTPS("javascript:alert(1)"))
    }
}
