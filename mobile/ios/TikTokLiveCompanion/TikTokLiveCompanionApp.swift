import SwiftUI

@main struct TikTokLiveCompanionApp: App {
    init() {
        MonitorBackground.register()
        MonitorBackground.schedule(MonitorStore(defaults: .standard).load())
    }
    var body: some Scene { WindowGroup { ContentView() } }
}
