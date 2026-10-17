import SwiftUI
import AVFoundation
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
    @AppStorage("tlc-icon-style") private var iconStyle = "plastisch"
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
                if let url = state.vlcReplacementURL {
                    VlcVideoSurface(url: url, enabled: state.limiterEnabled, strength: state.limiterStrength) { active, input, output, reduction, error in
                        state.reportNativeLimiter(url: url, active: active, input: input, output: output, reduction: reduction, error: error)
                    }
                }
            }.frame(height: 230).clipped()
            Picker("Bereich", selection: $state.selectedTab) { ForEach(CompanionTab.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented).padding([.horizontal, .top])
            ScrollView { tabContent.padding() }
        }.tint(Design.accent).background(Color(uiColor: .systemBackground))
            .environment(\.companionIconStyle, iconStyle)
            .toggleStyle(CompanionIconToggleStyle())
            .sheet(isPresented: $settingsOpen) { speechSettingsView.environment(\.companionIconStyle, iconStyle).toggleStyle(CompanionIconToggleStyle()) }
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
            Text("Songs").font(.headline)
            Button(action: state.recognize) { VStack { Image(systemName: "magnifyingglass").font(.system(size: 34, weight: .medium)); Text("Jetzt erkennen").font(.callout.bold()) }.frame(width: 116, height: 116).foregroundStyle(.white).background(Design.accent).clipShape(Circle()) }.buttonStyle(.plain).frame(maxWidth: .infinity).accessibilityHint("Startet eine einmalige Erkennung von höchstens zwölf Sekunden")
            Picker("Audioquelle", selection: $state.recognitionSource) { ForEach(RecognitionSource.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
            Label(state.recognitionStatus, systemImage: "circle.fill").font(.footnote).foregroundStyle(.secondary).symbolRenderingMode(.palette).foregroundStyle(.green, .green)
            if let result = state.recognitionResult, result.matched {
                VStack(alignment: .leading, spacing: 5) { Text(result.title).font(.headline); Text(result.artist).foregroundStyle(.secondary); if let url = result.safeSongURL { Link("Song öffnen", destination: url).font(.callout.bold()).padding(.top, 6) } }.frame(maxWidth: .infinity, alignment: .leading).padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var capabilityRows: some View { VStack(spacing: 0) { capability("Connection", state.hookAvailable); Divider(); capability("Titel", state.captionsAvailable); Divider(); capability("Verbindung", state.connected) }.padding(.horizontal).background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 12)) }
    private func capability(_ label: String, _ available: Bool) -> some View { HStack { Text(label); Spacer(); Circle().fill(available ? Color.green : Color.red).frame(width: 10, height: 10) }.frame(minHeight: 46) }
    private var chatView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chat").font(.headline)
            Toggle("Vorlesen", isOn: Binding(get: { state.speechEnabled }, set: { state.setSpeechEnabled($0) })).toggleStyle(CompanionIconToggleStyle(hint: "Vorlesen"))
            Button { settingsOpen = true } label: { CompanionIconLabel(label: "Erweiterte Einstellungen", component: "settings") }.buttonStyle(.bordered)
            ForEach(Array(state.speechChatEntries.suffix(5).enumerated()), id: \.offset) { _, entry in HStack { Text(entry.author.isEmpty ? entry.content : "\(entry.author): \(entry.content)"); Spacer(); Button { state.speak(entry.content, author: entry.author) } label: { Image(systemName: "speaker.wave.2") }; if !entry.author.isEmpty { Button { state.muteAuthor(entry.author) } label: { Image(systemName: "speaker.slash") }.accessibilityLabel("Autor dauerhaft stummschalten") } }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }
            Text("Chatzeilen \(state.chatLines.count)")
            if state.chatLines.isEmpty { Text("Noch keine öffentlichen Chatzeilen empfangen.").foregroundStyle(.secondary) }
            HStack { Text("Top-Chatter").font(.subheadline.bold()); Spacer(); Button("Zurücksetzen", action: state.resetTopChatters).disabled(state.participants.isEmpty) }
            ForEach(Array(state.topChatters.prefix(20))) { chatter in HStack { Text(chatter.author); Spacer(); Text("\(chatter.messages) N · \(chatter.words) W").monospacedDigit(); Button { state.muteAuthor(chatter.author) } label: { Image(systemName: "speaker.slash") } }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }
        }
    }
    private var speechSettingsView: some View {
        NavigationView { Form {
            Picker("Icon-Stil", selection: $iconStyle) { Text("3D / Plastisch").tag("plastisch"); Text("Glass / Realistisch").tag("glass"); Text("Minimal / Linear").tag("linear") }
            SecureField("AudD API-Token", text: $state.auddToken)
            SecureField("Pairing-Code", text: $state.pairingCode)
            SecureField("Universal API-Key", text: $state.universalCaptionApiKey)
            TextField("Alternative Companion-Adresse (lokal zuerst)", text: $state.serviceURL).textInputAutocapitalization(.never).autocorrectionDisabled()
            Picker("Sprache", selection: $state.speechLanguage) { ForEach(["Auto", "Deutsch", "Englisch", "Russisch", "Ukrainisch", "Bulgarisch", "Serbisch", "Kasachisch", "Chinesisch", "Japanisch", "Koreanisch", "Arabisch", "Persisch", "Urdu", "Hindi", "Nepali", "Malayalam"], id: \.self) { Text($0) } }
            TextField("Stimme", text: $state.speechVoice)
            Button("Sherpa-Stimmen laden", action: state.loadServiceVoices)
            Text(state.serviceStatus)
            Button("Systemstandard") { state.speechVoice = "Systemstandard" }
            ForEach(AVSpeechSynthesisVoice.speechVoices(), id: \.identifier) { voice in
                Button("\(voice.name) · \(voice.language)") { state.speechVoice = voice.identifier }
            }
            ForEach(state.serviceVoiceGroups, id: \.self) { group in
                Text(group).font(.headline)
                ForEach(state.serviceVoices.filter { $0.displayGroup == group }) { voice in
                VStack(alignment: .leading) {
                    Button("\(voice.name) · \(voice.culture)") { state.speechVoice = voice.id }
                    Text("\(voice.bytes / 1048576) MiB · \(voice.license)").font(.caption)
                    if !voice.installed { Button("Installieren") { state.installServiceVoice(voice.id) } }
                }
                }
            }
            Toggle("Chatnamen sprechen", isOn: $state.speakNames).toggleStyle(CompanionIconToggleStyle(hint: "Chatnamen sprechen"))
            Toggle("Chatnamen kürzen", isOn: $state.shortenNames).toggleStyle(CompanionIconToggleStyle(hint: "Chatnamen kürzen"))
            HStack {
                Toggle("Trigger filtern (ext. Sprachdienste)", isOn: $state.filterExternalSpeechTriggers).toggleStyle(CompanionIconToggleStyle(hint: "Trigger filtern (ext. Sprachdienste)"))
                TextField(".", text: $state.externalSpeechTriggerCharacters).frame(width: 54)
                    .textFieldStyle(.roundedBorder).autocorrectionDisabled().textInputAutocapitalization(.never)
                    .accessibilityLabel("Triggerzeichen, maximal fünf Sonderzeichen")
            }
            Toggle("Auto-Chat Refresh", isOn: $state.autoChatRefreshEnabled).toggleStyle(CompanionIconToggleStyle(hint: "Auto-Chat Refresh"))
            HStack { Text("Auto-Chat Refresh"); TextField("Minuten", value: $state.autoChatRefreshMinutes, format: .number).keyboardType(.numberPad).frame(width: 54); Text("min.") }
            Toggle("Game-Mode (Spam-, Emoji, usw. Chatfilter)", isOn: $state.gameModeEnabled).toggleStyle(CompanionIconToggleStyle(hint: "Game-Mode (Spam-, Emoji, usw. Chatfilter)"))
        }.navigationTitle("Erweiterte Einstellungen").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Schließen") { settingsOpen = false } } } }
        .navigationViewStyle(.stack)
    }
    private var statusView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LIVE-Information").font(.headline); capabilityRows
            ForEach(state.liveValues.keys.sorted(), id: \.self) { key in HStack { Text(key); Spacer(); Text(state.liveValues[key] ?? "–").monospacedDigit() }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }
            Text("Personen stummschalten").font(.subheadline.bold())
            ForEach(Array(state.topChatters.prefix(20))) { chatter in HStack { Text(chatter.author); Spacer(); Text("\(chatter.messages) N"); Button { state.muteAuthor(chatter.author) } label: { Image(systemName: "speaker.slash") } }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }
            Text("PROFIL-Information").font(.headline)
            Button { state.sendCommand?("inspect", [:]) } label: { CompanionIconLabel(label: "Refresh", component: "reset") }.buttonStyle(.bordered)
            ForEach(state.pageInformation.keys.sorted(), id: \.self) { key in HStack { Text(key); Spacer(); Text(state.pageInformation[key] ?? "–").monospacedDigit() }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }
            Text("LIVE-Empfehlungen").font(.headline)
            Stepper(value: $state.recommendationLimit, in: 1...300) { HStack { Text("Anzahl"); Text("\(state.recommendationLimit)") } }
            if state.recommendationStatus == "running" { Button("Abbrechen", action: state.cancelRecommendationScan).buttonStyle(.bordered) } else { Button("Empfehlungen scannen", action: state.startRecommendationScan).buttonStyle(.borderedProminent) }
            Text("\(state.recommendationScanned) geprüft · \(state.recommendationItems.count) gefunden").font(.footnote).foregroundStyle(.secondary)
            ForEach(state.recommendationItems) { item in VStack(alignment: .leading) { Text("@\(item.handle)").bold(); Text(item.displayName); Text(item.viewerLabel.isEmpty ? item.viewerCount.map(String.init) ?? "–" : item.viewerLabel); if !item.title.isEmpty { Text(item.title).font(.footnote) }; Link("Stream öffnen", destination: item.url) }.padding().background(Design.surface).clipShape(RoundedRectangle(cornerRadius: 10)) }
        }
    }
    private var playerView: some View { VStack(alignment: .leading, spacing: 12) { Text("Player").font(.headline); HStack { commandButton("Play", "play", "play.fill"); commandButton("Stop", "pause", "pause.fill"); commandButton("Mute", "mute", "speaker.slash.fill") }; HStack { commandButton("Unmute", "unmute", "speaker.wave.2.fill"); commandButton("Vollbild", "fullscreen", "arrow.up.left.and.arrow.down.right"); commandButton("PiP", "picture-in-picture", "pip") }; commandButton("Neu laden", "reload-player", "arrow.clockwise"); Button(action: state.toggleVlcReplacement) { CompanionIconLabel(label: "Player", component: "player") }.buttonStyle(.bordered).frame(maxWidth: .infinity).disabled(state.mediaLinks.isEmpty); Button("VLC Player", action: openExternalVlc).buttonStyle(.bordered).frame(maxWidth: .infinity).disabled(state.mediaLinks.isEmpty); Text(state.vlcReplacementURL != nil ? state.nativeLimiterStatus : (state.limiterEnabled ? state.webLimiterStatus : "WebView · Pegelschutz aus")).font(.caption); Toggle("Pegelschutz", isOn: Binding(get: { state.limiterEnabled }, set: { state.setLimiter(enabled: $0) })).toggleStyle(CompanionIconToggleStyle(hideLabel: true, hint: "Pegelschutz")); HStack { Text("Schutzstärke"); Slider(value: Binding(get: { Double(state.limiterStrength) }, set: { state.setLimiter(strength: Int($0)) }), in: 0...100); Text("\(state.limiterStrength)%").monospacedDigit() }; Text("HAR-Logs").font(.headline); ForEach(state.mediaLinks) { link in Link("\(link.label) · \(link.type)", destination: link.url).buttonStyle(.bordered) } } }
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
    private func commandButton(_ label: String, _ command: String, _ icon: String) -> some View { Button { state.sendCommand?(command, [:]) } label: { CompanionIconLabel(label: label, component: ["pause":"stop", "picture-in-picture":"pip", "reload-player":"reset"][command] ?? command).frame(maxWidth: .infinity, minHeight: 44) }.buttonStyle(.bordered) }
    @State private var connectionSettingsOpen = false
    private var connectionSettingsView: some View {
        NavigationView { Form {
            HStack { Toggle("Player-Recovery", isOn: $state.autoReconnectEnabled).toggleStyle(CompanionIconToggleStyle(hint: "Player-Recovery")); TextField("Sek.", value: $state.autoReconnectDelaySeconds, format: .number).keyboardType(.numberPad).frame(width: 54); Text("Sek.") }
            HStack { Toggle("Hook-Reconnect", isOn: $state.hookReconnectEnabled).toggleStyle(CompanionIconToggleStyle(hint: "Hook-Reconnect")); TextField("Sek.", value: $state.hookReconnectDelaySeconds, format: .number).keyboardType(.numberPad).frame(width: 54); Text("Sek.") }
        }.navigationTitle("Connection-Einstellungen").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Schließen") { connectionSettingsOpen = false } } } }.navigationViewStyle(.stack)
    }
    private var moreView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mehr").font(.headline)
            Text("Player-Recovery: \(state.autoReconnectEnabled ? state.playerRecovery["phase"] as? String ?? "aktiv" : "aus")").font(.footnote)
            Text("Hook-Reconnect: \(state.hookReconnectEnabled ? (state.hookRecovery["phase"] as? String).map { $0 == "native" ? "aktiv" : $0 } ?? "aktiv" : "aus")").font(.footnote)
            Text("Connection").font(.headline)
            HStack {
                Toggle("Connection", isOn: Binding(get: { state.connectionEnabled }, set: { state.setConnectionEnabled($0) })).toggleStyle(CompanionIconToggleStyle(hideLabel: true, hint: "Connection"))
                Button(action: state.openNormal) { CompanionIconLabel(label: "Browser", component: "browser").frame(minHeight: 44) }
                Button(action: state.toggleVlcReplacement) { CompanionIconLabel(label: "Player", component: "player") }.disabled(state.mediaLinks.isEmpty)
                Button { connectionSettingsOpen = true } label: { CompanionIconLabel(label: "Connection-Einstellungen", component: "settings").frame(width: 44, height: 44) }.accessibilityLabel("Connection-Einstellungen")
            }.sheet(isPresented: $connectionSettingsOpen) { connectionSettingsView.environment(\.companionIconStyle, iconStyle).toggleStyle(CompanionIconToggleStyle()) }
            Button("Embed", action: state.openEmbed)
            Text("Embed: \(state.embedPhase) · Versuch \(state.embedAttempt)/3").font(.footnote)
            Toggle("Debugmodus", isOn: $state.debugEnabled).toggleStyle(CompanionIconToggleStyle(hint: "Debugmodus"))
            Text("\(state.debugEvents.count) bereinigte Diagnoseereignisse").font(.footnote).foregroundStyle(.secondary)
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
            Text("LIVE-Logs").font(.headline)
            Text("\(state.captionRecords.count) RAW-Untertitelereignisse").font(.footnote).foregroundStyle(.secondary)
            HStack {
                Button("JSON-L-Export") { captionExportDocument = CaptionExportDocument(content: state.captionJSONLines()); captionExportName = "tiktok-live-captions.jsonl"; captionExportOpen = true }.disabled(state.captionRecords.isEmpty)
                Button("RAW-JSON-Export") { captionExportDocument = CaptionExportDocument(content: state.captionRawJSON()); captionExportName = "tiktok-live-caption-raw.json"; captionExportOpen = true }.disabled(state.captionRecords.isEmpty)
            }
            Button("Caption-Protokoll leeren", action: state.clearCaptions).disabled(state.captionRecords.isEmpty)
            Button { state.sendCommand?("inspect", [:]) } label: { CompanionIconLabel(label: "Status", component: "status") }.buttonStyle(.borderedProminent)
            Button { state.sendCommand?("captions", [:]) } label: { CompanionIconLabel(label: "Untertitel", component: "captions") }.buttonStyle(.bordered)
            Button { state.sendCommand?("refresh", [:]) } label: { CompanionIconLabel(label: "Reset", component: "reset") }.buttonStyle(.bordered)
            Button("Force") { state.sendCommand?("force-profile", [:]) }.buttonStyle(.bordered)
            Button { state.sendCommand?("open-report", [:]) } label: { CompanionIconLabel(label: "Meldung", component: "report") }.buttonStyle(.bordered)
            Text("Reset leert App- und WebView-Cache, behält Cookies bei und startet den Stream erneut.").font(.footnote).foregroundStyle(.secondary)
            Text("Nicht verfügbare WebView-Funktionen werden als Status angezeigt. Eine Meldung wird nie automatisch ausgefüllt oder abgesendet.").font(.footnote).foregroundStyle(.secondary)
        }
    }
}
