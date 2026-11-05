import Foundation
import Combine

@MainActor
final class StatusMonitorModel: ObservableObject {
    @Published private(set) var config: MonitorConfiguration
    @Published private(set) var rows: [MonitorEntry]
    private let store: MonitorStore
    private let probe = MonitorProbe()
    private var revisions = Array(repeating: 0, count: MonitorConfiguration.slotCount)
    private var pending: Set<Int> = []
    private var playing: Set<Int> = []
    private var activeChecks = 0
    private var checkingAll = false

    init(defaults: UserDefaults = .standard) {
        let store = MonitorStore(defaults: defaults)
        self.store = store
        let initial = store.load()
        self.config = initial
        self.rows = store.loadRows(initial)
    }
    func update(_ next: MonitorConfiguration) throws {
        try store.save(next)
        for i in 0..<MonitorConfiguration.slotCount where next.handles[i] != config.handles[i] {
            revisions[i] += 1
            rows[i] = MonitorEntry(handle: next.handles[i])
        }
        config = next
        MonitorBackground.schedule(next)
    }
    func check(_ index: Int, force: Bool = true) async {
        guard rows.indices.contains(index), !pending.contains(index) else { return }
        let handle = config.handles[index], revision = revisions[index], storedRevision = store.revision(index)
        guard !handle.isEmpty else { return }
        if !force && !rows[index].sources.isEmpty && (playing.contains(index) || (config.skipOnline && rows[index].status == .online)) { return }
        pending.insert(index)
        defer { pending.remove(index) }
        while activeChecks >= 3 {
            do { try await Task.sleep(nanoseconds: 100_000_000) } catch { return }
        }
        guard !Task.isCancelled, revisions[index] == revision, config.handles[index] == handle else { return }
        activeChecks += 1
        defer { activeChecks -= 1 }
        rows[index].status = .checking
        let result = await probe.check(handle: handle, maxLinks: config.maxLinks)
        guard !Task.isCancelled, revisions[index] == revision, config.handles[index] == handle else { return }
        var applied = result
        if result.status == .error { applied.sources = rows[index].sources.filter { MonitorProbe.usable($0) } }
        rows[index] = applied
        store.saveStatus(result, slot: index, expectedRevision: storedRevision)
    }
    func checkAll(force: Bool = true) async {
        guard !checkingAll else { return }
        checkingAll = true
        defer { checkingAll = false }
        for index in 0..<MonitorConfiguration.slotCount {
            if Task.isCancelled { return }
            await check(index, force: force)
        }
    }
    func setPlaying(_ index: Int, _ value: Bool) { if value { playing.insert(index) } else { playing.remove(index) } }
    func reloadBackgroundStatuses() {
        let stored = store.loadRows(config)
        for index in rows.indices where (stored[index].checkedAt ?? .distantPast) > (rows[index].checkedAt ?? .distantPast) {
            rows[index].status = stored[index].status
            rows[index].checkedAt = stored[index].checkedAt
        }
    }
}
