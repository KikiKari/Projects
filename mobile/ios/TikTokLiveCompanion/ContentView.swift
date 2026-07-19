import SwiftUI

private enum Design {
    static let accent = Color(red: 1.0, green: 0.11, blue: 0.31)
    static let surface = Color(uiColor: .secondarySystemBackground)
}

struct ContentView: View {
    @StateObject var state: CompanionState

    init(state: CompanionState = CompanionState()) { _state = StateObject(wrappedValue: state) }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                if !state.videoExpanded {
                    HStack { Image(systemName: "waveform").foregroundStyle(.white).padding(8).background(Design.accent).clipShape(RoundedRectangle(cornerRadius: 8)); Text("TikTok LIVE Companion").font(.headline); Spacer(); Circle().fill(Design.accent).frame(width: 8); Text("LIVE").font(.caption.bold()) }.padding()
                    streamNameField
                }
                CompanionWebView(state: state)
                    .frame(height: state.videoExpanded ? proxy.size.height : proxy.size.height * 0.5)
                    .clipped()
                if !state.videoExpanded {
                    Picker("Bereich", selection: $state.selectedTab) { ForEach(CompanionTab.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented).padding([.horizontal, .top])
                    ScrollView { tabContent.padding() }
                }
            }
        }.tint(Design.accent).background(Color(uiColor: .systemBackground)).alert("Hinweis", isPresented: Binding(get: { state.lastError != nil }, set: { if !$0 { state.lastError = nil } })) { Button("OK") {} } message: { Text(state.lastError ?? "") }
    }

    private var streamNameField: some View {
        HStack {
            TextField("@creator oder creator", text: $state.streamName)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .onSubmit(state.openStream)
                .accessibilityLabel("Streamname, mit oder ohne At-Zeichen")
            Button(action: state.openStream) { Image(systemName: "play.fill") }
                .buttonStyle(.borderedProminent)
                .disabled(state.streamName.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Stream öffnen")
        }.padding(.horizontal).padding(.bottom, 6)
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
            capabilityRows
        }
    }

    private var capabilityRows: some View { VStack(spacing: 0) { capability("WebSocket-Hook", state.hookAvailable); Divider(); capability("Untertitel", state.captionsAvailable); Divider(); capability("Verbindung", state.connected) }.padding(.horizontal).background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 12)) }
    private func capability(_ label: String, _ available: Bool) -> some View { HStack { Text(label); Spacer(); Circle().fill(available ? Color.green : Color.red).frame(width: 10, height: 10) }.frame(minHeight: 46) }
    private var chatView: some View { VStack(alignment: .leading, spacing: 10) { Text("Chat").font(.headline); ForEach(Array(state.chatLines.suffix(50).enumerated()), id: \.offset) { _, line in HStack { Text(line); Spacer(); Button { state.speak(line) } label: { Image(systemName: "speaker.wave.2") }; if let author = line.split(separator: ":", maxSplits: 1).first { Button { state.muteAuthor(String(author)) } label: { Image(systemName: "speaker.slash") }.accessibilityLabel("Autor dauerhaft stummschalten") } }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }; if state.chatLines.isEmpty { Text("Noch keine öffentlichen Chatzeilen empfangen.").foregroundStyle(.secondary) } } }
    private var statusView: some View { VStack(alignment: .leading, spacing: 12) { Text("LIVE-Informationen").font(.headline); capabilityRows; ForEach(state.liveValues.keys.sorted(), id: \.self) { key in HStack { Text(key); Spacer(); Text(state.liveValues[key] ?? "–").monospacedDigit() }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) } } }
    private var playerView: some View { VStack(alignment: .leading, spacing: 12) { Text("Player").font(.headline); HStack { commandButton("Play", "play", "play.fill"); commandButton("Pause", "pause", "pause.fill"); commandButton("Stumm", "mute", "speaker.slash.fill") }; HStack { commandButton("Vollbild", "fullscreen", "arrow.up.left.and.arrow.down.right"); commandButton("PiP", "picture-in-picture", "pip"); commandButton("Neu laden", "reload-player", "arrow.clockwise") } } }
    private func commandButton(_ label: String, _ command: String, _ icon: String) -> some View { Button { state.sendCommand?(command, [:]) } label: { Label(label, systemImage: icon).frame(maxWidth: .infinity, minHeight: 44) }.buttonStyle(.bordered) }
    private var moreView: some View { VStack(alignment: .leading, spacing: 12) { Text("Mehr").font(.headline); Button("Seite prüfen") { state.sendCommand?("inspect", [:]) }.buttonStyle(.borderedProminent); Button("Untertitel aktivieren") { state.sendCommand?("captions", [:]) }.buttonStyle(.bordered); Button("Refresh") { state.sendCommand?("refresh", [:]) }.buttonStyle(.bordered); Button("Force") { state.sendCommand?("force-profile", [:]) }.buttonStyle(.bordered); Button("Melden öffnen") { state.sendCommand?("open-report", [:]) }.buttonStyle(.bordered); Text("Nicht verfügbare WebView-Funktionen werden als Status angezeigt. Eine Meldung wird nie automatisch ausgefüllt oder abgesendet.").font(.footnote).foregroundStyle(.secondary) } }
}
