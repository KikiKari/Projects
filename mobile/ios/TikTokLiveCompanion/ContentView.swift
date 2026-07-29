import SwiftUI

private enum Design {
    static let accent = Color(red: 1.0, green: 0.11, blue: 0.31)
    static let surface = Color(uiColor: .secondarySystemBackground)
}

func mobileVideoHeight(totalHeight: Int, landscape: Bool) -> Int {
    landscape ? min(totalHeight / 3, 104) : totalHeight / 2
}

struct ContentView: View {
    @StateObject var state: CompanionState

    @MainActor
    init() {
        _state = StateObject(wrappedValue: CompanionState())
    }

    @MainActor
    init(state: CompanionState) {
        _state = StateObject(wrappedValue: state)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack { Image(systemName: "waveform").foregroundStyle(.white).padding(8).background(Design.accent).clipShape(RoundedRectangle(cornerRadius: 8)); Text("TikTok LIVE Companion").font(.headline); Spacer(); Circle().fill(Design.accent).frame(width: 8); Text("LIVE").font(.caption.bold()) }.padding()
            CompanionWebView(state: state).frame(height: 230).clipped()
            Picker("Bereich", selection: $state.selectedTab) { ForEach(CompanionTab.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented).padding([.horizontal, .top])
            ScrollView { tabContent.padding() }
        }.tint(Design.accent).background(Color(uiColor: .systemBackground)).alert("Hinweis", isPresented: Binding(get: { state.lastError != nil }, set: { if !$0 { state.lastError = nil } })) { Button("OK") {} } message: { Text(state.lastError ?? "") }
    }

    @ViewBuilder private var tabContent: some View {
        switch state.selectedTab {
        case .song: songView
        case .chat: chatView
        case .live: statusView
        case .player: playerView
        case .more: moreView
        }
    }

    private var songView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Songerkennung").font(.headline)
            Button(action: state.recognize) { VStack { Image(systemName: "magnifyingglass").font(.system(size: 34, weight: .medium)); Text("Jetzt erkennen").font(.callout.bold()) }.frame(width: 116, height: 116).foregroundStyle(.white).background(Design.accent).clipShape(Circle()) }.buttonStyle(.plain).frame(maxWidth: .infinity).accessibilityHint("Startet eine einmalige Erkennung von höchstens zwölf Sekunden")
            Picker("Audioquelle", selection: $state.recognitionSource) { ForEach(RecognitionSource.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
            Label(state.recognitionStatus, systemImage: "circle.fill").font(.footnote).foregroundStyle(.secondary).symbolRenderingMode(.palette).foregroundStyle(.green, .green)
            if let result = state.recognitionResult, result.matched {
                VStack(alignment: .leading, spacing: 5) { Text(result.title).font(.headline); Text(result.artist).foregroundStyle(.secondary); if let url = result.safeSongURL { Link("Song öffnen", destination: url).font(.callout.bold()).padding(.top, 6) } }.frame(maxWidth: .infinity, alignment: .leading).padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var capabilityRows: some View { VStack(spacing: 0) { capability("WebSocket-Hook", state.hookAvailable); Divider(); capability("Untertitel", state.captionsAvailable); Divider(); capability("Verbindung", state.connected) }.padding(.horizontal).background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 12)) }
    private func capability(_ label: String, _ available: Bool) -> some View { HStack { Text(label); Spacer(); Circle().fill(available ? Color.green : Color.red).frame(width: 10, height: 10) }.frame(minHeight: 46) }
    private var chatView: some View { VStack(alignment: .leading, spacing: 10) { Text("Chat").font(.headline); Text("Top-Chatter").font(.subheadline.bold()); Toggle("Game-Mode", isOn: $state.gameModeEnabled); Toggle("Chatnamen kürzen", isOn: $state.shortenNames); Toggle("Permanent aktiv", isOn: $state.keepSpeechActive); ForEach(Array(state.chatLines.suffix(5).enumerated()), id: \.offset) { _, line in HStack { Text(line); Spacer(); Button { state.speak(line) } label: { Image(systemName: "speaker.wave.2") }; if let author = line.split(separator: ":", maxSplits: 1).first { Button { state.muteAuthor(String(author)) } label: { Image(systemName: "speaker.slash") }.accessibilityLabel("Autor dauerhaft stummschalten") } }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }; if state.chatLines.isEmpty { Text("Noch keine öffentlichen Chatzeilen empfangen.").foregroundStyle(.secondary) } } }
    private var statusView: some View { VStack(alignment: .leading, spacing: 12) { Text("LIVE-Informationen").font(.headline); capabilityRows; Text("Personen stummschalten").font(.subheadline.bold()); ForEach(state.liveValues.keys.sorted(), id: \.self) { key in HStack { Text(key); Spacer(); Text(state.liveValues[key] ?? "–").monospacedDigit() }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) } } }
    private var playerView: some View { VStack(alignment: .leading, spacing: 12) { Text("Player").font(.headline); HStack { commandButton("Play", "play", "play.fill"); commandButton("Pause", "pause", "pause.fill"); commandButton("Stumm", "mute", "speaker.slash.fill") }; HStack { commandButton("Ton an", "unmute", "speaker.wave.2.fill"); commandButton("Vollbild", "fullscreen", "arrow.up.left.and.arrow.down.right"); commandButton("PiP", "picture-in-picture", "pip") }; commandButton("Neu laden", "reload-player", "arrow.clockwise"); Toggle("Pegelschutz", isOn: Binding(get: { state.limiterEnabled }, set: { state.setLimiter(enabled: $0) })); HStack { Text("Schutzstärke"); Slider(value: Binding(get: { Double(state.limiterStrength) }, set: { state.setLimiter(strength: Int($0)) }), in: 0...100); Text("\(state.limiterStrength)%").monospacedDigit() }; ForEach(state.mediaLinks) { link in Link("\(link.label) · \(link.type)", destination: link.url).buttonStyle(.bordered) } } }
    private func commandButton(_ label: String, _ command: String, _ icon: String) -> some View { Button { state.sendCommand?(command, [:]) } label: { Label(label, systemImage: icon).frame(maxWidth: .infinity, minHeight: 44) }.buttonStyle(.bordered) }
    private var moreView: some View { VStack(alignment: .leading, spacing: 12) { Text("Mehr").font(.headline); Toggle("Auto-Reconnect", isOn: $state.autoReconnectEnabled); Toggle("Debugmodus", isOn: .constant(false)); Button("Seite prüfen") { state.sendCommand?("inspect", [:]) }.buttonStyle(.borderedProminent); Button("Untertitel aktivieren") { state.sendCommand?("captions", [:]) }.buttonStyle(.bordered); Button("Refresh") { state.sendCommand?("refresh", [:]) }.buttonStyle(.bordered); Button("Force") { state.sendCommand?("force-profile", [:]) }.buttonStyle(.bordered); Button("Melden öffnen") { state.sendCommand?("open-report", [:]) }.buttonStyle(.bordered); Text("Refresh leert App- und WebView-Cache, behält Cookies bei und startet den Stream erneut.").font(.footnote).foregroundStyle(.secondary); Text("Nicht verfügbare WebView-Funktionen werden als Status angezeigt. Eine Meldung wird nie automatisch ausgefüllt oder abgesendet.").font(.footnote).foregroundStyle(.secondary) } }
}
