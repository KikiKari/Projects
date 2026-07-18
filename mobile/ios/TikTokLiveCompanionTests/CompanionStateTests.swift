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
}
