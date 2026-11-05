import BackgroundTasks
import Foundation

/// iOS decides when (or whether) a requested refresh is executed.
enum MonitorBackground {
    private static let identifier = "app.tiktoklivecompanion.ios.status-refresh"
    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { task.setTaskCompleted(success: false); return }
            let worker = Task {
                let store = MonitorStore(defaults: .standard)
                let config = store.load()
                schedule(config)
                let probe = MonitorProbe()
                if config.enabled {
                    for (slot, handle) in config.handles.enumerated() where !handle.isEmpty {
                        if Task.isCancelled { break }
                        let revision = store.revision(slot)
                        let result = await probe.check(handle: handle, maxLinks: config.maxLinks)
                        if !Task.isCancelled { await MainActor.run { store.saveStatus(result, slot: slot, expectedRevision: revision) } }
                    }
                }
                task.setTaskCompleted(success: !Task.isCancelled)
            }
            task.expirationHandler = { worker.cancel() }
        }
    }
    static func schedule(_ config: MonitorConfiguration) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        guard config.enabled, config.handles.contains(where: { !$0.isEmpty }) else { return }
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: TimeInterval(max(15, config.intervalMinutes) * 60))
        do { try BGTaskScheduler.shared.submit(request) }
        catch { NSLog("Monitor background scheduling failed: %@", String(describing: error)) }
    }
}
