import XCTest
@testable import TikTokLiveCompanion

final class MobileUIStructureTests: XCTestCase {
    func testLandscapeVideoReservesScrollableContentHeight() {
        XCTAssertLessThanOrEqual(mobileVideoHeight(totalHeight: 360, landscape: true), 104)
        XCTAssertGreaterThanOrEqual(360 - 160 - mobileVideoHeight(totalHeight: 360, landscape: true), 96)
        XCTAssertEqual(mobileVideoHeight(totalHeight: 800, landscape: false), 400)
    }
    func testCapabilityRowsAreRenderedOnlyByLiveTab() throws {
        let testURL = URL(fileURLWithPath: #filePath)
        let sourceURL = testURL.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("TikTokLiveCompanion/ContentView.swift")
        let source = try String(contentsOf: sourceURL)
        let song = source.components(separatedBy: "private var songView")[1].components(separatedBy: "private var capabilityRows")[0]
        let status = source.components(separatedBy: "private var statusView")[1].components(separatedBy: "private var playerView")[0]
        XCTAssertFalse(song.contains("capabilityRows"))
        XCTAssertTrue(status.contains("capabilityRows"))
    }
}
