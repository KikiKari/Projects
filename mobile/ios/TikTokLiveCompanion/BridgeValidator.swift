import Foundation

enum BridgeValidationError: Error, Equatable { case origin, frame, oversized, malformed, unsupported }

struct BridgeValidator {
    static let allowedOrigin = "https://www.tiktok.com"
    static let maximumBytes = 64 * 1024
    static let allowedTypes: Set<String> = [
        "bridge-ready", "inspection", "capability", "chat", "caption", "live-stats", "gift",
        "bridge-error", "command-result", "audio-chunk", "audio-complete"
    ]

    static func decode(data: Data, origin: String, isMainFrame: Bool) throws -> BridgeEnvelope {
        guard origin == allowedOrigin else { throw BridgeValidationError.origin }
        guard isMainFrame else { throw BridgeValidationError.frame }
        guard data.count <= maximumBytes else { throw BridgeValidationError.oversized }
        guard let envelope = try? JSONDecoder().decode(BridgeEnvelope.self, from: data), envelope.version == 1 else { throw BridgeValidationError.malformed }
        guard allowedTypes.contains(envelope.type) else { throw BridgeValidationError.unsupported }
        return envelope
    }

    static func validatedHTTPS(_ value: String?) -> URL? {
        guard let value, let url = URL(string: value), url.scheme == "https" else { return nil }
        return url
    }
}
