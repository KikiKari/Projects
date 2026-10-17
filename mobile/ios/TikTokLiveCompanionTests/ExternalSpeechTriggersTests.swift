import XCTest
@testable import TikTokLiveCompanion

final class ExternalSpeechTriggersTests: XCTestCase {
    func testDefaultsEmptyAndPastedSixthCharacter() {
        XCTAssertEqual(ExternalSpeechTriggers.normalize(nil), ".")
        XCTAssertEqual(ExternalSpeechTriggers.normalize(""), "")
        XCTAssertEqual(ExternalSpeechTriggers.normalize(".,-;:!"), ".,-;:")
        XCTAssertEqual(ExternalSpeechTriggers.normalize(" a1 \"'.,- "), ".,-")
        XCTAssertEqual(ExternalSpeechTriggers.normalize("😀😁😂😃😄😅"), "😀😁😂😃😄")
    }
    func testLiteralIndividualPrefixesAndDisabledFilter() {
        for enabled in [true, false] {
            for text in [".Hallo", ",Hallo", "- Hallo", "  ,Hallo"] {
                XCTAssertEqual(ExternalSpeechTriggers.matches(text, enabled: enabled, characters: ".,-"), enabled)
            }
            XCTAssertFalse(ExternalSpeechTriggers.matches("Hallo, zusammen.", enabled: enabled, characters: ".,-"))
        }
        XCTAssertTrue(ExternalSpeechTriggers.matches(";Hallo", enabled: true, characters: ";"))
        XCTAssertTrue(ExternalSpeechTriggers.matches("[Hallo", enabled: true, characters: "["))
        XCTAssertTrue(ExternalSpeechTriggers.matches("😀Hallo", enabled: true, characters: "😀"))
        XCTAssertFalse(ExternalSpeechTriggers.matches(".Hallo", enabled: true, characters: ""))
    }
}
