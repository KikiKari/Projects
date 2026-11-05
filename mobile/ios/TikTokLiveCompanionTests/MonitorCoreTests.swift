import Foundation
import XCTest
@testable import TikTokLiveCompanion

final class MonitorCoreTests: XCTestCase {
    func testSourcesAdvanceAndOnlyManualRestartWraps() {
        XCTAssertEqual(nextMonitorSource(index: 0, count: 3, manual: false), 1)
        XCTAssertNil(nextMonitorSource(index: 2, count: 3, manual: false))
        XCTAssertEqual(nextMonitorSource(index: 2, count: 3, manual: true), 0)
        XCTAssertNil(nextMonitorSource(index: 0, count: 0, manual: true))
    }
    func testPersistenceValidationAndGridOrder() throws {
        let name = "tlc.monitor.test.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = MonitorStore(defaults: defaults)
        var config = MonitorConfiguration()
        config.handles[7] = "creator7"; config.handles[8] = "creator8"; config.autoSort = true
        try store.save(config)
        XCTAssertEqual(store.load(), config)
        var rows = config.handles.map { MonitorEntry(handle: $0) }
        rows[7].status = .online; rows[8].status = .online
        XCTAssertEqual(monitorGridSlots(config, rows), [7, 8, 0, 1])
        rows[7].status = .checking; rows[7].sources = [try XCTUnwrap(URL(string: "https://example.invalid/live.m3u8"))]
        XCTAssertEqual(monitorGridSlots(config, rows), [7, 8, 0, 1])
        config.handles[0] = "creator7"
        XCTAssertThrowsError(try store.save(config))
    }
    func testProbeDistinguishesStatusAndIdentity() {
        let html = #"<script id="SIGI_STATE">{"LiveRoom":{"liveRoomUserInfo":{"user":{"uniqueId":"creator7"},"liveRoom":{"status":2,"url":"https://stream.tiktokcdn.com/live.m3u8"}}}}</script>"#
        XCTAssertEqual(MonitorProbe.parse(handle: "creator7", html: html, maxLinks: 5).status, .online)
        XCTAssertEqual(MonitorProbe.parse(handle: "other", html: html, maxLinks: 5).status, .error)
        XCTAssertEqual(MonitorProbe.parse(handle: "creator7", html: html.replacingOccurrences(of: "\"status\":2", with: "\"status\":4"), maxLinks: 5).status, .offline)
    }
    func testBackgroundResultCannotOverwriteAReassignedSlot() throws {
        let name = "tlc.monitor.test.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = MonitorStore(defaults: defaults)
        var config = MonitorConfiguration(); config.handles[0] = "alice"
        try store.save(config)
        let oldRevision = store.revision(0)
        var other = config; other.handles[0] = "bob"
        try store.save(other); try store.save(config)
        store.saveStatus(MonitorEntry(handle: "alice", status: .online, checkedAt: Date()), slot: 0, expectedRevision: oldRevision)
        XCTAssertEqual(store.loadRows(config)[0].status, .unknown)
    }
}
