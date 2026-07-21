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

    func toggleVideoExpanded() { videoExpanded.toggle() }

    func openStream() {
        guard let url = StreamNameNormalizer.liveURL(streamName) else {
            lastError = "Ungültiger Streamname · erlaubt sind Buchstaben, Ziffern, Punkt und Unterstrich"
            return
        }
        connected = false; hookAvailable = false; captionsAvailable = false
        chatLines = []; liveValues = [:]
        loadURL?(url)
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
