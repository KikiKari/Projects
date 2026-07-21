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

    func testMobilePlayerFocusExcludesTikTokChatAndTargetsOnlyPrimaryVideo() throws {
        let testURL = URL(fileURLWithPath: #filePath)
        let mobileRoot = testURL.deletingLastPathComponent().deletingLastPathComponent()
        let bridge = try String(contentsOf: mobileRoot.appendingPathComponent("TikTokLiveCompanion/Resources/webview-bridge.js"))
        XCTAssertTrue(bridge.contains("function containsChatSurface"))
        XCTAssertTrue(bridge.contains("data-tlc-mobile-primary-video"))
        XCTAssertTrue(bridge.contains("data-tlc-mobile-video-layer"))
        XCTAssertFalse(bridge.contains("[data-tlc-mobile-player=\"true\"] video"))
        XCTAssertFalse(bridge.contains("videoArea * 3.5"))
    }
}
