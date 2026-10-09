import XCTest
import UIKit
import MobileVLCKit
import WebKit
@testable import TikTokLiveCompanion

private final class AudioWorkletProbe: NSObject, WKScriptMessageHandler {
    var receive: ((Any) -> Void)?
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) { receive?(message.body) }
}

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
    func testConnectionAcknowledgementAndBrowserReturn() {
        let state = recoveryState(#function)
        var commands: [String] = []
        state.sendCommand = { name, _ in commands.append(name) }
        state.setConnectionEnabled(true)
        XCTAssertFalse(state.connectionEnabled)
        state.handle(event("capability", ["feature": .string("connection"), "available": .bool(true)]))
        XCTAssertTrue(state.connectionEnabled)
        state.setConnectionEnabled(false)
        XCTAssertTrue(state.connectionEnabled)
        state.handle(event("capability", ["feature": .string("connection"), "available": .bool(false)]))
        XCTAssertFalse(state.connectionEnabled)
        state.handle(event("media-url", ["url": .string("https://cdn.example/live.m3u8"), "kind": .string("network")]))
        state.toggleVlcReplacement()
        XCTAssertNotNil(state.vlcReplacementURL)
        state.openNormal()
        XCTAssertNil(state.vlcReplacementURL)
        XCTAssertTrue(commands.contains("set-vlc-active"))
    }
    func testAutoChatRefreshPersistence() {
        let suite = #function
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let state = CompanionState(recognizer: FakeRecognizer(), defaults: defaults)
        state.autoChatRefreshEnabled = true; state.autoChatRefreshMinutes = 7
        let restored = CompanionState(recognizer: FakeRecognizer(), defaults: defaults)
        XCTAssertTrue(restored.autoChatRefreshEnabled)
        XCTAssertEqual(restored.autoChatRefreshMinutes, 7)
        state.autoChatRefreshEnabled = false; restored.autoChatRefreshEnabled = false
    }
    func testNativeVlcPcmIsLimitedAndStops() async throws {
        // Real decoder -> native callback -> common limiter -> AVAudioEngine.
        // This measures digital PCM, not physical speaker output or A/V sync.
        let rate = 48000
        var data = Data()
        func word(_ value: UInt32) { var value = value.littleEndian; withUnsafeBytes(of: &value) { data.append(contentsOf: $0) } }
        func short(_ value: UInt16) { var value = value.littleEndian; withUnsafeBytes(of: &value) { data.append(contentsOf: $0) } }
        data.append(contentsOf: "RIFF".utf8); word(UInt32(36 + rate * 2 * 2))
        data.append(contentsOf: "WAVEfmt ".utf8); word(16); short(1); short(2)
        word(UInt32(rate)); word(UInt32(rate * 4)); short(4); short(16)
        data.append(contentsOf: "data".utf8); word(UInt32(rate * 4))
        for i in 0..<rate {
            let sample = Int16(sin(Double(i) * 2 * .pi * 8000 / Double(rate)) * 31000)
            short(UInt16(bitPattern: sample)); short(UInt16(bitPattern: sample))
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        var previousPeak = Double.infinity
        for strength in [-1, 25, 75, 100] {
            let enabled = strength >= 0
            let measured = expectation(description: "VLC PCM at strength \(strength)")
            var peak: Double?
            let audio = try XCTUnwrap(TLCNativeVlcAudio(report: { active, input, output, reduction, error in
                XCTAssertNil(error)
                if active == enabled && input > -3 && output > -90 && peak == nil {
                    print("Native PCM: strength=\(strength) input=\(input) output=\(output) reduction=\(reduction)")
                    XCTAssertEqual(input, -1.732, accuracy: 0.05, "Decoded signed PCM16 fixture must have a plausible input peak")
                    if enabled { XCTAssertLessThanOrEqual(output, -4 - Double(strength) * 0.26 + 0.05) }
                    else { XCTAssertEqual(output, input, accuracy: 0.05); XCTAssertEqual(reduction, 0, accuracy: 0.05) }
                    peak = output; measured.fulfill()
                }
            }))
            audio.setProtection(enabled: enabled, strength: max(0, strength))
            audio.play(url: url, drawable: UIView())
            await fulfillment(of: [measured], timeout: 15)
            if let peak { XCTAssertLessThan(peak, previousPeak); previousPeak = peak }
            let stopped = expectation(description: "VLC native callbacks stopped at \(strength)")
            audio.stop { stopped.fulfill() }
            await fulfillment(of: [stopped], timeout: 10)
        }
    }
    func testNativePauseResumeSeekAndLiveProtectionChanges() async throws {
        let rate = 48000, frames = 48000 * 12
        var data = Data()
        func word(_ value: UInt32) { var value = value.littleEndian; withUnsafeBytes(of: &value) { data.append(contentsOf: $0) } }
        func short(_ value: UInt16) { var value = value.littleEndian; withUnsafeBytes(of: &value) { data.append(contentsOf: $0) } }
        data.append(contentsOf: "RIFF".utf8); word(UInt32(36 + frames * 4))
        data.append(contentsOf: "WAVEfmt ".utf8); word(16); short(1); short(2)
        word(UInt32(rate)); word(UInt32(rate * 4)); short(4); short(16)
        data.append(contentsOf: "data".utf8); word(UInt32(frames * 4))
        for i in 0..<frames {
            let sample = Int16(sin(Double(i) * 2 * .pi * 8000 / Double(rate)) * 31000)
            short(UInt16(bitPattern: sample)); short(UInt16(bitPattern: sample))
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        var reports = [Double]()
        var target = -10.5
        var pending: XCTestExpectation? = expectation(description: "Initial protected output")
        let audio = try XCTUnwrap(TLCNativeVlcAudio(report: { _, _, output, _, error in
            XCTAssertNil(error)
            reports.append(output)
            if abs(output - target) < 0.05 { pending?.fulfill(); pending = nil }
        }))
        audio.setProtection(enabled: true, strength: 25)
        audio.play(url: url, drawable: UIView())
        if let check = pending { await fulfillment(of: [check], timeout: 8) }
        target = -30; pending = expectation(description: "Live strength change")
        audio.setProtection(enabled: true, strength: 100)
        if let check = pending { await fulfillment(of: [check], timeout: 8) }
        audio.player.pause()
        try await Task.sleep(nanoseconds: 300_000_000)
        reports.removeAll()
        try await Task.sleep(nanoseconds: 350_000_000)
        XCTAssertTrue(reports.isEmpty, "PCM output must pause")
        pending = expectation(description: "Resume protected output")
        audio.player.play()
        if let check = pending { await fulfillment(of: [check], timeout: 8) }
        pending = expectation(description: "Output after seek and flush")
        audio.player.position = 0.5
        if let check = pending { await fulfillment(of: [check], timeout: 8) }
        target = -1.732; pending = expectation(description: "Live bypass")
        audio.setProtection(enabled: false, strength: 100)
        if let check = pending { await fulfillment(of: [check], timeout: 8) }
        let stopped = expectation(description: "Output stopped")
        audio.stop { stopped.fulfill() }
        await fulfillment(of: [stopped], timeout: 10)
        reports.removeAll()
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertTrue(reports.isEmpty, "No reports after native stop")
    }
    func testPackagedAudioWorkletInWKWebView() async throws {
        let coreURL = try XCTUnwrap(Bundle.main.url(forResource: "content-core", withExtension: "js"))
        let core = try String(contentsOf: coreURL, encoding: .utf8)
        let finished = expectation(description: "WKWebView AudioWorklet rendered")
        var response: [String: Any]?
        let probe = AudioWorkletProbe()
        probe.receive = { response = $0 as? [String: Any]; finished.fulfill() }
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(probe, name: "audioProbe")
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 480), configuration: configuration)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        let controller = UIViewController()
        controller.view = webView
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer {
            webView.stopLoading()
            configuration.userContentController.removeScriptMessageHandler(forName: "audioProbe")
            window.isHidden = true
            window.rootViewController = nil
        }
        let script = """
        (async () => {
          try {
            const rows = [];
            for (const strength of [-1,25,75,100]) {
              const ctx = new OfflineAudioContext(1,4800,48000);
              const buffer = ctx.createBuffer(1,4800,48000);
              buffer.getChannelData(0)[1000] = 0.95;
              const source = ctx.createBufferSource(); source.buffer = buffer;
              const limiter = await TLC_CONTENT_CORE.createPeakLimiterNode(ctx);
              limiter.setProtection({enabled:strength >= 0,strength:Math.max(0,strength)});
              source.connect(limiter).connect(ctx.destination); source.start();
              const rendered = await ctx.startRendering();
              const pcm = rendered.getChannelData(0);
              let peak=0,index=-1;
              for(let i=0;i<pcm.length;i++) if(Math.abs(pcm[i])>peak){peak=Math.abs(pcm[i]);index=i;}
              rows.push({strength,db:20*Math.log10(peak),delay:index-1000});
              limiter.port.close();
            }
            window.webkit.messageHandlers.audioProbe.postMessage({rows});
          } catch(error) { window.webkit.messageHandlers.audioProbe.postMessage({error:String(error)}); }
        })();
        """
        // Local document with the shipped resource; no live-site policy claim.
        webView.loadHTMLString("<html><script>" + core + "</script><script>" + script + "</script></html>", baseURL: URL(string: "https://localhost/"))
        await fulfillment(of: [finished], timeout: 20)
        let result = try XCTUnwrap(response)
        XCTAssertNil(result["error"], String(describing: result))
        let rows = try XCTUnwrap(result["rows"] as? [[String: Any]])
        XCTAssertEqual(rows.count, 4)
        let expected = [20 * log10(0.95), -10.5, -23.5, -30.0]
        for (index, row) in rows.enumerated() {
            XCTAssertEqual(try XCTUnwrap(row["db"] as? Double), expected[index], accuracy: 0.05)
            XCTAssertEqual(try XCTUnwrap(row["delay"] as? Int), 240)
        }
    }
    func testExternalTriggerFilterPersistsAndPrecedesNames() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let state = CompanionState(recognizer: FakeRecognizer(), defaults: defaults)
        XCTAssertFalse(state.filterExternalSpeechTriggers)
        for game in [false,true] { for enabled in [false,true] {
            state.gameModeEnabled = game; state.filterExternalSpeechTriggers = enabled
            for text in [".Text", ". Text", "  .Text", "Normal", "Ein Satz. Noch einer", "ABC"] {
                XCTAssertEqual(state.speechText(text, author: "Autor") == nil, enabled && text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("."))
            }
        } }
        XCTAssertEqual(state.speechText("ABC", author: "Autor"), "Autor: ABC")
        XCTAssertTrue(CompanionState(recognizer: FakeRecognizer(), defaults: defaults).filterExternalSpeechTriggers)
        defaults.removePersistentDomain(forName: #function)
    }
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
    func testLimiterMigratesThresholdAndPersistsExactStrength() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        defer { defaults.removePersistentDomain(forName: #function) }
        defaults.set(-17, forKey: "limiterThreshold")
        let state = CompanionState(recognizer: FakeRecognizer(), defaults: defaults)
        XCTAssertEqual(state.limiterStrength, 50)
        for strength in [25, 75, 100] {
            state.setLimiter(enabled: true, strength: strength)
            let restored = CompanionState(recognizer: FakeRecognizer(), defaults: defaults)
            XCTAssertTrue(restored.limiterEnabled)
            XCTAssertEqual(restored.limiterStrength, strength)
        }
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
        XCTAssertTrue(state.debugReport(vlcInstalled: false).contains("0.8.2"))
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
