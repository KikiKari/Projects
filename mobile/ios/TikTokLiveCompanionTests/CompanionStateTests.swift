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

    func testLimiterAndAutoReconnectCommands() {
        let state = CompanionState(recognizer: FakeRecognizer(), defaults: UserDefaults(suiteName: #function)!)
        var commands: [(String, [String: Any])] = []
        state.sendCommand = { command, payload in commands.append((command, payload)) }
        state.autoReconnectEnabled = false
        state.setLimiter(enabled: true, strength: 90)
        XCTAssertFalse(state.autoReconnectEnabled)
        XCTAssertTrue(state.limiterEnabled)
        XCTAssertEqual(state.limiterStrength, 90)
        XCTAssertEqual(commands.first?.0, "set-auto-reconnect")
        XCTAssertEqual(commands.last?.0, "set-limiter")
        XCTAssertEqual(commands.last?.1["strength"] as? Int, 90)
        XCTAssertNil(commands.last?.1["threshold"])
        state.handle(BridgeEnvelope(version: 1, type: "capability", streamId: "live-1", sequence: 1,
            timestamp: "2026-10-08T12:00:00Z", payload: ["feature": .string("limiter"), "available": .bool(false)]))
        XCTAssertFalse(state.limiterEnabled)
        XCTAssertTrue(state.lastError?.contains("Pegelschutz") == true)
    }

    func testDebugLogIsOptInAndExcludesRawPayload() {
        let state = CompanionState(recognizer: FakeRecognizer(), defaults: UserDefaults(suiteName: #function)!)
        let envelope = BridgeEnvelope(version: 1, type: "caption", streamId: "live-1", sequence: 7, timestamp: "2026-08-13T12:00:00Z", payload: ["text": .string("vollständiger RAW-Text")])
        state.handle(envelope)
        XCTAssertTrue(state.debugEvents.isEmpty)
        state.debugEnabled = true
        state.handle(envelope)
        XCTAssertEqual(state.debugEvents.count, 1)
        XCTAssertFalse(state.debugReport(vlcInstalled: false).contains("vollständiger RAW-Text"))
        XCTAssertTrue(state.debugReport(vlcInstalled: false).contains("ios-native-shazamkit"))
    }

    func testReleaseEightSettingsCaptionsRecommendationsAndReconnectPersist() {
        let suite = #function
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let state = CompanionState(recognizer: FakeRecognizer(), defaults: defaults)
        state.auddToken = "audd"
        state.pairingCode = "pair"
        state.universalCaptionApiKey = "caption"
        state.autoReconnectDelaySeconds = 59
        state.handle(BridgeEnvelope(version: 1, type: "caption", streamId: "live", sequence: 1, timestamp: "2026-08-13T12:00:00Z", payload: ["sentenceId": .string("1"), "definite": .bool(true), "contents": .array([.object(["lang": .string("de"), "text": .string("Hallo")])])]))
        XCTAssertEqual(state.captionRecords.count, 1)
        XCTAssertTrue(state.captionJSONLines().contains("Hallo"))
        XCTAssertTrue(state.debugReport(vlcInstalled: false).contains("0.8.1"))
        let restored = CompanionState(recognizer: FakeRecognizer(), defaults: defaults)
        XCTAssertEqual(restored.auddToken, "audd")
        XCTAssertEqual(restored.autoReconnectDelaySeconds, 59)
    }
    private func recoveryState(_ suite: String) -> CompanionState {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return CompanionState(recognizer: FakeRecognizer(), defaults: defaults)
    }
    private func event(_ type: String, _ payload: [String: JSONValue]) -> BridgeEnvelope {
        BridgeEnvelope(version: 1, type: type, streamId: "live", sequence: 1, timestamp: "2026-10-07T12:00:00Z", payload: payload)
    }
    func testHookAndPlayerRecoveryHaveIndependentSettings() {
        let state = recoveryState(#function)
        state.autoReconnectDelaySeconds = 8
        state.hookReconnectEnabled = true
        state.hookReconnectDelaySeconds = 3
        let restored = CompanionState(recognizer: FakeRecognizer(), defaults: UserDefaults(suiteName: #function)!)
        XCTAssertTrue(restored.hookReconnectEnabled)
        XCTAssertEqual(restored.hookReconnectDelaySeconds, 3)
        XCTAssertEqual(restored.autoReconnectDelaySeconds, 8)
    }
    func testFiveHookFailuresDoNotNavigateOrRebuildPlayer() {
        let state = recoveryState(#function)
        var loads = 0
        var commands: [String] = []
        state.loadURL = { _ in loads += 1 }
        state.sendCommand = { name, _ in commands.append(name) }
        for attempt in 1...5 {
            state.handle(event("hook-recovery", ["phase": .string("failed"), "attempt": .number(Double(attempt))]))
        }
        XCTAssertEqual(loads, 0)
        XCTAssertTrue(commands.isEmpty)
        XCTAssertEqual(state.hookRecovery["attempt"] as? Double, 5)
    }
    func testDiagnosisExcludesCaptionAndCredentialsButExplicitCaptionExportKeepsText() {
        let state = recoveryState(#function)
        state.debugEnabled = true
        state.handle(event("caption", ["text": .string("private-caption"), "token": .string("private-token")]))
        state.handle(event("hook-recovery", ["phase": .string("failed"), "url": .string("https://secret.invalid/signed")]))
        let report = state.debugReport(vlcInstalled: false)
        XCTAssertFalse(report.contains("private-caption"))
        XCTAssertFalse(report.contains("private-token"))
        XCTAssertFalse(report.contains("secret.invalid"))
        XCTAssertTrue(report.contains("firstDecodedAtMs"))
        XCTAssertTrue(state.captionJSONLines().contains("private-caption"))
    }
    func testRetiredDocumentCannotReplaceCurrentRecoveryState() {
        let state = recoveryState(#function)
        let old = UUID().uuidString
        state.handle(event("hook-recovery", ["documentId": .string(old), "phase": .string("failed")]))
        state.noteNavigation(URL(string: "https://www.tiktok.com/@test/live")!)
        state.handle(event("hook-recovery", ["documentId": .string(UUID().uuidString), "phase": .string("connected")]))
        state.handle(event("hook-recovery", ["documentId": .string(old), "phase": .string("failed")]))
        XCTAssertEqual(state.hookRecovery["phase"] as? String, "connected")
    }
    func testEmbedCoalescesClicksAndRequiresObservedPlayback() {
        let state = recoveryState(#function)
        var loads = 0
        state.loadURL = { _ in loads += 1 }
        state.noteNavigation(URL(string: "https://www.tiktok.com/@test/live")!)
        state.openEmbed(); state.openEmbed(); state.openEmbed()
        XCTAssertEqual(loads, 1)
        XCTAssertEqual(state.embedAttempt, 1)
        XCTAssertEqual(state.embedPhase, "loading")
        state.handle(event("player-observation", ["playing": .bool(true)]))
        XCTAssertEqual(state.embedPhase, "playing")
        state.openNormal()
        XCTAssertEqual(loads, 2)
    }
    func testEmbedLoginAndGestureBlockAutomaticRetries() {
        let state = recoveryState(#function)
        state.noteNavigation(URL(string: "https://www.tiktok.com/@test/live")!)
        state.openEmbed()
        state.handle(event("embed-blocked", ["reason": .string("login-required")]))
        XCTAssertEqual(state.embedPhase, "login-required")
        state.openNormal(); state.openEmbed()
        state.handle(event("player-recovery", ["phase": .string("awaiting-gesture")]))
        XCTAssertEqual(state.embedPhase, "awaiting-gesture")
        state.openNormal()
    }
    func testCaptionMenuDoesNotOverrideActivity() {
        let state = recoveryState(#function)
        state.handle(event("caption-state", ["websocket": .bool(true), "metadataPresent": .bool(true)]))
        state.handle(event("inspection", ["captionsControlPresent": .bool(false)]))
        XCTAssertTrue(state.captionsAvailable)
        XCTAssertEqual(state.captionSources["metadataPresent"] as? Bool, true)
        XCTAssertEqual(state.captionSources["menuAvailable"] as? Bool, false)
    }

    func testFractionalSocketTimestampsArePreservedWithoutFreeText() throws {
        let state = recoveryState(#function)
        state.debugEnabled = true
        let stamp = "2026-10-07T12:00:00.123Z"
        state.handle(BridgeEnvelope(version: 1, type: "socket-telemetry", streamId: "live", sequence: 1, timestamp: stamp, payload: ["atUtc": .string(stamp), "stage": .string("socket-open")]))
        let data = state.debugReport(vlcInstalled: false).data(using: .utf8)!
        let report = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let events = report["bridgeEvents"] as! [[String: Any]]
        XCTAssertEqual(events[0]["timestamp"] as? String, stamp)
        XCTAssertEqual((events[0]["payload"] as! [String: Any])["atUtc"] as? String, stamp)
    }

}
