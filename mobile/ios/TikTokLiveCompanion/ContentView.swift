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
                // Querformat: Video kleiner halten, damit Inhalt unter dem Menüband sichtbar und scrollbar bleibt (0PE-56).
                let landscape = proxy.size.width > proxy.size.height
                let videoHeight = landscape ? min(proxy.size.height * 0.35, 220) : proxy.size.height * 0.5
                CompanionWebView(state: state)
                    .frame(height: state.videoExpanded ? proxy.size.height : videoHeight)
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
        }
    }

    private var capabilityRows: some View { VStack(spacing: 0) { capability("WebSocket-Hook", state.hookAvailable); Divider(); capability("Untertitel", state.captionsAvailable); Divider(); capability("Verbindung", state.connected) }.padding(.horizontal).background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 12)) }
    private func capability(_ label: String, _ available: Bool) -> some View { HStack { Text(label); Spacer(); Circle().fill(available ? Color.green : Color.red).frame(width: 10, height: 10) }.frame(minHeight: 46) }
    private var chatView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chat").font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Neue Nachrichten automatisch vorlesen", isOn: $state.ttsEnabled)
                Text("Lautstärke \(Int(state.ttsVolume * 100)) %").font(.caption)
                Slider(value: $state.ttsVolume, in: 0 ... 1)
                Picker("Sprache", selection: $state.ttsLanguage) { ForEach(TTSLanguage.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
                Toggle("Chatnamen vorlesen", isOn: $state.ttsSpeakNames)
                Toggle("Lange Namen kürzen", isOn: $state.ttsShortenNames)
            }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 12))
            ForEach(state.chatLines.suffix(50)) { line in HStack { Text(line.visibleText); Spacer(); Button { state.speak(line) } label: { Image(systemName: "speaker.wave.2") }; if !line.author.isEmpty { Button { state.muteAuthor(line.author) } label: { Image(systemName: "speaker.slash") }.accessibilityLabel("Autor dauerhaft stummschalten") } }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }
            if state.chatLines.isEmpty { Text("Noch keine öffentlichen Chatzeilen empfangen.").foregroundStyle(.secondary) }
        }
    }
    private var statusView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LIVE-Informationen").font(.headline)
            capabilityRows
            if state.liveValues.isEmpty { Text("Der WebSocket-Hook liefert die Werte nach dem Laden des Streams.").font(.footnote).foregroundStyle(.secondary) }
            ForEach(state.liveValues.keys.sorted(), id: \.self) { key in HStack { Text(key); Spacer(); Text(state.liveValues[key] ?? "–").monospacedDigit() }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }
            Text("Top-Chatter").font(.headline)
            if state.topChatters.isEmpty { Text("Noch keine Personen im Chat beobachtet.").font(.footnote).foregroundStyle(.secondary) }
            ForEach(state.topChatters, id: \.0) { entry in HStack { Text(entry.0); Spacer(); Text("\(entry.1)").monospacedDigit().bold() }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }
            Text("Seiteninformationen").font(.headline)
            if state.pageInfo.isEmpty { Text("Noch keine Seitenprüfung ausgeführt · \u{201E}Seite prüfen\u{201C} im Tab Mehr.").font(.footnote).foregroundStyle(.secondary) }
            ForEach(state.pageInfo.keys.sorted(), id: \.self) { key in VStack(alignment: .leading, spacing: 3) { Text(key).font(.caption).foregroundStyle(.secondary); Text(state.pageInfo[key] ?? "–").bold() }.frame(maxWidth: .infinity, alignment: .leading).padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }
        }
    }
    private var playerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Player").font(.headline)
            HStack { commandButton("Play", "play", "play.fill"); commandButton("Pause", "pause", "pause.fill"); commandButton("Stumm", "mute", "speaker.slash.fill") }
            HStack {
                // Vollbild nativ: Bridge-„fullscreen" greift im mobilen WebView nicht (0PE-54); PiP ist Nicht-Ziel.
                Button { state.toggleVideoExpanded() } label: { Label("Vollbild", systemImage: "arrow.up.left.and.arrow.down.right").frame(maxWidth: .infinity, minHeight: 44) }.buttonStyle(.bordered)
                commandButton("Neu laden", "reload-player", "arrow.clockwise")
            }
            Text("Pegelschutz").font(.headline)
            Toggle("Digitalen Pegelschutz aktivieren", isOn: $state.limiterEnabled)
            HStack { Text("Grenzwert"); Spacer(); Text("\(state.limiterThreshold) dBFS").bold().monospacedDigit() }
            Slider(value: Binding(get: { Double(state.limiterThreshold) }, set: { state.limiterThreshold = Int($0) }), in: -30 ... -1, step: 1).disabled(!state.limiterEnabled)
            Text("dBFS ist ein digitaler Signalpegel, kein am Ohr messbarer dB-SPL-Wert. Der Schutz komprimiert Spitzen oberhalb des Grenzwerts lokal im WebView.").font(.footnote).foregroundStyle(.secondary)
        }
    }
    private func commandButton(_ label: String, _ command: String, _ icon: String) -> some View { Button { state.sendCommand?(command, [:]) } label: { Label(label, systemImage: icon).frame(maxWidth: .infinity, minHeight: 44) }.buttonStyle(.bordered) }
    private var moreView: some View { VStack(alignment: .leading, spacing: 12) { Text("Mehr").font(.headline); Button("Seite prüfen") { state.sendCommand?("inspect", [:]) }.buttonStyle(.borderedProminent); Button("Untertitel aktivieren") { state.sendCommand?("captions", [:]) }.buttonStyle(.bordered); Button("Refresh") { state.sendCommand?("refresh", [:]) }.buttonStyle(.bordered); Button(state.forceInProgress ? "Force läuft …" : "Force") { state.startForce() }.buttonStyle(.bordered).disabled(state.forceInProgress); if state.forceRecoveryURL != nil { Button("Manuell zum LIVE-Stream zurück") { state.recoverForce() }.buttonStyle(.bordered) }; Button("Melden öffnen") { state.sendCommand?("open-report", [:]) }.buttonStyle(.bordered); Text("Nicht verfügbare WebView-Funktionen werden als Status angezeigt. Eine Meldung wird nie automatisch ausgefüllt oder abgesendet.").font(.footnote).foregroundStyle(.secondary) } }
}
