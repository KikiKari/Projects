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

    func testChatSummaryMuteListAndBackgroundAudioSources() throws {
        let testURL = URL(fileURLWithPath: #filePath)
        let mobileRoot = testURL.deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: mobileRoot.appendingPathComponent("TikTokLiveCompanion/ContentView.swift"))
        let chat = source.components(separatedBy: "private var chatView")[1].components(separatedBy: "private var statusView")[0]
        let status = source.components(separatedBy: "private var statusView")[1].components(separatedBy: "private var playerView")[0]
        XCTAssertTrue(chat.contains("suffix(5)"))
        XCTAssertTrue(chat.contains("Top-Chatter"))
        XCTAssertFalse(status.contains("Top-Chatter"))
        XCTAssertTrue(status.contains("Personen stummschalten"))
        let plist = try String(contentsOf: mobileRoot.appendingPathComponent("TikTokLiveCompanion/Info.plist"))
        XCTAssertTrue(plist.contains("UIBackgroundModes"))
        XCTAssertTrue(plist.contains("<string>audio</string>"))
        let controller = try String(contentsOf: mobileRoot.appendingPathComponent("TikTokLiveCompanion/BackgroundAudioController.swift"))
        XCTAssertTrue(controller.contains("setCategory(.playback"))
        XCTAssertTrue(source.components(separatedBy: "private var moreView")[1].contains("Debugmodus"))
    }

    func testMobilePlayerFocusUsesCenterFrameThenLiveOverviewAndPureFullscreen() throws {
        let testURL = URL(fileURLWithPath: #filePath)
        let mobileRoot = testURL.deletingLastPathComponent().deletingLastPathComponent()
        let repoRoot = mobileRoot.deletingLastPathComponent().deletingLastPathComponent()
        let bridgeURLs = [
            mobileRoot.appendingPathComponent("Resources/webview-bridge.js"),
            repoRoot.appendingPathComponent("plugin-source/mobile-shared/webview-bridge.js")
        ]
        for bridgeURL in bridgeURLs {
            let bridge = try String(contentsOf: bridgeURL)
            XCTAssertTrue(bridge.contains("[data-e2e=\"live-content-container\"]"), "\(bridgeURL.path) missing live-content-container selector")
            XCTAssertTrue(bridge.contains("[data-e2e=\"live-room-content\"]"), "\(bridgeURL.path) missing live-room-content selector")
            XCTAssertTrue(bridge.contains("[data-e2e=\"live-second-screen-container\"]"), "\(bridgeURL.path) missing live-second-screen selector")
            XCTAssertTrue(bridge.contains("data-tlc-mobile-content-root"), "\(bridgeURL.path) missing mobile content root marker")
            XCTAssertTrue(bridge.contains("data-tlc-mobile-primary-video"), "\(bridgeURL.path) missing primary video marker")
            XCTAssertTrue(bridge.contains("data-tlc-mobile-second-screen"), "\(bridgeURL.path) missing second screen marker")
            XCTAssertTrue(bridge.contains("display:none!important"), "\(bridgeURL.path) missing second screen hide style")
            XCTAssertFalse(bridge.contains("--tlc-scroll-y"), "\(bridgeURL.path) still uses scroll offset styling")
            XCTAssertFalse(bridge.contains("object-fit:contain"), "\(bridgeURL.path) still uses contained player styling")
            XCTAssertFalse(bridge.contains("[data-tlc-mobile-player=\"true\"] video"), "\(bridgeURL.path) still targets old mobile player marker")
            XCTAssertTrue(bridge.contains("optionale cookies ablehnen"), "\(bridgeURL.path) missing optional cookie rejection copy")
            XCTAssertTrue(bridge.contains("node.shadowRoot"), "\(bridgeURL.path) missing shadow root traversal")
        }
    }
}
