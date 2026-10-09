import AVFoundation
import Foundation

@MainActor final class CompanionState: ObservableObject {
    struct ServiceVoice: Identifiable { let id: String; let name: String; let culture: String; let installed: Bool; let bytes: Int; let license: String }
    @Published var serviceVoices: [ServiceVoice] = []
    @Published var serviceStatus = ""
    private var serviceAudio: AVAudioPlayer?
    private var serviceSpeechTask: Task<Void, Never>?
    private var pipelineRetryTask: Task<Void, Never>?
    @Published var serviceURL = "" { didSet { defaults.set(serviceURL, forKey: "companionServiceURL") } }
    private let serviceClient = MobilePipelineClient()
    @Published var hookReconnectEnabled = false {
        didSet { defaults.set(hookReconnectEnabled, forKey: "hookReconnectEnabled"); pushHookRecovery() }
    }
    @Published var hookReconnectDelaySeconds = 3 {
        didSet {
            let safe = max(1, min(59, hookReconnectDelaySeconds))
            if safe != hookReconnectDelaySeconds { hookReconnectDelaySeconds = safe; return }
            defaults.set(safe, forKey: "hookReconnectDelaySeconds"); pushHookRecovery()
        }
    }
    @Published var hookRecovery: [String: Any] = [:]
    @Published var playerRecovery: [String: Any] = [:]
    @Published var captionSources: [String: Any] = [:]
    @Published var embedMode = false
    @Published var embedPhase = "idle"
    @Published var embedAttempt = 0
    var loadURL: ((URL) -> Void)?
    private var normalURL = URL(string: "https://www.tiktok.com/live")!
    private var connectionPaused = false
    private var currentDocument: String?
    private var retiredDocuments: Set<String> = []
    private var embedTask: Task<Void, Never>?
    private var captionTask: Task<Void, Never>?
    private var embedStartedAt = Date()
    private var embedId = UUID().uuidString
    @Published var selectedTab: CompanionTab = .song
    @Published var recognitionSource: RecognitionSource {
        didSet { defaults.set(recognitionSource.rawValue, forKey: Self.sourceKey) }
    }
    @Published var recognitionStatus = "Bereit für manuelle Erkennung"
    @Published var recognitionResult: RecognitionResult?
    @Published var connectionEnabled = false
    @Published var hookAvailable = false
    @Published var captionsAvailable = false
    @Published var connected = false
    struct SpeechChatEntry { let author: String; let content: String }
    @Published var speechChatEntries: [SpeechChatEntry] = []
    private var chatRefreshTask: Task<Void, Never>?
    @Published var autoChatRefreshEnabled = false { didSet { defaults.set(autoChatRefreshEnabled, forKey: "autoChatRefreshEnabled"); scheduleChatRefresh() } }
    @Published var autoChatRefreshMinutes = 5 { didSet {
        let safe = max(1, min(60, autoChatRefreshMinutes))
        if safe != autoChatRefreshMinutes { autoChatRefreshMinutes = safe; return }
        defaults.set(safe, forKey: "autoChatRefreshMinutes"); scheduleChatRefresh()
    } }
    @Published var speechEnabled = false
    @Published var filterExternalSpeechTriggers = false { didSet { defaults.set(filterExternalSpeechTriggers, forKey: "filterExternalSpeechTriggers") } }
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
    @Published var universalCaptionApiKey = "" { didSet { defaults.set(String(universalCaptionApiKey.prefix(4096)), forKey: Self.universalApiKey); sendCommand?("set-pipeline-enabled", ["enabled": !universalCaptionApiKey.isEmpty]) } }
    @Published var speechLanguage = "Auto" { didSet { defaults.set(speechLanguage, forKey: Self.speechLanguageKey) } }
    @Published var speechVoice = "Systemstandard" { didSet { defaults.set(speechVoice, forKey: Self.speechVoiceKey) } }
    @Published var captionRecords: [CaptionRecord] = []
    @Published var recommendationStatus = "idle"
    @Published var recommendationLimit = 20
    @Published var recommendationScanned = 0
    @Published var recommendationItems: [RecommendationItem] = []
    @Published var limiterEnabled = false
    @Published var limiterStrength = 30
    @Published var webLimiterStatus = "WebView · Pegelschutz aus"
    @Published var nativeLimiterStatus = "Noch keine native Audiomessung"
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
        self.serviceURL = defaults.string(forKey: "companionServiceURL") ?? ""
        self.autoChatRefreshEnabled = defaults.bool(forKey: "autoChatRefreshEnabled")
        self.autoChatRefreshMinutes = max(1, min(60, defaults.object(forKey: "autoChatRefreshMinutes") as? Int ?? 5))
        self.filterExternalSpeechTriggers = defaults.bool(forKey: "filterExternalSpeechTriggers")
        self.limiterEnabled = defaults.bool(forKey: "limiterEnabled")
        let oldThreshold = defaults.object(forKey: "limiterThreshold") as? Double
        self.limiterStrength = max(0, min(100, defaults.object(forKey: "limiterStrength") as? Int ?? oldThreshold.map { Int((-$0 - 4) * 100 / 26) } ?? 30))
        self.recognitionSource = defaults.string(forKey: Self.sourceKey).flatMap(RecognitionSource.init(rawValue:)) ?? .microphone
        self.mutedAuthors = Set(defaults.stringArray(forKey: Self.mutedAuthorsKey) ?? [])
        self.autoReconnectEnabled = defaults.object(forKey: Self.autoReconnectKey) as? Bool ?? true
        self.autoReconnectDelaySeconds = max(1, min(59, defaults.object(forKey: Self.autoReconnectDelayKey) as? Int ?? 3))
        self.hookReconnectEnabled = defaults.bool(forKey: "hookReconnectEnabled")
        self.hookReconnectDelaySeconds = max(1, min(59, defaults.object(forKey: "hookReconnectDelaySeconds") as? Int ?? 3))
        self.auddToken = defaults.string(forKey: Self.auddTokenKey) ?? ""
        self.pairingCode = defaults.string(forKey: Self.pairingCodeKey) ?? ""
        self.universalCaptionApiKey = defaults.string(forKey: Self.universalApiKey) ?? ""
        self.speechLanguage = defaults.string(forKey: Self.speechLanguageKey) ?? "Auto"
        self.speechVoice = defaults.string(forKey: Self.speechVoiceKey) ?? "Systemstandard"
        scheduleChatRefresh()
        pipelineRetryTask = Task { [weak self] in
            while !Task.isCancelled {
                if let owner = self, !owner.universalCaptionApiKey.isEmpty {
                    do { try await owner.serviceClient.flush(baseURL: owner.serviceURL, pairing: owner.pairingCode, key: owner.universalCaptionApiKey) }
                    catch { owner.serviceStatus = "Pipeline-Verbindung unterbrochen; gespeicherte Daten werden erneut gesendet." }
                }
                do { try await Task.sleep(nanoseconds: 30_000_000_000) } catch { return }
            }
        }
        recognizer.onResult = { [weak self] result in Task { @MainActor in
            self?.recognitionResult = result
            if let data = try? JSONEncoder().encode(result), let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] { self?.publishPipeline("songs", data: object) }
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
        if !universalCaptionApiKey.isEmpty {
            let url = serviceURL, pairing = pairingCode, key = universalCaptionApiKey, audd = auddToken
            Task { do { try await serviceClient.capture(envelope, baseURL: url, pairing: pairing, key: key, secrets: [audd]) } catch { lastError = "Pipeline-Verbindung unterbrochen; Daten bleiben vorgemerkt." } }
        }
        if connectionPaused && ["chat", "caption", "live-stats", "gift", "socket-open"].contains(envelope.type) { return }
        if envelope.payload["frameKind"]?.stringValue != "sub", let doc = envelope.payload["documentId"]?.stringValue {
            guard !retiredDocuments.contains(doc) else { return }
            if currentDocument == nil { currentDocument = doc }
            guard currentDocument == doc else { return }
        }
        connected = true
        if debugEnabled {
            debugEvents.append(["type": envelope.type, "sequence": envelope.sequence, "timestamp": RecoveryProjection.validTimestamp(envelope.timestamp) ? envelope.timestamp as Any : NSNull(), "payload": RecoveryProjection.project(envelope.payload)])
            debugEvents = Array(debugEvents.suffix(2000))
        }
        switch envelope.type {
        case "bridge-ready", "recovery-ready":
            sendCommand?("set-pipeline-enabled", ["enabled": !universalCaptionApiKey.isEmpty])
            pushHookRecovery()
            sendCommand?("set-auto-reconnect", ["enabled": autoReconnectEnabled, "delaySeconds": autoReconnectDelaySeconds])
            sendCommand?("set-vlc-active", ["active": vlcReplacementURL != nil])
        case "hook-status": hookAvailable = envelope.payload["installed"]?.boolValue == true
        case "hook-recovery": hookRecovery = RecoveryProjection.project(envelope.payload)
        case "player-recovery":
            playerRecovery = RecoveryProjection.project(envelope.payload)
            if embedMode, envelope.payload["phase"]?.stringValue == "awaiting-gesture" { embedTask?.cancel(); embedPhase = "awaiting-gesture" }
        case "caption-state":
            captionSources = RecoveryProjection.project(envelope.payload)
            captionsAvailable = ["websocket", "dom", "playerText"].contains { envelope.payload[$0]?.boolValue == true }
        case "embed-blocked":
            if embedMode { embedTask?.cancel(); embedPhase = envelope.payload["reason"]?.stringValue == "ended" ? "ended" : "login-required" }
        case "player-observation":
            if embedMode, ["loading", "awaiting-gesture"].contains(embedPhase), envelope.payload["playing"]?.boolValue == true { embedTask?.cancel(); embedPhase = "playing" }
        case "player-state":
            if embedMode, envelope.payload["reason"]?.stringValue == "autoplay-blocked" { embedTask?.cancel(); embedPhase = "awaiting-gesture" }
        case "capability":
            let feature = envelope.payload["feature"]?.stringValue
            let available = envelope.payload["available"]?.boolValue == true
            if feature == "connection" { connectionPaused = !available; connectionEnabled = available }
            if feature == "websocket-hook" { hookAvailable = available }
            if feature == "limiter" && vlcReplacementURL == nil {
                limiterEnabled = available && envelope.payload["enabled"]?.boolValue == true
                if !available { lastError = "Pegelschutz nicht verfügbar · Player oder AudioWorklet fehlt" }
            }
            if feature == "webview-audio", !available, recognitionSource == .webview {
                recognitionStatus = "WebView-Audio nicht verfügbar · Mikrofon wählen"
                recognizer.cancel()
            }
        case "inspection":
            captionSources["menuAvailable"] = envelope.payload["captionsControlPresent"]?.boolValue == true
            pageInformation = envelope.payload.reduce(into: [:]) { result, entry in
                if let value = entry.value.stringValue { result[entry.key] = value }
                else if let value = entry.value.numberValue { result[entry.key] = String(Int(value)) }
                else if let value = entry.value.boolValue { result[entry.key] = value ? "ja" : "nein" }
            }
        case "chat":
            let author = envelope.payload["nickname"]?.stringValue ?? ""
            let content = envelope.payload["content"]?.stringValue ?? ""
            guard !mutedAuthors.contains(author) else { return }
            speechChatEntries.append(SpeechChatEntry(author: author, content: content))
            speechChatEntries = Array(speechChatEntries.suffix(50))
            if speechEnabled { speak(content, author: author) }
            chatLines.append(author.isEmpty ? content : "\(author): \(content)")
            if chatLines.count > 50 { chatLines.removeFirst(chatLines.count - 50) }
            if !author.isEmpty {
                var stats = participants[author] ?? ParticipantStats()
                stats.messages += 1
                stats.words += content.split(whereSeparator: \.isWhitespace).count
                participants[author] = stats
            }
            publishPipeline("top-chatters", data: participants.mapValues { ["messages": $0.messages, "words": $0.words] })
        case "caption":
            let contents = envelope.payload["contents"]?.arrayValue
            let first = contents?.first?.objectValue
            let language = first?["lang"]?.stringValue ?? envelope.payload["language"]?.stringValue ?? ""
            let text = first?["text"]?.stringValue ?? envelope.payload["text"]?.stringValue ?? ""
            captionRecords.append(CaptionRecord(timestamp: envelope.timestamp, sentenceId: envelope.payload["sentenceId"]?.stringValue ?? "", definite: envelope.payload["definite"]?.boolValue == true, language: language, text: text, raw: ["timestamp": envelope.timestamp, "sentenceId": envelope.payload["sentenceId"]?.stringValue ?? "", "language": language, "text": text, "definite": envelope.payload["definite"]?.boolValue == true]))
            captionRecords = Array(captionRecords.suffix(2000))
            captionsAvailable = true; captionTask?.cancel()
            captionTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                guard !Task.isCancelled else { return }; self?.captionsAvailable = false
            }
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
            // Preserve the selected VLC source across new candidate observations.
        case "media-url":
            guard let rawURL = envelope.payload["url"]?.stringValue,
                  let url = URL(string: rawURL), url.scheme == "https" else { return }
            let type = envelope.payload["kind"]?.stringValue ?? "stream"
            if !mediaLinks.contains(where: { $0.url == url }) {
                mediaLinks.append(MobileMediaLink(url: url, type: type, label: type.uppercased()))
            }
        case "quick-recover": liveValues["Auto-Reconnect"] = "aktiv"
        case "limiter":
            if vlcReplacementURL == nil && limiterEnabled,
               let input = envelope.payload["inputPeakDbfs"]?.numberValue,
               let output = envelope.payload["outputPeakDbfs"]?.numberValue,
               let reduction = envelope.payload["reductionDb"]?.numberValue,
               input.isFinite, output.isFinite, reduction.isFinite {
                let mode = envelope.payload["limiterMode"]?.stringValue == "Kompressor" ? "Kompressor" : "Lookahead"
                webLimiterStatus = String(format: "WebView · %@ · Eingang %.1f dBFS · Ausgang %.1f dBFS · Dämpfung %.1f dB", mode, input, output, reduction)
            }
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

    func speechText(_ content: String, author: String = "") -> String? {
        if filterExternalSpeechTriggers && content.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(".") { return nil }
        guard !content.isEmpty else { return nil }
        return speakNames && !author.isEmpty ? "\(author): \(content)" : content
    }
    private func scheduleChatRefresh() {
        chatRefreshTask?.cancel()
        guard autoChatRefreshEnabled else { return }
        let interval = UInt64(autoChatRefreshMinutes) * 60_000_000_000
        chatRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(nanoseconds: interval) } catch { return }
                guard let self else { return }
                self.chatLines.removeAll(); self.speechChatEntries.removeAll()
            }
        }
    }
    func setConnectionEnabled(_ enabled: Bool) {
        guard let sendCommand else { lastError = "Connection ist noch nicht bereit"; return }
        sendCommand("set-connection", ["enabled": enabled])
    }
    func setSpeechEnabled(_ enabled: Bool) {
        speechEnabled = enabled
        if !enabled { speaker.stopSpeaking(at: .immediate); serviceSpeechTask?.cancel(); serviceAudio?.stop() }
    }
    func speak(_ content: String, author: String = "") {
        guard let text = speechText(content, author: author) else { return }
        guard shouldSpeak(text) else { return }
        speaker.stopSpeaking(at: .immediate)
        serviceSpeechTask?.cancel(); serviceAudio?.stop()
        if speechVoice.hasPrefix("sherpa-") || speechVoice.hasPrefix("vits-") || serviceVoices.contains(where: { $0.id == speechVoice }) {
            let voice = speechVoice
            serviceSpeechTask = Task {
                do {
                    let audio = try await serviceClient.request("/v1/tts", baseURL: serviceURL, pairing: pairingCode, body: ["text": text, "language": "auto", "voiceName": voice])
                    try Task.checkCancellation()
                    serviceAudio = try AVAudioPlayer(data: audio)
                    guard serviceAudio?.play() == true else { throw URLError(.cannotDecodeContentData) }
                } catch is CancellationError {} catch { lastError = "Sherpa-Sprachausgabe nicht verfügbar." }
            }
            return
        }
        let utterance = AVSpeechUtterance(string: String(text.prefix(1_000)))
        utterance.voice = AVSpeechSynthesisVoice(identifier: speechVoice) ?? AVSpeechSynthesisVoice(language: "de-DE")
        speaker.speak(utterance)
    }

    private func publishPipeline(_ pipeline: String, data: [String: Any]) {
        guard !universalCaptionApiKey.isEmpty else { return }
        let documentID = currentDocument
        Task { try? await serviceClient.publishData(pipeline, data: data, documentID: documentID, baseURL: serviceURL, pairing: pairingCode, key: universalCaptionApiKey) }
    }
    func loadServiceVoices() {
        Task {
            do {
                let data = try await serviceClient.request("/v1/voices", baseURL: serviceURL, pairing: pairingCode)
                let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if !universalCaptionApiKey.isEmpty {
                    try? await serviceClient.publishData("sherpa", data: object ?? [:], documentID: currentDocument, baseURL: serviceURL, pairing: pairingCode, key: universalCaptionApiKey)
                    let health = try await serviceClient.request("/v1/health", baseURL: serviceURL, pairing: pairingCode)
                    let healthObject = try JSONSerialization.jsonObject(with: health) as? [String: Any] ?? [:]
                    try? await serviceClient.publishData("speech-service", data: healthObject, documentID: currentDocument, baseURL: serviceURL, pairing: pairingCode, key: universalCaptionApiKey)
                }
                serviceVoices = (object?["catalog"] as? [[String: Any]] ?? []).compactMap { voice in
                    guard let id = voice["id"] as? String, let name = voice["name"] as? String else { return nil }
                    return ServiceVoice(id: id, name: name, culture: voice["culture"] as? String ?? "", installed: voice["installed"] as? Bool ?? false, bytes: voice["bytes"] as? Int ?? 0, license: (voice["license"] as? [String: Any])?["id"] as? String ?? "")
                }
                serviceStatus = "Companion-Dienst verbunden"
            } catch { serviceStatus = "Companion-Dienst nicht erreichbar" }
        }
    }
    func installServiceVoice(_ id: String) {
        Task {
            do {
                _ = try await serviceClient.request("/v1/voices/install", baseURL: serviceURL, pairing: pairingCode, body: ["voiceId": id])
                serviceStatus = "Stimme wird installiert"
                for _ in 0..<120 {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    let data = try await serviceClient.request("/v1/sherpa/status", baseURL: serviceURL, pairing: pairingCode)
                    let status = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if status?["running"] as? Bool != true {
                        if let error = status?["error"] as? String, !error.isEmpty { serviceStatus = error; return }
                        loadServiceVoices(); return
                    }
                }
                serviceStatus = "Installation dauert länger; Status erneut laden"
            } catch { serviceStatus = "Stimme konnte nicht installiert werden" }
        }
    }

    func reportNativeLimiter(url: URL, active: Bool, input: Double, output: Double, reduction: Double, error: String?) {
        guard vlcReplacementURL == url else { return }
        nativeLimiterStatus = error ?? String(format: "VLC intern · Schutz %@ · Eingang %.1f dBFS · Ausgang %.1f dBFS · Dämpfung %.1f dB · Vorlauf 5 ms", active ? "aktiv" : "aus", input, output, reduction)
        if let error { limiterEnabled = false; lastError = error }
    }
    func setLimiter(enabled: Bool? = nil, strength: Int? = nil) {
        if let enabled { limiterEnabled = enabled }
        if let strength { limiterStrength = max(0, min(100, strength)) }
        defaults.set(limiterEnabled, forKey: "limiterEnabled")
        defaults.set(limiterStrength, forKey: "limiterStrength")
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
        speechChatEntries.removeAll { $0.author == normalized }
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
        if vlcReplacementURL != nil { vlcReplacementURL = nil; sendCommand?("set-vlc-active", ["active": false]); return }
        guard let url = bestVlcMediaURL(in: mediaLinks) else { lastError = "Keine Media-URL verfügbar"; return }
        vlcReplacementURL = url
        sendCommand?("set-vlc-active", ["active": true])
    }

    func bestVlcMediaURL() -> URL? { bestVlcMediaURL(in: mediaLinks) }

    private func pushHookRecovery() {
        sendCommand?("set-hook-reconnect", ["enabled": hookReconnectEnabled, "delaySeconds": hookReconnectDelaySeconds])
    }
    func noteNavigation(_ url: URL) {
        if let doc = currentDocument { retiredDocuments.insert(doc) }
        currentDocument = nil; captionTask?.cancel(); captionsAvailable = false
        captionSources = [:]; hookRecovery = [:]; playerRecovery = [:]
        if url.host == "www.tiktok.com", url.path.range(of: "^/@[^/]+/live/?$", options: .regularExpression) != nil { normalURL = url }
    }
    func openEmbed() {
        if embedMode, ["loading", "retry-wait", "playing", "awaiting-gesture"].contains(embedPhase) { return }
        let parts = normalURL.path.split(separator: "/")
        guard let first = parts.first, first.hasPrefix("@"), parts.last == "live",
              let url = URL(string: "https://www.tiktok.com/embed/live/\(first)") else { return }
        embedTask?.cancel(); embedStartedAt = Date(); embedId = UUID().uuidString
        embedMode = true; embedAttempt = 0; vlcReplacementURL = nil
        startEmbedAttempt(url)
    }
    private func startEmbedAttempt(_ url: URL) {
        guard embedMode, embedAttempt < 3, Date().timeIntervalSince(embedStartedAt) < 90 else { embedPhase = "failed"; return }
        embedAttempt += 1; embedPhase = "loading"; noteNavigation(url); loadURL?(url)
        embedTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard !Task.isCancelled, let self, self.embedMode, self.embedPhase == "loading" else { return }
            self.startEmbedAttempt(url)
        }
    }
    func openNormal() {
        if vlcReplacementURL != nil { toggleVlcReplacement() }
        guard embedMode else { return }
        embedTask?.cancel(); embedMode = false; embedPhase = "cancelled"
        noteNavigation(normalURL); loadURL?(normalURL)
    }

    func clearDebugEvents() { debugEvents.removeAll() }

    func debugReport(vlcInstalled: Bool) -> String {
        let report: [String: Any] = [
            "generatedAtUtc": ISO8601DateFormatter().string(from: Date()),
            "version": "0.8.2",
            "platform": "ios",
            "components": [
                "layout": ["liveInformationBeforePageInformation": true],
                "vlcReplacement": ["placement": "main-video-frame", "installed": vlcInstalled, "active": vlcReplacementURL != nil, "candidateCount": mediaLinks.count],
                "speechAndChatSettings": ["settingsDialogAvailable": true, "auddTokenConfigured": !auddToken.isEmpty, "pairingConfigured": !pairingCode.isEmpty, "universalCaptionApiKeyConfigured": !universalCaptionApiKey.isEmpty, "speakNames": speakNames, "shortenNames": shortenNames, "gameModeEnabled": gameModeEnabled, "language": ["Auto", "Deutsch", "Englisch"].contains(speechLanguage) ? speechLanguage : "Auto", "voiceConfigured": !speechVoice.isEmpty],
                "captions": ["rawBridgeStreamCaptured": false, "available": captionsAvailable, "eventCount": captionRecords.count, "jsonLinesExportAvailable": true, "rawJsonExportAvailable": true],
                "songRecognition": ["path": "ios-native-shazamkit", "source": recognitionSource.rawValue],
                "topChatters": ["observedCount": participants.count, "mutedCount": mutedAuthors.count, "resetAvailable": true],
                "recommendations": ["available": true, "status": recommendationStatus, "requested": recommendationLimit, "scanned": recommendationScanned, "found": recommendationItems.count],
                "hookReconnect": ["enabled": hookReconnectEnabled, "delaySeconds": hookReconnectDelaySeconds],
                "autoReconnect": ["enabled": autoReconnectEnabled, "delaySeconds": autoReconnectDelaySeconds]
            ],
            "schemaVersion": "tiktok-live-companion-diagnostic-v3",
            "snapshotId": UUID().uuidString,
            "hookRecovery": RecoveryProjection.missingMeasurements.merging(hookRecovery) { _, new in new },
            "playerRecovery": playerRecovery,
            "captionSources": captionSources,
            "embedStartup": ["id": embedId, "phase": embedPhase, "attempt": embedAttempt],
            "bridgeEvents": debugEvents
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private func bestVlcMediaURL(in links: [MobileMediaLink]) -> URL? {
        links.first(where: { $0.url.absoluteString.localizedCaseInsensitiveContains(".m3u8") })?.url
            ?? links.first(where: { !$0.url.absoluteString.localizedCaseInsensitiveContains("only_audio=1") })?.url
    }
}

private enum RecoveryProjection {
    static let ids: Set<String> = ["id", "documentId", "hookDocumentId", "socketId", "hookAttemptId"]
    static let numbers: Set<String> = ["attempt", "detectedAtMs", "scheduledAtMs", "startedAtMs", "configuredDelayMs", "effectiveDelayMs", "socketOpenAtMs", "firstFrameAtMs", "firstDecodedAtMs", "completedAtMs", "endedAtMs", "actualWaitMs", "scheduleOverrunMs", "disconnectToDecodedMs", "connectToDecodedMs", "elapsedMs", "closeCode", "activityTtlMs", "mediaProgressAtMs", "currentTime"]
    static let flags: Set<String> = ["enabled", "connected", "installed", "playing", "paused", "ended", "userPaused", "vlcActive", "wasClean", "metadataPresent", "menuAvailable", "websocket", "dom", "playerText"]
    static let words: Set<String> = ["disabled", "waiting", "unavailable", "scheduled", "connecting", "native", "socket-open", "first-frame", "first-decoded-message", "connected", "failed", "cancelled", "socket-close", "stream-changed", "configuration-changed", "native-takeover", "native-connected", "qualified-data", "timeout", "connect-error", "policy-rejected", "protocol-unverified", "protocol-error", "send-error", "document-ended", "socket-created", "socket-error", "hook-reconnect", "normal", "embed", "tiktok", "extension", "chat", "caption", "live", "gift", "playing", "awaiting-gesture", "media-progress", "player-changed", "user-paused", "vlc-changed", "loading", "login-required", "ended", "retry-wait", "player-stall", "stalled", "error", "waiting"]
    static let missingMeasurements: [String: Any] = Dictionary(uniqueKeysWithValues: ["socketOpenAtMs", "firstFrameAtMs", "firstDecodedAtMs", "completedAtMs", "disconnectToDecodedMs", "connectToDecodedMs"].map { ($0, NSNull() as Any) })
    static func validTimestamp(_ value: String) -> Bool {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) != nil || ISO8601DateFormatter().date(from: value) != nil
    }
    static func project(_ values: [String: JSONValue]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in values {
            if ids.contains(key) { result[key] = value.stringValue.flatMap { UUID(uuidString: $0) }.map { $0.uuidString as Any } ?? NSNull() }
            else if numbers.contains(key) { result[key] = value.numberValue.flatMap { $0.isFinite ? $0 : nil }.map { $0 as Any } ?? NSNull() }
            else if flags.contains(key) { result[key] = value.boolValue.map { $0 as Any } ?? NSNull() }
            else if ["phase", "reason", "stage", "controller", "mode", "owner", "kind"].contains(key) { result[key] = value.stringValue.flatMap { words.contains($0) ? $0 : nil }.map { $0 as Any } ?? NSNull() }
            else if key == "atUtc" { result[key] = value.stringValue.flatMap { validTimestamp($0) ? $0 : nil }.map { $0 as Any } ?? NSNull() }
        }
        return result
    }
}


@MainActor private final class MobilePipelineClient {
    private let sessionID = UUID().uuidString
    private let tabID = UUID().uuidString
    private let clientID: String
    private let directory: URL
    private var flushing = false
    private let session = URLSession(configuration: .ephemeral, delegate: CompanionNoRedirectDelegate(), delegateQueue: nil)
    private var registeredDocuments = Set<String>()
    init() {
        clientID = UserDefaults.standard.string(forKey: "pipelineClientID") ?? UUID().uuidString
        UserDefaults.standard.set(clientID, forKey: "pipelineClientID")
        directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("pipeline-outbox")
    }
    func publishData(_ pipeline: String, data: [String: Any], documentID: String?, baseURL: String, pairing: String, key: String) async throws {
        let object: [String: Any] = ["version": 1, "type": "pipeline-snapshot", "streamId": "companion", "sequence": 0, "timestamp": ISO8601DateFormatter().string(from: Date()), "payload": ["pipeline": pipeline, "data": data, "documentId": documentID ?? sessionID]]
        let envelope = try JSONDecoder().decode(BridgeEnvelope.self, from: JSONSerialization.data(withJSONObject: object))
        try await capture(envelope, baseURL: baseURL, pairing: pairing, key: key, secrets: [])
    }
    func request(_ route: String, baseURL: String, pairing: String, body: [String: Any]? = nil) async throws -> Data {
        guard let base = URL(string: baseURL), base.scheme == "https", base.host != nil, base.user == nil, base.query == nil,
              let url = URL(string: baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + route) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(pairing)", forHTTPHeaderField: "Authorization")
        if let body { request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type"); request.httpBody = try JSONSerialization.data(withJSONObject: body) }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else { throw URLError(.badServerResponse) }
        return data
    }
    func capture(_ envelope: BridgeEnvelope, baseURL: String, pairing: String, key: String, secrets: [String]) async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let mapping = ["caption": "title", "chat": "chat", "live-stats": "live", "inspection": "profile", "media-links": "media-links", "media-url": "media-links", "pipeline-document": "browser-tab"]
        let pipeline = ["pipeline-record", "pipeline-snapshot"].contains(envelope.type) ? (envelope.payload["pipeline"]?.stringValue ?? "debug-logs") : (mapping[envelope.type] ?? "debug-logs")
        var types = [pipeline]
        if pipeline != "debug-logs" { types.append("debug-logs") }
        if pipeline == "title" { types.append("live-logs") }
        let document = envelope.payload["documentId"]?.stringValue ?? sessionID
        let initial = registeredDocuments.insert(document).inserted ? ["title", "chat", "speech-service", "sherpa", "top-chatters", "profile", "live", "songs", "media-links", "live-logs", "debug-logs", "browser-tab"].filter { !types.contains($0) } : []
        types = initial + types
        for type in types {
            let id = UUID().uuidString
            let sequence = UserDefaults.standard.integer(forKey: "pipelineSourceSequence") + 1
            UserDefaults.standard.set(sequence, forKey: "pipelineSourceSequence")
            let unavailable = initial.contains(type)
            let structured: [String: Any] = unavailable ? ["reason": "not-yet-observed"] : envelope.rawObject
            let raw: Any = unavailable ? NSNull() as Any : envelope.rawObject as Any
            let row: [String: Any] = ["sourceSequence": sequence, "eventId": id, "clientId": clientID, "sessionId": sessionID, "tabId": tabID,
                "documentId": document, "pipeline": type,
                "capturedAt": ISO8601DateFormatter().string(from: Date()), "availability": initial.contains(type) ? "unavailable" : "available", "source": "ios-webview-bridge",
                "structured": structured, "raw": raw]
            let data = try JSONSerialization.data(withJSONObject: row)
            var text = String(decoding: data, as: UTF8.self)
            for secret in ([pairing, key] + secrets).filter({ !$0.isEmpty }) { text = text.replacingOccurrences(of: secret, with: "[credential removed]") }
            var sanitized = try JSONSerialization.jsonObject(with: Data(text.utf8)) as! [String: Any]
            sanitized["credentialsRedacted"] = text != String(decoding: data, as: UTF8.self)
            try JSONSerialization.data(withJSONObject: sanitized).write(to: directory.appendingPathComponent(id + ".json"), options: .atomic)
        }
        try await flush(baseURL: baseURL, pairing: pairing, key: key)
    }
    func flush(baseURL: String, pairing: String, key: String) async throws {
        guard !flushing, !baseURL.isEmpty, !pairing.isEmpty, !key.isEmpty,
              FileManager.default.fileExists(atPath: directory.path) else { return }
        flushing = true
        defer { flushing = false }
        _ = try await request("/v1/pipelines/key", baseURL: baseURL, pairing: pairing, body: ["key": key])
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey]).filter { $0.pathExtension == "json" }.sorted { first, second in
            let a = ((try? JSONSerialization.jsonObject(with: Data(contentsOf: first))) as? [String: Any])?["sourceSequence"] as? Int ?? 0
            let b = ((try? JSONSerialization.jsonObject(with: Data(contentsOf: second))) as? [String: Any])?["sourceSequence"] as? Int ?? 0
            return a < b
        }
        for file in files {
            let row = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
            _ = try await request("/v1/pipelines/events", baseURL: baseURL, pairing: pairing, body: row)
            try FileManager.default.removeItem(at: file)
        }
    }
}

private final class CompanionNoRedirectDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}
