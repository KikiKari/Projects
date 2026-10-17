import XCTest
@testable import TikTokLiveCompanion

final class CompanionEndpointTests: XCTestCase {
    func testLocalSuccessDoesNotValidateBrokenAlternative() async throws {
        var attempts: [String] = []
        let selected = try await CompanionEndpoint.select("not a URL") { attempts.append($0) }
        XCTAssertEqual(selected, CompanionEndpoint.local)
        XCTAssertEqual(attempts, [CompanionEndpoint.local])
    }
    func testAlternativeOnlyAfterBothLocalFailures() async throws {
        var attempts: [String] = []
        let selected = try await CompanionEndpoint.select("service.example:443") {
            attempts.append($0)
            if $0.hasPrefix("http:") { throw URLError(.cannotConnectToHost) }
        }
        XCTAssertEqual(selected, "https://service.example:443")
        XCTAssertEqual(attempts, [CompanionEndpoint.local, "http://localhost:43117", selected])
    }
    func testMissingAlternativeDescribesLocalFailure() async {
        do {
            _ = try await CompanionEndpoint.select("") { _ in throw URLError(.cannotConnectToHost) }
            XCTFail("Expected local-service failure")
        } catch { XCTAssertTrue(error.localizedDescription.contains("Kein lokaler")) }
    }
    func testCancellationDoesNotRetry() async {
        var attempts = 0
        do {
            _ = try await CompanionEndpoint.select("service.example") { _ in attempts += 1; throw CancellationError() }
            XCTFail("Expected cancellation")
        } catch { XCTAssertTrue(error is CancellationError); XCTAssertEqual(attempts, 1) }
    }
    func testUnsafeAddressesAreRejected() throws {
        for address in ["https://user:secret@host", "https://host/?key=value", "https://host/#fragment", "http://100.94.134.39:43117", "https://host/path"] {
            XCTAssertThrowsError(try CompanionEndpoint.normalize(address))
        }
        XCTAssertEqual(try CompanionEndpoint.normalize("100.94.134.39"), "https://100.94.134.39")
        XCTAssertEqual(try CompanionEndpoint.normalize("http://localhost:43117"), "http://localhost:43117")
    }
}
