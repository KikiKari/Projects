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
    @Published var chatLines: [ChatLine] = []
    @Published var speechQueue: [SpeechRequest] = []
    @Published var ttsEnabled = false { didSet { defaults.set(ttsEnabled, forKey: Self.ttsEnabledKey) } }
    @Published var ttsVolume = 1.0 { didSet { ttsVolume = min(1, max(0, ttsVolume)); defaults.set(ttsVolume, forKey: Self.ttsVolumeKey) } }
    @Published var ttsLanguage: TTSLanguage = .automatic { didSet { defaults.set(ttsLanguage.rawValue, forKey: Self.ttsLanguageKey) } }
    @Published var ttsSpeakNames = true { didSet { defaults.set(ttsSpeakNames, forKey: Self.ttsSpeakNamesKey) } }
    @Published var ttsShortenNames = true { didSet { defaults.set(ttsShortenNames, forKey: Self.ttsShortenNamesKey) } }
    @Published var liveValues: [String: String] = [:]
    @Published var chatterCounts: [String: Int] = [:]
    @Published var chatterWords: [String: Int] = [:]
    @Published var liveNumbers: [String: Int] = [:]
    @Published var pageInfo: [String: String] = [:]
    @Published var limiterEnabled: Bool {
        didSet { defaults.set(limiterEnabled, forKey: Self.limiterEnabledKey); pushLimiter() }
    }
    @Published var limiterThreshold: Int {
        didSet {
            // Zuweisung im eigenen didSet löst keinen weiteren Beobachterlauf aus — daher hier klemmen UND persistieren.
            let clamped = min(-1, max(-30, limiterThreshold))
            if clamped != limiterThreshold { limiterThreshold = clamped }
            defaults.set(limiterThreshold, forKey: Self.limiterThresholdKey)
            pushLimiter()
        }
    }
    @Published var mutedAuthors: Set<String>
    @Published var lastError: String?
    @Published var videoExpanded = false
    @Published var forceInProgress = false
    @Published var forceRecoveryURL: URL?
    @Published var audibleStartRequested = false
    @Published var playerMuted: Bool?
    @Published var audibleStartBlocked = false
    @Published var streamName = ""
    var sendCommand: ((String, [String: Any]) -> Void)?
    var loadURL: ((URL) -> Void)?
    let recognizer: RecognitionService
    private let speaker = AVSpeechSynthesizer()
    private let defaults: UserDefaults
    private var speechSequence = 0
    private var forceWatchdog: Task<Void, Never>?
    private static let sourceKey = "recognitionSource"
    private static let mutedAuthorsKey = "mutedAuthors"
    private static let limiterEnabledKey = "limiterEnabled"
    private static let limiterThresholdKey = "limiterThreshold"
    private static let ttsEnabledKey = "ttsEnabled"
    private static let ttsVolumeKey = "ttsVolume"
    private static let ttsLanguageKey = "ttsLanguage"
    private static let ttsSpeakNamesKey = "ttsSpeakNames"
    private static let ttsShortenNamesKey = "ttsShortenNames"
    private static let liveStatLabels: [String: String] = [
        "viewerCount": "Zuschauer*innen",
        "totalViewers": "Aufrufe gesamt",
        "likeCount": "Likes",
        "followerCount": "Follower gesamt",
        "shareCount": "Teilungen"
    ]

    var topChatters: [(author: String, messages: Int, words: Int)] {
        chatterCounts.map { (author: $0.key, messages: $0.value, words: chatterWords[$0.key, default: 0]) }
            .sorted { $0.messages != $1.messages ? $0.messages > $1.messages : $0.words != $1.words ? $0.words > $1.words : $0.author.localizedCaseInsensitiveCompare($1.author) == .orderedAscending }
            .prefix(5).map { $0 }
    }

    init(recognizer: RecognitionService = ShazamRecognitionService(), defaults: UserDefaults = .standard) {
        self.recognizer = recognizer
        self.defaults = defaults
        self.recognitionSource = defaults.string(forKey: Self.sourceKey).flatMap(RecognitionSource.init(rawValue:)) ?? .microphone
        self.mutedAuthors = Set(defaults.stringArray(forKey: Self.mutedAuthorsKey) ?? [])
        self.limiterEnabled = defaults.bool(forKey: Self.limiterEnabledKey)
        let storedThreshold = defaults.object(forKey: Self.limiterThresholdKey) as? Int ?? -6
        self.limiterThreshold = min(-1, max(-30, storedThreshold))
        self.ttsEnabled = defaults.bool(forKey: Self.ttsEnabledKey)
        self.ttsVolume = defaults.object(forKey: Self.ttsVolumeKey) as? Double ?? 1
        self.ttsLanguage = defaults.string(forKey: Self.ttsLanguageKey).flatMap(TTSLanguage.init(rawValue:)) ?? .automatic
        self.ttsSpeakNames = defaults.object(forKey: Self.ttsSpeakNamesKey) as? Bool ?? true
        self.ttsShortenNames = defaults.object(forKey: Self.ttsShortenNamesKey) as? Bool ?? true
        recognizer.onResult = { [weak self] result in Task { @MainActor in
            self?.recognitionResult = result
            self?.recognitionStatus = result.matched ? "Song erkannt" : "Kein passender Song erkannt"
        }}
        recognizer.onError = { [weak self] message in Task { @MainActor in
            self?.lastError = message
            self?.recognitionStatus = message
        }}
    }

    func toggleVideoExpanded() { videoExpanded.toggle() }

    func startForce() {
        let inspected = pageInfo["URL"].flatMap(URL.init(string:)).flatMap(Self.validatedLiveURL)
        let recovery = inspected ?? StreamNameNormalizer.liveURL(streamName)
        guard let recovery else { lastError = "Force ist erst in einem gültigen LIVE-Stream verfügbar"; return }
        forceWatchdog?.cancel()
        forceInProgress = true
        forceRecoveryURL = recovery
        lastError = nil
        sendCommand?("force-profile", ["liveUrl": recovery.absoluteString])
        forceWatchdog = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 20_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { if self?.forceInProgress == true { self?.recoverForce(reason: "Timeout nach 20 Sekunden") } }
        }
    }

    private static func validatedLiveURL(_ url: URL) -> URL? {
        guard url.scheme == "https", url.host == "www.tiktok.com", url.path.range(of: #"^/@[^/]+/live(?:/|$)"#, options: .regularExpression) != nil else { return nil }
        return url
    }

    func recoverForce(reason: String = "manuelle Rückkehr") {
        let recovery = forceRecoveryURL
        forceWatchdog?.cancel()
        forceInProgress = false
        lastError = recovery == nil ? "Force: \(reason) · bitte manuell zurück" : "Force: \(reason) · LIVE-Stream wurde wieder geöffnet"
        if let recovery { loadURL?(recovery) }
    }

    func openStream() {
        guard let url = StreamNameNormalizer.liveURL(streamName) else {
            lastError = "Ungültiger Streamname · erlaubt sind Buchstaben, Ziffern, Punkt und Unterstrich"
            return
        }
        connected = false; hookAvailable = false; captionsAvailable = false
        chatLines = []; liveValues = [:]; liveNumbers = [:]; chatterCounts = [:]; chatterWords = [:]; pageInfo = [:]
        audibleStartRequested = true; playerMuted = nil; audibleStartBlocked = false
        loadURL?(url)
    }

    func enableStreamSound() {
        audibleStartRequested = true
        audibleStartBlocked = false
        sendCommand?("start-audible", [:])
    }

    func pushLimiter() {
        sendCommand?("set-limiter", ["enabled": limiterEnabled, "threshold": limiterThreshold])
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
        switch envelope.type {
        case "bridge-ready": pushLimiter(); if audibleStartRequested { sendCommand?("start-audible", [:]) }
        case "capability":
            let feature = envelope.payload["feature"]?.stringValue
            let available = envelope.payload["available"]?.boolValue == true
            if feature == "websocket-hook" { hookAvailable = hookAvailable || available }
            if feature == "webview-audio", !available, recognitionSource == .webview {
                recognitionStatus = "WebView-Audio nicht verfügbar · Mikrofon wählen"
                recognizer.cancel()
            }
            if feature == "limiter", !available { lastError = "Pegelschutz nicht verfügbar · Player oder Web Audio fehlt" }
        case "inspection":
            captionsAvailable = envelope.payload["captionsControlPresent"]?.boolValue == true
            var info: [String: String] = [:]
            if let title = envelope.payload["title"]?.stringValue, !title.isEmpty { info["Titel"] = title }
            if let url = envelope.payload["url"]?.stringValue, !url.isEmpty { info["URL"] = url }
            if let value = envelope.payload["canonicalUrl"]?.stringValue, !value.isEmpty { info["Kanonische URL"] = value }
            if let value = envelope.payload["description"]?.stringValue, !value.isEmpty { info["Beschreibung"] = value }
            if let value = envelope.payload["creatorName"]?.stringValue, !value.isEmpty { info["Creator"] = value }
            if let value = envelope.payload["creatorHandle"]?.stringValue, !value.isEmpty { info["Handle"] = value }
            if let value = envelope.payload["followerText"]?.stringValue, !value.isEmpty { info["Follower"] = value }
            if let value = envelope.payload["followingText"]?.stringValue, !value.isEmpty { info["Gefolgt"] = value }
            if let value = envelope.payload["profileLikesText"]?.stringValue, !value.isEmpty { info["Profil-Likes"] = value }
            if let value = envelope.payload["signature"]?.stringValue, !value.isEmpty { info["Bio"] = value }
            if let value = envelope.payload["language"]?.stringValue, !value.isEmpty { info["Seitensprache"] = value }
            info["Verifiziert"] = envelope.payload["verified"]?.boolValue == true ? "ja" : "nein"
            info["Video vorhanden"] = envelope.payload["videoPresent"]?.boolValue == true ? "ja" : "nein"
            info["Untertitel-Steuerung"] = captionsAvailable ? "ja" : "nein"
            pageInfo = info
        case "chat":
            let author = envelope.payload["nickname"]?.stringValue ?? ""
            let content = envelope.payload["content"]?.stringValue ?? ""
            guard !mutedAuthors.contains(author) else { return }
            let language = envelope.payload["language"]?.stringValue ?? ""
            speechSequence += 1
            let line = ChatLine(id: speechSequence, author: String(author.prefix(128)), content: String(content.prefix(1_000)), language: String(language.prefix(24)))
            chatLines.append(line)
            if chatLines.count > 50 { chatLines.removeFirst(chatLines.count - 50) }
            if !author.isEmpty, chatterCounts[author] != nil || chatterCounts.count < 5_000 {
                chatterCounts[author, default: 0] += 1
                chatterWords[author, default: 0] += content.split(whereSeparator: { $0.isWhitespace }).count
            }
            if ttsEnabled { enqueueSpeech(line) }
        case "live-stats":
            for (key, label) in Self.liveStatLabels {
                let number = envelope.payload[key]?.numberValue.map { Int($0) } ?? envelope.payload[key]?.stringValue.flatMap { Int($0) }
                if let number {
                    let effective = key == "viewerCount" ? number : max(number, liveNumbers[key, default: 0])
                    liveNumbers[key] = effective
                    liveValues[label] = String(effective)
                }
            }
            if envelope.payload["kind"]?.stringValue == "follow" {
                liveValues["Follows seit Hook"] = String((Int(liveValues["Follows seit Hook"] ?? "0") ?? 0) + 1)
            }
        case "force-return":
            if envelope.payload["ok"]?.boolValue == true { forceWatchdog?.cancel(); forceInProgress = false; forceRecoveryURL = nil }
            if envelope.payload["ok"]?.boolValue == false { recoverForce(reason: "Bridge-Rückkehr fehlgeschlagen") }
        case "force-start":
            forceInProgress = true
            if let value = envelope.payload["url"]?.stringValue, let url = URL(string: value), let valid = Self.validatedLiveURL(url) { forceRecoveryURL = valid }
        case "player-state":
            playerMuted = envelope.payload["muted"]?.boolValue
            audibleStartBlocked = envelope.payload["reason"]?.stringValue == "autoplay-blocked"
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

    func speak(_ line: ChatLine) { enqueueSpeech(line) }

    private func enqueueSpeech(_ line: ChatLine) {
        let spokenAuthor = ttsShortenNames ? String(line.author.prefix(24)) : line.author
        let text = ttsSpeakNames && !spokenAuthor.isEmpty ? "\(spokenAuthor) sagt \(line.content)" : line.content
        let detected = line.language.lowercased().hasPrefix("de") ? "de-DE" : line.language.lowercased().hasPrefix("en") ? "en-US" : nil
        let request = SpeechRequest(id: speechSequence + speechQueue.count + 1, text: String(text.prefix(1_000)), languageTag: ttsLanguage.voiceTag ?? detected)
        speechQueue.append(request)
        if speechQueue.count > 5 { speechQueue.removeFirst(speechQueue.count - 5) }
        speak(request)
    }

    private func speak(_ request: SpeechRequest) {
        guard !request.text.isEmpty else { return }
        speaker.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: request.text)
        utterance.volume = Float(ttsVolume)
        if let tag = request.languageTag { utterance.voice = AVSpeechSynthesisVoice(language: tag) }
        speaker.speak(utterance)
    }

    func muteAuthor(_ author: String) {
        let normalized = String(author.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
        guard !normalized.isEmpty else { return }
        mutedAuthors.insert(normalized)
        chatLines.removeAll { $0.author == normalized }
        chatterCounts.removeValue(forKey: normalized)
        chatterWords.removeValue(forKey: normalized)
        defaults.set(Array(mutedAuthors).sorted(), forKey: Self.mutedAuthorsKey)
    }
}
