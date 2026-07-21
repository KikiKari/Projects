import XCTest
@testable import TikTokLiveCompanion

private final class FakeRecognizer: RecognitionService {
    var onResult: ((RecognitionResult) -> Void)?
    var onError: ((String) -> Void)?
    var microphoneStarts = 0
    var streamStarts = 0
    func startMicrophone() { microphoneStarts += 1 }
    func startPCMStream(source: RecognitionSource, sampleRate: Double) { streamStarts += 1 }
    func appendPCM16(_ data: Data, sampleRate: Double) {}
    func finishPCMStream() {}
    func cancel() {}
}

@MainActor final class CompanionStateTests: XCTestCase {
    func testRecognitionRequiresExplicitActionAndSelectedSource() {
        let fake = FakeRecognizer()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let state = CompanionState(recognizer: fake, defaults: defaults)
        XCTAssertEqual(fake.microphoneStarts, 0)
        state.recognize()
        XCTAssertEqual(fake.microphoneStarts, 1)
        state.recognitionSource = .webview
        state.recognize()
        XCTAssertEqual(fake.streamStarts, 1)
    }

    func testPersistsRecognitionSourceAndDurableMutes() {
        let suite = #function
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let first = CompanionState(recognizer: FakeRecognizer(), defaults: defaults)
        first.recognitionSource = .webview
        first.muteAuthor("spam-author")
        let restored = CompanionState(recognizer: FakeRecognizer(), defaults: defaults)
        XCTAssertEqual(restored.recognitionSource, .webview)
        XCTAssertTrue(restored.mutedAuthors.contains("spam-author"))
    }

    private func makeState(_ suite: String) -> CompanionState {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return CompanionState(recognizer: FakeRecognizer(), defaults: defaults)
    }

    private func envelope(_ type: String, _ json: String) throws -> BridgeEnvelope {
        let raw = #"{"version":1,"type":"\#(type)","streamId":"","sequence":1,"timestamp":"2026-07-21T12:00:00Z","payload":\#(json)}"#
        return try JSONDecoder().decode(BridgeEnvelope.self, from: raw.data(using: .utf8)!)
    }

    func testChatEventsFillChatAndTopChatters() throws {
        let state = makeState(#function)
        for index in 0 ..< 3 { state.handle(try envelope("chat", #"{"nickname":"Anna","content":"hi \#(index)"}"#)) }
        state.handle(try envelope("chat", #"{"nickname":"Ben","content":"hallo"}"#))
        XCTAssertEqual(state.chatLines.count, 4)
        XCTAssertEqual(state.topChatters.map { $0.0 }, ["Anna", "Ben"])
        state.muteAuthor("Anna")
        XCTAssertFalse(state.chatLines.contains { $0.author == "Anna" })
    }

    func testChatCapAndPersistentTTSCoreSettings() throws {
        let suite = #function
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let state = CompanionState(recognizer: FakeRecognizer(), defaults: defaults)
        state.ttsEnabled = true
        state.ttsLanguage = .english
        state.ttsSpeakNames = false
        state.ttsVolume = 0.4
        for index in 0 ..< 60 { state.handle(try envelope("chat", #"{"nickname":"Anna","content":"hello \#(index)","language":"de"}"#)) }
        XCTAssertEqual(state.chatLines.count, 50)
        XCTAssertEqual(state.speechQueue.count, 5)
        XCTAssertEqual(state.speechQueue.last?.languageTag, "en-US")
        XCTAssertEqual(state.speechQueue.last?.text, "hello 59")
        let restored = CompanionState(recognizer: FakeRecognizer(), defaults: defaults)
        XCTAssertTrue(restored.ttsEnabled)
        XCTAssertEqual(restored.ttsLanguage, .english)
        XCTAssertEqual(restored.ttsVolume, 0.4, accuracy: 0.001)
    }

    func testInspectionFillsPageInfo() throws {
        let state = makeState(#function)
        state.handle(try envelope("inspection", #"{"title":"Stream","url":"https://www.tiktok.com/@x/live","videoPresent":true,"captionsControlPresent":false}"#))
        XCTAssertEqual(state.pageInfo["Titel"], "Stream")
        XCTAssertEqual(state.pageInfo["URL"], "https://www.tiktok.com/@x/live")
        XCTAssertEqual(state.pageInfo["Video vorhanden"], "ja")
        XCTAssertEqual(state.pageInfo["Untertitel-Steuerung"], "nein")
    }

    func testLiveStatsMapToGermanLabelsAndCountFollows() throws {
        let state = makeState(#function)
        state.handle(try envelope("live-stats", #"{"viewerCount":42,"likeCount":7}"#))
        state.handle(try envelope("live-stats", #"{"kind":"follow"}"#))
        state.handle(try envelope("live-stats", #"{"kind":"follow"}"#))
        XCTAssertEqual(state.liveValues["Zuschauer*innen"], "42")
        XCTAssertEqual(state.liveValues["Likes"], "7")
        XCTAssertEqual(state.liveValues["Follows seit Start"], "2")
    }

    func testLimiterSettingsAreClampedPersistedAndSentToBridge() throws {
        let suite = #function
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let state = CompanionState(recognizer: FakeRecognizer(), defaults: defaults)
        var sent: [(String, [String: Any])] = []
        state.sendCommand = { command, payload in sent.append((command, payload)) }
        state.limiterEnabled = true
        state.limiterThreshold = -99
        XCTAssertEqual(state.limiterThreshold, -30)
        state.limiterThreshold = 5
        XCTAssertEqual(state.limiterThreshold, -1)
        XCTAssertTrue(sent.contains { $0.0 == "set-limiter" })
        state.handle(try envelope("bridge-ready", "{}"))
        XCTAssertEqual(sent.last?.0, "set-limiter")
        let restored = CompanionState(recognizer: FakeRecognizer(), defaults: defaults)
        XCTAssertTrue(restored.limiterEnabled)
        XCTAssertEqual(restored.limiterThreshold, -1)
    }

    func testFailedForceReturnSurfacesError() throws {
        let state = makeState(#function)
        state.handle(try envelope("force-return", #"{"ok":false,"reason":"max-attempts"}"#))
        XCTAssertTrue(state.lastError?.contains("Force") == true)
        state.handle(try envelope("force-return", #"{"ok":true}"#))
    }

    func testForceFailureRecoversToValidatedLiveURL() throws {
        let state = makeState(#function)
        var loaded: [URL] = []
        var sent: [String] = []
        state.loadURL = { loaded.append($0) }
        state.sendCommand = { command, _ in sent.append(command) }
        state.streamName = "creator"
        state.startForce()
        XCTAssertEqual(sent, ["force-profile"])
        state.handle(try envelope("force-return", #"{"ok":false}"#))
        XCTAssertEqual(loaded.map(\.absoluteString), ["https://www.tiktok.com/@creator/live"])
        XCTAssertFalse(state.forceInProgress)
    }

    func testHookAvailabilityStaysOnceAnyFrameReportsIt() throws {
        let state = makeState(#function)
        state.handle(try envelope("capability", #"{"feature":"websocket-hook","available":true}"#))
        state.handle(try envelope("capability", #"{"feature":"websocket-hook","available":false}"#))
        XCTAssertTrue(state.hookAvailable)
    }
}
