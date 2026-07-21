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
    private static let sourceKey = "recognitionSource"
    private static let mutedAuthorsKey = "mutedAuthors"
    private static let limiterEnabledKey = "limiterEnabled"
    private static let limiterThresholdKey = "limiterThreshold"
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
            chatLines.append(author.isEmpty ? content : "\(author): \(content)")
            if chatLines.count > 50 { chatLines.removeFirst(chatLines.count - 50) }
            if !author.isEmpty { chatterCounts[author, default: 0] += 1 }
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

    func speak(_ text: String) {
        guard !text.isEmpty else { return }
        speaker.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: String(text.prefix(1_000)))
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        speaker.speak(utterance)
    }

    func muteAuthor(_ author: String) {
        let normalized = String(author.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
        guard !normalized.isEmpty else { return }
        mutedAuthors.insert(normalized)
        chatLines.removeAll { $0.hasPrefix("\(normalized):") }
        defaults.set(Array(mutedAuthors).sorted(), forKey: Self.mutedAuthorsKey)
    }
}
