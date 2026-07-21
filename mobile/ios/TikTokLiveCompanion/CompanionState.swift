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
    @Published var streamName = ""
    var sendCommand: ((String, [String: Any]) -> Void)?
    var loadURL: ((URL) -> Void)?
    let recognizer: RecognitionService
    private let speaker = AVSpeechSynthesizer()
    private let defaults: UserDefaults
    private var speechSequence = 0
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

    var topChatters: [(String, Int)] {
        chatterCounts.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }.prefix(5).map { ($0.key, $0.value) }
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

    func openStream() {
        guard let url = StreamNameNormalizer.liveURL(streamName) else {
            lastError = "Ungültiger Streamname · erlaubt sind Buchstaben, Ziffern, Punkt und Unterstrich"
            return
        }
        connected = false; hookAvailable = false; captionsAvailable = false
        chatLines = []; liveValues = [:]; chatterCounts = [:]; pageInfo = [:]
        loadURL?(url)
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
        case "bridge-ready": pushLimiter()
        case "capability":
            let feature = envelope.payload["feature"]?.stringValue
            let available = envelope.payload["available"]?.boolValue == true
            if feature == "websocket-hook" { hookAvailable = hookAvailable || available }
            if feature == "webview-audio", !available, recognitionSource == .webview {
                recognitionStatus = "WebView-Audio nicht verfügbar · Mikrofon wählen"
                recognizer.cancel()
            }
        case "inspection":
            captionsAvailable = envelope.payload["captionsControlPresent"]?.boolValue == true
            var info: [String: String] = [:]
            if let title = envelope.payload["title"]?.stringValue, !title.isEmpty { info["Titel"] = title }
            if let url = envelope.payload["url"]?.stringValue, !url.isEmpty { info["URL"] = url }
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
            if !author.isEmpty { chatterCounts[author, default: 0] += 1 }
            if ttsEnabled { enqueueSpeech(line) }
        case "live-stats":
            for (key, label) in Self.liveStatLabels {
                if let text = envelope.payload[key]?.stringValue, !text.isEmpty { liveValues[label] = text }
                else if let number = envelope.payload[key]?.numberValue { liveValues[label] = String(Int(number)) }
            }
            if envelope.payload["kind"]?.stringValue == "follow" {
                liveValues["Follows seit Start"] = String((Int(liveValues["Follows seit Start"] ?? "0") ?? 0) + 1)
            }
        case "force-return":
            if envelope.payload["ok"]?.boolValue == false {
                lastError = "Force: automatische Rückkehr zum LIVE-Stream fehlgeschlagen · bitte manuell zurück"
            }
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
        defaults.set(Array(mutedAuthors).sorted(), forKey: Self.mutedAuthorsKey)
    }
}
