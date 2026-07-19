import XCTest
@testable import TikTokLiveCompanion

final class StreamNameNormalizerTests: XCTestCase {
    func testAcceptsNameWithLeadingAt() { XCTAssertEqual(StreamNameNormalizer.normalize("@creator"), "creator") }
    func testAcceptsNameWithoutAt() { XCTAssertEqual(StreamNameNormalizer.normalize("creator"), "creator") }
    func testTrimsAndLowercases() { XCTAssertEqual(StreamNameNormalizer.normalize("  @Crea.Tor_1  "), "crea.tor_1") }
    func testRejectsEmpty() { XCTAssertNil(StreamNameNormalizer.normalize("   ")) }
    func testRejectsAtOnly() { XCTAssertNil(StreamNameNormalizer.normalize("@")) }
    func testRejectsSpecialCharacters() { XCTAssertNil(StreamNameNormalizer.normalize("crea<script>")) }
    func testRejectsPathInjection() { XCTAssertNil(StreamNameNormalizer.normalize("creator/../evil")) }
    func testRejectsWhitespaceInside() { XCTAssertNil(StreamNameNormalizer.normalize("crea tor")) }
    func testRejectsOverlongName() { XCTAssertNil(StreamNameNormalizer.normalize(String(repeating: "a", count: 25))) }
    func testBuildsLiveURL() { XCTAssertEqual(StreamNameNormalizer.liveURL("@Creator")?.absoluteString, "https://www.tiktok.com/@creator/live") }
    func testLiveURLNilForInvalid() { XCTAssertNil(StreamNameNormalizer.liveURL("!!")) }
}
