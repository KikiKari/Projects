import XCTest
@testable import TikTokLiveCompanion

final class BridgeValidatorTests: XCTestCase {
    private let ready = #"{"version":1,"type":"bridge-ready","streamId":"","sequence":1,"timestamp":"2026-07-18T12:00:00Z","payload":{}}"#.data(using: .utf8)!

    func testAcceptsMainFrameTikTokEnvelope() throws {
        XCTAssertEqual(try BridgeValidator.decode(data: ready, origin: "https://www.tiktok.com", isMainFrame: true).type, "bridge-ready")
    }

    func testAcceptsMobileRuntimeEvents() throws {
        for type in ["media-links", "quick-recover", "limiter"] {
            let data = String(data: ready, encoding: .utf8)!.replacingOccurrences(of: "bridge-ready", with: type).data(using: .utf8)!
            XCTAssertEqual(try BridgeValidator.decode(data: data, origin: "https://www.tiktok.com", isMainFrame: true).type, type)
        }
    }

    func testRejectsWrongOrigin() {
        XCTAssertThrowsError(try BridgeValidator.decode(data: ready, origin: "https://evil.example", isMainFrame: true))
    }

    func testAcceptsSameOriginSubframe() throws {
        XCTAssertEqual(try BridgeValidator.decode(data: ready, origin: "https://www.tiktok.com", isMainFrame: false).type, "bridge-ready")
    }

    func testAcceptsNewDiagnosticTypes() throws {
        for type in ["socket-open", "force-start", "force-return", "media-url", "player-state"] {
            let data = String(data: ready, encoding: .utf8)!.replacingOccurrences(of: "bridge-ready", with: type).data(using: .utf8)!
            XCTAssertEqual(try BridgeValidator.decode(data: data, origin: "https://www.tiktok.com", isMainFrame: true).type, type)
        }
    }

    func testOnlyAllowsHTTPSResultLinks() {
        XCTAssertNotNil(BridgeValidator.validatedHTTPS("https://www.shazam.com/song/1"))
        XCTAssertNil(BridgeValidator.validatedHTTPS("javascript:alert(1)"))
    }

    func testRecommendationProgressIsAllowed() throws {
        let data = String(data: ready, encoding: .utf8)!.replacingOccurrences(of: "bridge-ready", with: "recommendation-scan-progress").data(using: .utf8)!
        XCTAssertEqual(try BridgeValidator.decode(data: data, origin: "https://www.tiktok.com", isMainFrame: true).type, "recommendation-scan-progress")
    }
    func testThreeHundredLargeRecommendationsAndUnchangedOtherLimits() throws {
        let items = (1...300).map { ["handle": "creator\($0)", "title": String(repeating: "x", count: 300)] }
        var object: [String: Any] = ["version": 1, "type": "recommendation-scan-progress", "streamId": "test", "sequence": 1, "timestamp": "2026-10-12", "payload": ["items": items]]
        let data = try JSONSerialization.data(withJSONObject: object)
        XCTAssertGreaterThan(data.count, BridgeValidator.maximumBytes)
        XCTAssertEqual(try BridgeValidator.decode(data: data, origin: BridgeValidator.allowedOrigin, isMainFrame: true).payload["items"]?.arrayValue?.count, 300)
        object["type"] = "chat"
        XCTAssertThrowsError(try BridgeValidator.decode(data: JSONSerialization.data(withJSONObject: object), origin: BridgeValidator.allowedOrigin, isMainFrame: true))
        object["type"] = "recommendation-scan-progress"
        object["payload"] = ["items": items + [["handle": "extra"]]]
        XCTAssertThrowsError(try BridgeValidator.decode(data: JSONSerialization.data(withJSONObject: object), origin: BridgeValidator.allowedOrigin, isMainFrame: true))
    }
}
