import Foundation
let suite = "tlc.monitor.test.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName: suite)!
defer { defaults.removePersistentDomain(forName: suite) }
let store = MonitorStore(defaults: defaults)
var config = MonitorConfiguration()
precondition(store.load() == config)
config.handles[7] = "creator7"; config.handles[8] = "creator8"; config.autoSort = true
try store.save(config)
precondition(store.load() == config)
var rows = config.handles.map { MonitorEntry(handle: $0) }
rows[7].status = .online; rows[8].status = .online
precondition(monitorGridSlots(config, rows) == [7, 8, 0, 1])
rows[7].status = .checking; rows[7].sources = [URL(string: "https://example.invalid/stream.m3u8")!]
precondition(monitorGridSlots(config, rows) == [7, 8, 0, 1])
config.handles[0] = "creator7"
do { try store.save(config); fatalError("duplicate accepted") } catch MonitorStoreError.invalidConfiguration { }
precondition(MonitorConfiguration.normalize(" @Creator.Name ") == "creator.name")
print("MonitorCore: persistence, validation and grid selection passed")
let html = #"<script id="SIGI_STATE">{"LiveRoom":{"liveRoomUserInfo":{"user":{"uniqueId":"creator7"},"liveRoom":{"status":2,"url":"https://stream.tiktokcdn.com/live.m3u8"}}}}</script>"#
let online = MonitorProbe.parse(handle: "creator7", html: html, maxLinks: 5)
precondition(online.status == .online && online.sources.count == 1)
precondition(MonitorProbe.parse(handle: "other", html: html, maxLinks: 5).status == .error)
precondition(MonitorProbe.parse(handle: "creator7", html: html.replacingOccurrences(of: "\"status\":2", with: "\"status\":4"), maxLinks: 5).status == .offline)
precondition(!MonitorProbe.usable(URL(string: "https://evil.invalid/live.m3u8")!))
print("MonitorProbe: online, offline, wrong identity and domain validation passed")
var current = MonitorConfiguration(); current.handles[0] = "alice"
try store.save(current)
let oldRevision = store.revision(0)
var other = current; other.handles[0] = "bob"; try store.save(other)
try store.save(current)
store.saveStatus(MonitorEntry(handle: "alice", status: .online, checkedAt: Date()), slot: 0, expectedRevision: oldRevision)
precondition(store.loadRows(current)[0].status == .unknown)
let newRevision = store.revision(0)
store.saveStatus(MonitorEntry(handle: "alice", status: .offline, checkedAt: Date()), slot: 0, expectedRevision: newRevision)
precondition(store.loadRows(current)[0].status == .offline)
print("MonitorStore: stale background results rejected")
precondition(nextMonitorSource(index: 0, count: 3, manual: false) == 1)
precondition(nextMonitorSource(index: 2, count: 3, manual: false) == nil)
precondition(nextMonitorSource(index: 2, count: 3, manual: true) == 0)
precondition(nextMonitorSource(index: 0, count: 0, manual: true) == nil)
print("Monitor source failover passed")
