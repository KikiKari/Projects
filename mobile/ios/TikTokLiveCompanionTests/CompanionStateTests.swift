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
        state.handle(try envelope("inspection", #"{"title":"Stream","url":"https://www.tiktok.com/@x/live","creatorHandle":"@x","signature":"Bio","followerText":"12K","verified":true,"videoPresent":true,"captionsControlPresent":false}"#))
        XCTAssertEqual(state.pageInfo["Titel"], "Stream")
        XCTAssertEqual(state.pageInfo["URL"], "https://www.tiktok.com/@x/live")
        XCTAssertEqual(state.pageInfo["Video vorhanden"], "ja")
        XCTAssertEqual(state.pageInfo["Untertitel-Steuerung"], "nein")
        XCTAssertEqual(state.pageInfo["Handle"], "@x")
        XCTAssertEqual(state.pageInfo["Bio"], "Bio")
        XCTAssertEqual(state.pageInfo["Follower"], "12K")
        XCTAssertEqual(state.pageInfo["Verifiziert"], "ja")
    }

    func testLiveStatsMapToGermanLabelsAndCountFollows() throws {
        let state = makeState(#function)
        state.handle(try envelope("live-stats", #"{"viewerCount":42,"likeCount":7}"#))
        state.handle(try envelope("live-stats", #"{"kind":"follow"}"#))
        state.handle(try envelope("live-stats", #"{"kind":"follow"}"#))
        XCTAssertEqual(state.liveValues["Zuschauer*innen"], "42")
        XCTAssertEqual(state.liveValues["Likes"], "7")
        XCTAssertEqual(state.liveValues["Follows seit Hook"], "2")
    }

    func testMediaURLsRequireHTTPSDeduplicateAndKeepTwelve() throws {
        let state = makeState(#function)
        state.handle(try envelope("media-url", #"{"url":"javascript:alert(1)","kind":"network"}"#))
        for index in 0 ..< 14 { state.handle(try envelope("media-url", #"{"url":"https://cdn.example/live-#(index).m3u8","kind":"network"}"#)) }
        state.handle(try envelope("media-url", #"{"url":"https://cdn.example/live-13.m3u8","kind":"player"}"#))
        XCTAssertEqual(state.mediaURLs.count, 12)
        XCTAssertFalse(state.mediaURLs.contains { $0.url.scheme != "https" })
        XCTAssertEqual(state.mediaURLs.last?.kind, "player")
    }

    func testDebugLogIsOptInPayloadFreeAndBounded() throws {
        let state = makeState(#function)
        state.handle(try envelope("command-result", #"{"data":"secret"}"#))
        XCTAssertTrue(state.debugEvents.isEmpty)
        state.debugEnabled = true
        for index in 0 ..< 205 { state.handle(try envelope("command-result", #"{"data":"secret-#(index)"}"#)) }
        XCTAssertEqual(state.debugEvents.count, 200)
        XCTAssertFalse(state.debugEvents.contains { $0.contains("secret") })
    }

    func testParticipantsAreBoundedAndRankByMessagesWordsThenName() throws {
        let state = makeState(#function)
        for index in 0 ... 5_000 { state.handle(try envelope("chat", #"{"nickname":"user\#(index)","content":"one two"}"#)) }
        state.handle(try envelope("chat", #"{"nickname":"user2","content":"one two three"}"#))
        state.handle(try envelope("chat", #"{"nickname":"user1","content":"one"}"#))
        XCTAssertEqual(state.chatterCounts.count, 5_000)
        XCTAssertEqual(state.topChatters.first?.author, "user2")
        XCTAssertEqual(state.topChatters.first?.words, 5)
    }

    func testCumulativeLiveValuesNeverDecrease() throws {
        let state = makeState(#function)
        state.handle(try envelope("live-stats", #"{"likeCount":100,"viewerCount":42}"#))
        state.handle(try envelope("live-stats", #"{"likeCount":80,"viewerCount":30}"#))
        XCTAssertEqual(state.liveValues["Likes"], "100")
        XCTAssertEqual(state.liveValues["Zuschauer*innen"], "30")
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
