import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CaptionExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .plainText] }
    let content: String
    init(content: String = "") { self.content = content }
    init(configuration: ReadConfiguration) throws { content = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) ?? "" }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: Data(content.utf8)) }
}

private enum Design {
    static let accent = Color(red: 1.0, green: 0.11, blue: 0.31)
    static let surface = Color(uiColor: .secondarySystemBackground)
}

func mobileVideoHeight(totalHeight: Int, landscape: Bool) -> Int {
    landscape ? min(totalHeight / 3, 104) : totalHeight / 2
}

struct ContentView: View {
    @StateObject var state: CompanionState
    @State private var settingsOpen = false
    @State private var captionExportOpen = false
    @State private var captionExportDocument = CaptionExportDocument()
    @State private var captionExportName = "tiktok-live-captions.jsonl"

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
            ZStack {
                CompanionWebView(state: state).opacity(state.vlcReplacementURL == nil ? 1 : 0)
                if let url = state.vlcReplacementURL { VlcVideoSurface(url: url) }
            }.frame(height: 230).clipped()
            Picker("Bereich", selection: $state.selectedTab) { ForEach(CompanionTab.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented).padding([.horizontal, .top])
            ScrollView { tabContent.padding() }
        }.tint(Design.accent).background(Color(uiColor: .systemBackground))
            .sheet(isPresented: $settingsOpen) { speechSettingsView }
            .fileExporter(isPresented: $captionExportOpen, document: captionExportDocument, contentType: captionExportName.hasSuffix(".jsonl") ? .plainText : .json, defaultFilename: captionExportName) { _ in }
            .alert("Hinweis", isPresented: Binding(get: { state.lastError != nil }, set: { if !$0 { state.lastError = nil } })) { Button("OK") {} } message: { Text(state.lastError ?? "") }
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
            Toggle("Neue Nachrichten automatisch vorlesen", isOn: $state.keepSpeechActive)
            Button { settingsOpen = true } label: { Label("Sprach- und Chat-Einstellungen", systemImage: "gearshape") }.buttonStyle(.bordered)
            ForEach(Array(state.chatLines.suffix(5).enumerated()), id: \.offset) { _, line in HStack { Text(line); Spacer(); Button { state.speak(line) } label: { Image(systemName: "speaker.wave.2") }; if let author = line.split(separator: ":", maxSplits: 1).first { Button { state.muteAuthor(String(author)) } label: { Image(systemName: "speaker.slash") }.accessibilityLabel("Autor dauerhaft stummschalten") } }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }
            if state.chatLines.isEmpty { Text("Noch keine öffentlichen Chatzeilen empfangen.").foregroundStyle(.secondary) }
            HStack { Text("Top-Chatter").font(.subheadline.bold()); Spacer(); Button("Zurücksetzen", action: state.resetTopChatters).disabled(state.participants.isEmpty) }
            ForEach(Array(state.topChatters.prefix(20))) { chatter in HStack { Text(chatter.author); Spacer(); Text("\(chatter.messages) N · \(chatter.words) W").monospacedDigit(); Button { state.muteAuthor(chatter.author) } label: { Image(systemName: "speaker.slash") } }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }
        }
    }
    private var speechSettingsView: some View {
        NavigationStack { Form {
            SecureField("AudD API-Token", text: $state.auddToken)
            SecureField("Pairing-Code", text: $state.pairingCode)
            SecureField("Universal API-Key für Untertitel", text: $state.universalCaptionApiKey)
            Picker("Sprache", selection: $state.speechLanguage) { ForEach(["Auto", "Deutsch", "Englisch", "Russisch", "Ukrainisch", "Bulgarisch", "Serbisch", "Kasachisch", "Chinesisch", "Japanisch", "Koreanisch", "Arabisch", "Persisch", "Urdu", "Hindi", "Nepali", "Malayalam"], id: \.self) { Text($0) } }
            TextField("Stimme", text: $state.speechVoice)
            Toggle("Chatnamen sprechen", isOn: $state.speakNames)
            Toggle("Chatnamen kürzen", isOn: $state.shortenNames)
            Toggle("Game-Mode", isOn: $state.gameModeEnabled)
        }.navigationTitle("Sprach- und Chat-Einstellungen").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Schließen") { settingsOpen = false } } } }
    }
    private var statusView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LIVE-Informationen").font(.headline); capabilityRows
            ForEach(state.liveValues.keys.sorted(), id: \.self) { key in HStack { Text(key); Spacer(); Text(state.liveValues[key] ?? "–").monospacedDigit() }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }
            Text("Personen stummschalten").font(.subheadline.bold())
            ForEach(Array(state.topChatters.prefix(20))) { chatter in HStack { Text(chatter.author); Spacer(); Text("\(chatter.messages) N"); Button { state.muteAuthor(chatter.author) } label: { Image(systemName: "speaker.slash") } }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }
            Text("Seiteninformationen").font(.headline)
            Button("Seite prüfen") { state.sendCommand?("inspect", [:]) }.buttonStyle(.bordered)
            ForEach(state.pageInformation.keys.sorted(), id: \.self) { key in HStack { Text(key); Spacer(); Text(state.pageInformation[key] ?? "–").monospacedDigit() }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }
            Text("LIVE-Empfehlungen").font(.headline)
            Stepper("Anzahl: \(state.recommendationLimit)", value: $state.recommendationLimit, in: 1...50)
            if state.recommendationStatus == "running" { Button("Abbrechen", action: state.cancelRecommendationScan).buttonStyle(.bordered) } else { Button("Empfehlungen scannen", action: state.startRecommendationScan).buttonStyle(.borderedProminent) }
            Text("\(state.recommendationScanned) geprüft · \(state.recommendationItems.count) gefunden").font(.footnote).foregroundStyle(.secondary)
            ForEach(state.recommendationItems) { item in VStack(alignment: .leading) { Text("@\(item.handle)").bold(); Text(item.displayName); Text(item.viewerLabel.isEmpty ? item.viewerCount.map(String.init) ?? "–" : item.viewerLabel); if !item.title.isEmpty { Text(item.title).font(.footnote) }; Link("Stream öffnen", destination: item.url) }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }
        }
    }
    private var playerView: some View { VStack(alignment: .leading, spacing: 12) { Text("Player").font(.headline); HStack { commandButton("Play", "play", "play.fill"); commandButton("Pause", "pause", "pause.fill"); commandButton("Stumm", "mute", "speaker.slash.fill") }; HStack { commandButton("Ton an", "unmute", "speaker.wave.2.fill"); commandButton("Vollbild", "fullscreen", "arrow.up.left.and.arrow.down.right"); commandButton("PiP", "picture-in-picture", "pip") }; commandButton("Neu laden", "reload-player", "arrow.clockwise"); Button("VLC Ersatz", action: state.toggleVlcReplacement).buttonStyle(.bordered).frame(maxWidth: .infinity).disabled(state.mediaLinks.isEmpty); Button("VLC Player", action: openExternalVlc).buttonStyle(.bordered).frame(maxWidth: .infinity).disabled(state.mediaLinks.isEmpty); Toggle("Pegelschutz", isOn: Binding(get: { state.limiterEnabled }, set: { state.setLimiter(enabled: $0) })); HStack { Text("Schutzstärke"); Slider(value: Binding(get: { Double(state.limiterStrength) }, set: { state.setLimiter(strength: Int($0)) }), in: 0...100); Text("\(state.limiterStrength)%").monospacedDigit() }; ForEach(state.mediaLinks) { link in Link("\(link.label) · \(link.type)", destination: link.url).buttonStyle(.bordered) } } }
    private func openExternalVlc() {
        guard let mediaURL = state.bestVlcMediaURL() else { return }
        var components = URLComponents(string: "vlc-x-callback://x-callback-url/stream")
        components?.queryItems = [URLQueryItem(name: "url", value: mediaURL.absoluteString)]
        if let vlcURL = components?.url, UIApplication.shared.canOpenURL(vlcURL) {
            UIApplication.shared.open(vlcURL)
        } else if let storeURL = URL(string: "itms-apps://itunes.apple.com/app/id650377962") {
            UIApplication.shared.open(storeURL)
        }
    }
    private func commandButton(_ label: String, _ command: String, _ icon: String) -> some View { Button { state.sendCommand?(command, [:]) } label: { Label(label, systemImage: icon).frame(maxWidth: .infinity, minHeight: 44) }.buttonStyle(.bordered) }
    private var moreView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mehr").font(.headline)
            HStack { Toggle("Auto-Reconnect", isOn: $state.autoReconnectEnabled); TextField("Sek.", value: $state.autoReconnectDelaySeconds, format: .number).keyboardType(.numberPad).frame(width: 54); Text("Sek.") }
            Toggle("Debugmodus", isOn: $state.debugEnabled)
            Text("\(state.debugEvents.count) vollständige Rohereignisse").font(.footnote).foregroundStyle(.secondary)
            ForEach(Array(state.debugEvents.enumerated()), id: \.offset) { _, event in
                Text(String(data: (try? JSONSerialization.data(withJSONObject: event, options: [.sortedKeys])) ?? Data(), encoding: .utf8) ?? "{}")
                    .font(.caption2.monospaced())
            }
            HStack {
                Button("Debug kopieren") {
                    let installed = UIApplication.shared.canOpenURL(URL(string: "vlc-x-callback://x-callback-url/stream")!)
                    UIPasteboard.general.string = state.debugReport(vlcInstalled: installed)
                }.disabled(state.debugEvents.isEmpty)
                Button("Leeren", action: state.clearDebugEvents).disabled(state.debugEvents.isEmpty)
            }
            Text("Caption-Protokoll").font(.headline)
            Text("\(state.captionRecords.count) RAW-Untertitelereignisse").font(.footnote).foregroundStyle(.secondary)
            HStack {
                Button("JSON-L-Export") { captionExportDocument = CaptionExportDocument(content: state.captionJSONLines()); captionExportName = "tiktok-live-captions.jsonl"; captionExportOpen = true }.disabled(state.captionRecords.isEmpty)
                Button("RAW-JSON-Export") { captionExportDocument = CaptionExportDocument(content: state.captionRawJSON()); captionExportName = "tiktok-live-caption-raw.json"; captionExportOpen = true }.disabled(state.captionRecords.isEmpty)
            }
            Button("Caption-Protokoll leeren", action: state.clearCaptions).disabled(state.captionRecords.isEmpty)
            Button("Seite prüfen") { state.sendCommand?("inspect", [:]) }.buttonStyle(.borderedProminent)
            Button("Untertitel aktivieren") { state.sendCommand?("captions", [:]) }.buttonStyle(.bordered)
            Button("Refresh") { state.sendCommand?("refresh", [:]) }.buttonStyle(.bordered)
            Button("Force") { state.sendCommand?("force-profile", [:]) }.buttonStyle(.bordered)
            Button("Melden öffnen") { state.sendCommand?("open-report", [:]) }.buttonStyle(.bordered)
            Text("Refresh leert App- und WebView-Cache, behält Cookies bei und startet den Stream erneut.").font(.footnote).foregroundStyle(.secondary)
            Text("Nicht verfügbare WebView-Funktionen werden als Status angezeigt. Eine Meldung wird nie automatisch ausgefüllt oder abgesendet.").font(.footnote).foregroundStyle(.secondary)
        }
    }
}
