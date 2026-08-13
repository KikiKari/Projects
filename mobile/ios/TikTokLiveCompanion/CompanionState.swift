import AVFoundation
import Foundation

@MainActor final class CompanionState: ObservableObject {
    @Published var selectedTab: CompanionTab = .song
    @Published var recognitionSource: RecognitionSource {
        didSet { defaults.set(recognitionSource.rawValue, forKey: Self.sourceKey) }
    }
    @Published var recognitionStatus = "Bereit für manuelle Erkennung"
    @Published var recognitionResult: RecognitionResult?
    @Published var hookAvailable = false
    @Published var captionsAvailable = false
    @Published var connected = false
    @Published var chatLines: [String] = []
    @Published var liveValues: [String: String] = [:]
    @Published var mediaLinks: [MobileMediaLink] = []
    @Published var vlcReplacementURL: URL?
    @Published var mutedAuthors: Set<String>
    @Published var gameModeEnabled = true
    @Published var shortenNames = true
    @Published var keepSpeechActive = true
    @Published var autoReconnectEnabled = true {
        didSet { sendCommand?("set-auto-reconnect", ["enabled": autoReconnectEnabled]) }
    }
    @Published var limiterEnabled = false
    @Published var limiterStrength = 30
    @Published var lastError: String?
    @Published var debugEnabled = false
    @Published var debugEvents: [[String: Any]] = []
    var sendCommand: ((String, [String: Any]) -> Void)?
    let recognizer: RecognitionService
    private let speaker = AVSpeechSynthesizer()
    private let defaults: UserDefaults
    private var recentSpeech: [String: Date] = [:]
    private let repeatWindow: TimeInterval = 20
    private static let sourceKey = "recognitionSource"
    private static let mutedAuthorsKey = "mutedAuthors"

    init(recognizer: RecognitionService = ShazamRecognitionService(), defaults: UserDefaults = .standard) {
        self.recognizer = recognizer
        self.defaults = defaults
        self.recognitionSource = defaults.string(forKey: Self.sourceKey).flatMap(RecognitionSource.init(rawValue:)) ?? .microphone
        self.mutedAuthors = Set(defaults.stringArray(forKey: Self.mutedAuthorsKey) ?? [])
        recognizer.onResult = { [weak self] result in Task { @MainActor in
            self?.recognitionResult = result
            self?.recognitionStatus = result.matched ? "Song erkannt" : "Kein passender Song erkannt"
        }}
        recognizer.onError = { [weak self] message in Task { @MainActor in
            self?.lastError = message
            self?.recognitionStatus = message
        }}
    }

    func recognize() {
        recognitionResult = nil
        lastError = nil
        recognitionStatus = "Erkennung läuft · maximal 12 Sekunden"
        if recognitionSource == .microphone {
            recognizer.startMicrophone()
        } else {
            recognizer.startPCMStream(source: .webview, sampleRate: 48_000)
            sendCommand?("start-webview-audio", [:])
        }
    }

    func handle(_ envelope: BridgeEnvelope) {
        connected = true
        if debugEnabled { debugEvents.append(envelope.rawObject) }
        switch envelope.type {
        case "capability":
            let feature = envelope.payload["feature"]?.stringValue
            let available = envelope.payload["available"]?.boolValue == true
            if feature == "websocket-hook" { hookAvailable = available }
            if feature == "webview-audio", !available, recognitionSource == .webview {
                recognitionStatus = "WebView-Audio nicht verfügbar · Mikrofon wählen"
                recognizer.cancel()
            }
        case "inspection": captionsAvailable = envelope.payload["captionsControlPresent"]?.boolValue == true
        case "chat":
            let author = envelope.payload["nickname"]?.stringValue ?? ""
            let content = envelope.payload["content"]?.stringValue ?? ""
            guard !mutedAuthors.contains(author) else { return }
            chatLines.append(author.isEmpty ? content : "\(author): \(content)")
            if chatLines.count > 50 { chatLines.removeFirst(chatLines.count - 50) }
        case "live-stats":
            for (key, value) in envelope.payload { if let text = value.stringValue { liveValues[key] = text } else if let number = value.numberValue { liveValues[key] = String(Int(number)) } }
        case "media-links":
            let nextLinks: [MobileMediaLink] = envelope.payload["links"]?.arrayValue?.compactMap { item -> MobileMediaLink? in
                guard let object = item.objectValue,
                      let rawURL = object["url"]?.stringValue,
                      let url = URL(string: rawURL),
                      url.scheme == "https",
                      let type = object["type"]?.stringValue else { return nil }
                return MobileMediaLink(url: url, type: type, label: object["label"]?.stringValue ?? type)
            } ?? []
            mediaLinks = nextLinks
            if vlcReplacementURL != nil { vlcReplacementURL = bestVlcMediaURL(in: nextLinks) }
        case "quick-recover": liveValues["Auto-Reconnect"] = "aktiv"
        case "limiter":
            if let strength = envelope.payload["strength"]?.numberValue { liveValues["Pegelschutz"] = "\(Int(strength))%" }
        case "audio-chunk":
            guard let encoded = envelope.payload["data"]?.stringValue,
                  let bytes = Data(base64Encoded: encoded) else { return }
            let rate = envelope.payload["sampleRate"]?.numberValue ?? 48_000
            recognizer.appendPCM16(bytes, sampleRate: rate)
        case "audio-complete": recognizer.finishPCMStream()
        case "bridge-error": lastError = envelope.payload["message"]?.stringValue
        default: break
        }
    }

    func speak(_ text: String) {
        guard !text.isEmpty else { return }
        guard shouldSpeak(text) else { return }
        speaker.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: String(text.prefix(1_000)))
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        speaker.speak(utterance)
    }

    func setLimiter(enabled: Bool? = nil, strength: Int? = nil) {
        if let enabled { limiterEnabled = enabled }
        if let strength { limiterStrength = max(0, min(100, strength)) }
        sendCommand?("set-limiter", ["enabled": limiterEnabled, "strength": limiterStrength])
    }

    private func shouldSpeak(_ text: String, now: Date = Date()) -> Bool {
        let normalized = text.lowercased().replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return false }
        recentSpeech = recentSpeech.filter { now.timeIntervalSince($0.value) <= repeatWindow }
        let last = recentSpeech[normalized]
        recentSpeech[normalized] = now
        return last.map { now.timeIntervalSince($0) > repeatWindow } ?? true
    }

    func muteAuthor(_ author: String) {
        let normalized = String(author.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
        guard !normalized.isEmpty else { return }
        mutedAuthors.insert(normalized)
        chatLines.removeAll { $0.hasPrefix("\(normalized):") }
        defaults.set(Array(mutedAuthors).sorted(), forKey: Self.mutedAuthorsKey)
    }

    func toggleVlcReplacement() {
        if vlcReplacementURL != nil { vlcReplacementURL = nil; return }
        guard let url = bestVlcMediaURL(in: mediaLinks) else { lastError = "Keine Media-URL verfügbar"; return }
        vlcReplacementURL = url
    }

    func bestVlcMediaURL() -> URL? { bestVlcMediaURL(in: mediaLinks) }

    func clearDebugEvents() { debugEvents.removeAll() }

    func debugReport(vlcInstalled: Bool) -> String {
        let report: [String: Any] = [
            "generatedAtUtc": ISO8601DateFormatter().string(from: Date()),
            "version": "0.7.1",
            "platform": "ios",
            "components": [
                "layout": ["liveInformationBeforePageInformation": true],
                "vlcReplacement": ["placement": "main-video-frame", "installed": vlcInstalled, "active": vlcReplacementURL != nil, "candidateCount": mediaLinks.count],
                "speechAndChatSettings": ["settingsDialogAvailable": false, "auddTokenConfigured": false, "pairingConfigured": false, "universalCaptionApiKeyConfigured": false, "shortenNames": shortenNames, "gameModeEnabled": gameModeEnabled],
                "captions": ["rawBridgeStreamCaptured": true, "available": captionsAvailable],
                "songRecognition": ["path": "ios-native-shazamkit", "source": recognitionSource.rawValue],
                "topChatters": ["mutedCount": mutedAuthors.count, "resetAvailable": true]
            ],
            "raw": [
                "connected": connected,
                "hookAvailable": hookAvailable,
                "captionsAvailable": captionsAvailable,
                "liveInformation": liveValues,
                "chat": chatLines,
                "mutedAuthors": Array(mutedAuthors).sorted(),
                "mediaUrls": mediaLinks.map { ["url": $0.url.absoluteString, "type": $0.type, "label": $0.label] },
                "bridgeEvents": debugEvents
            ]
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private func bestVlcMediaURL(in links: [MobileMediaLink]) -> URL? {
        links.first(where: { $0.url.absoluteString.localizedCaseInsensitiveContains(".m3u8") })?.url
            ?? links.first(where: { !$0.url.absoluteString.localizedCaseInsensitiveContains("only_audio=1") })?.url
    }
}
