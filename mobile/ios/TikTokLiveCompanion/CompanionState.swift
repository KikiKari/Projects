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
    @Published var participants: [String: ParticipantStats] = [:]
    @Published var liveValues: [String: String] = [:]
    @Published var pageInformation: [String: String] = [:]
    @Published var mediaLinks: [MobileMediaLink] = []
    @Published var vlcReplacementURL: URL?
    @Published var mutedAuthors: Set<String>
    @Published var gameModeEnabled = true
    @Published var speakNames = true
    @Published var shortenNames = true
    @Published var keepSpeechActive = true
    @Published var autoReconnectEnabled = true {
        didSet { defaults.set(autoReconnectEnabled, forKey: Self.autoReconnectKey); sendCommand?("set-auto-reconnect", ["enabled": autoReconnectEnabled, "delaySeconds": autoReconnectDelaySeconds]) }
    }
    @Published var autoReconnectDelaySeconds = 3 {
        didSet {
            let safe = max(1, min(59, autoReconnectDelaySeconds))
            if safe != autoReconnectDelaySeconds { autoReconnectDelaySeconds = safe; return }
            defaults.set(safe, forKey: Self.autoReconnectDelayKey)
            sendCommand?("set-auto-reconnect", ["enabled": autoReconnectEnabled, "delaySeconds": safe])
        }
    }
    @Published var auddToken = "" { didSet { defaults.set(String(auddToken.prefix(4096)), forKey: Self.auddTokenKey) } }
    @Published var pairingCode = "" { didSet { defaults.set(String(pairingCode.prefix(512)), forKey: Self.pairingCodeKey) } }
    @Published var universalCaptionApiKey = "" { didSet { defaults.set(String(universalCaptionApiKey.prefix(4096)), forKey: Self.universalApiKey) } }
    @Published var speechLanguage = "Auto" { didSet { defaults.set(speechLanguage, forKey: Self.speechLanguageKey) } }
    @Published var speechVoice = "Systemstandard" { didSet { defaults.set(speechVoice, forKey: Self.speechVoiceKey) } }
    @Published var captionRecords: [CaptionRecord] = []
    @Published var recommendationStatus = "idle"
    @Published var recommendationLimit = 20
    @Published var recommendationScanned = 0
    @Published var recommendationItems: [RecommendationItem] = []
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
    private static let autoReconnectKey = "autoReconnectEnabled"
    private static let autoReconnectDelayKey = "autoReconnectDelaySeconds"
    private static let auddTokenKey = "auddToken"
    private static let pairingCodeKey = "pairingCode"
    private static let universalApiKey = "universalCaptionApiKey"
    private static let speechLanguageKey = "speechLanguage"
    private static let speechVoiceKey = "speechVoice"

    init(recognizer: RecognitionService = ShazamRecognitionService(), defaults: UserDefaults = .standard) {
        self.recognizer = recognizer
        self.defaults = defaults
        self.recognitionSource = defaults.string(forKey: Self.sourceKey).flatMap(RecognitionSource.init(rawValue:)) ?? .microphone
        self.mutedAuthors = Set(defaults.stringArray(forKey: Self.mutedAuthorsKey) ?? [])
        self.autoReconnectEnabled = defaults.object(forKey: Self.autoReconnectKey) as? Bool ?? true
        self.autoReconnectDelaySeconds = max(1, min(59, defaults.object(forKey: Self.autoReconnectDelayKey) as? Int ?? 3))
        self.auddToken = defaults.string(forKey: Self.auddTokenKey) ?? ""
        self.pairingCode = defaults.string(forKey: Self.pairingCodeKey) ?? ""
        self.universalCaptionApiKey = defaults.string(forKey: Self.universalApiKey) ?? ""
        self.speechLanguage = defaults.string(forKey: Self.speechLanguageKey) ?? "Auto"
        self.speechVoice = defaults.string(forKey: Self.speechVoiceKey) ?? "Systemstandard"
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
        case "inspection":
            captionsAvailable = envelope.payload["captionsControlPresent"]?.boolValue == true
            pageInformation = envelope.payload.reduce(into: [:]) { result, entry in
                if let value = entry.value.stringValue { result[entry.key] = value }
                else if let value = entry.value.numberValue { result[entry.key] = String(Int(value)) }
                else if let value = entry.value.boolValue { result[entry.key] = value ? "ja" : "nein" }
            }
        case "chat":
            let author = envelope.payload["nickname"]?.stringValue ?? ""
            let content = envelope.payload["content"]?.stringValue ?? ""
            guard !mutedAuthors.contains(author) else { return }
            chatLines.append(author.isEmpty ? content : "\(author): \(content)")
            if chatLines.count > 50 { chatLines.removeFirst(chatLines.count - 50) }
            if !author.isEmpty {
                var stats = participants[author] ?? ParticipantStats()
                stats.messages += 1
                stats.words += content.split(whereSeparator: \.isWhitespace).count
                participants[author] = stats
            }
        case "caption":
            let contents = envelope.payload["contents"]?.arrayValue
            let first = contents?.first?.objectValue
            let language = first?["lang"]?.stringValue ?? envelope.payload["language"]?.stringValue ?? ""
            let text = first?["text"]?.stringValue ?? envelope.payload["text"]?.stringValue ?? ""
            captionRecords.append(CaptionRecord(timestamp: envelope.timestamp, sentenceId: envelope.payload["sentenceId"]?.stringValue ?? "", definite: envelope.payload["definite"]?.boolValue == true, language: language, text: text, raw: envelope.rawObject))
        case "recommendation-scan-progress":
            recommendationStatus = envelope.payload["status"]?.stringValue ?? "running"
            recommendationScanned = Int(envelope.payload["scanned"]?.numberValue ?? 0)
            recommendationItems = envelope.payload["items"]?.arrayValue?.compactMap { raw in
                guard let item = raw.objectValue,
                      let handle = item["handle"]?.stringValue,
                      let rawURL = item["url"]?.stringValue,
                      let url = URL(string: rawURL), url.scheme == "https" else { return nil }
                return RecommendationItem(handle: handle, displayName: item["displayName"]?.stringValue ?? handle, title: item["title"]?.stringValue ?? "", viewerCount: item["viewerCount"]?.numberValue.map { Int($0) }, viewerLabel: item["viewerLabel"]?.stringValue ?? "", url: url, position: Int(item["position"]?.numberValue ?? 0))
            } ?? []
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
        case "media-url":
            guard let rawURL = envelope.payload["url"]?.stringValue,
                  let url = URL(string: rawURL), url.scheme == "https" else { return }
            let type = envelope.payload["kind"]?.stringValue ?? "stream"
            if !mediaLinks.contains(where: { $0.url == url }) {
                mediaLinks.append(MobileMediaLink(url: url, type: type, label: type.uppercased()))
            }
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
        participants.removeValue(forKey: normalized)
        defaults.set(Array(mutedAuthors).sorted(), forKey: Self.mutedAuthorsKey)
    }

    var topChatters: [TopChatter] {
        participants.sorted { lhs, rhs in lhs.value.messages != rhs.value.messages ? lhs.value.messages > rhs.value.messages : (lhs.value.words != rhs.value.words ? lhs.value.words > rhs.value.words : lhs.key.localizedCaseInsensitiveCompare(rhs.key) == .orderedAscending) }
            .map { TopChatter(author: $0.key, messages: $0.value.messages, words: $0.value.words) }
    }

    func resetTopChatters() { participants.removeAll() }
    func startRecommendationScan() {
        recommendationLimit = max(1, min(50, recommendationLimit))
        recommendationStatus = "running"; recommendationScanned = 0; recommendationItems = []
        sendCommand?("scan-recommendations", ["limit": recommendationLimit])
    }
    func cancelRecommendationScan() { sendCommand?("cancel-recommendation-scan", [:]) }
    func clearCaptions() { captionRecords.removeAll() }
    func captionJSONLines() -> String { captionRecords.compactMap { record in
        guard let data = try? JSONSerialization.data(withJSONObject: record.raw, options: [.sortedKeys]) else { return nil }
        return String(data: data, encoding: .utf8)
    }.joined(separator: "\n") }
    func captionRawJSON() -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: captionRecords.map(\.raw), options: [.prettyPrinted, .sortedKeys]) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
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
            "version": "0.8.0",
            "platform": "ios",
            "components": [
                "layout": ["liveInformationBeforePageInformation": true],
                "vlcReplacement": ["placement": "main-video-frame", "installed": vlcInstalled, "active": vlcReplacementURL != nil, "candidateCount": mediaLinks.count],
                "speechAndChatSettings": ["settingsDialogAvailable": true, "auddTokenConfigured": !auddToken.isEmpty, "pairingConfigured": !pairingCode.isEmpty, "universalCaptionApiKeyConfigured": !universalCaptionApiKey.isEmpty, "speakNames": speakNames, "shortenNames": shortenNames, "gameModeEnabled": gameModeEnabled, "language": speechLanguage, "voice": speechVoice],
                "captions": ["rawBridgeStreamCaptured": true, "available": captionsAvailable, "eventCount": captionRecords.count, "jsonLinesExportAvailable": true, "rawJsonExportAvailable": true],
                "songRecognition": ["path": "ios-native-shazamkit", "source": recognitionSource.rawValue],
                "topChatters": ["observedCount": participants.count, "mutedCount": mutedAuthors.count, "resetAvailable": true],
                "recommendations": ["available": true, "status": recommendationStatus, "requested": recommendationLimit, "scanned": recommendationScanned, "found": recommendationItems.count],
                "autoReconnect": ["enabled": autoReconnectEnabled, "delaySeconds": autoReconnectDelaySeconds]
            ],
            "raw": [
                "connected": connected,
                "hookAvailable": hookAvailable,
                "captionsAvailable": captionsAvailable,
                "liveInformation": liveValues,
                "pageInformation": pageInformation,
                "chat": chatLines,
                "mutedAuthors": Array(mutedAuthors).sorted(),
                "mediaUrls": mediaLinks.map { ["url": $0.url.absoluteString, "type": $0.type, "label": $0.label] },
                "bridgeEvents": debugEvents,
                "captionProtocol": captionRecords.map(\.raw),
                "recommendations": recommendationItems.map { item -> [String: Any] in
                    ["handle": item.handle, "displayName": item.displayName, "title": item.title, "viewerCount": item.viewerCount.map { $0 as Any } ?? NSNull(), "viewerLabel": item.viewerLabel, "url": item.url.absoluteString, "position": item.position]
                }
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
