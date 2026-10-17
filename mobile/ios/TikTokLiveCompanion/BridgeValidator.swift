import Foundation

enum BridgeValidationError: Error, Equatable { case origin, frame, oversized, malformed, unsupported }

struct BridgeValidator {
    static let allowedOrigin = "https://www.tiktok.com"
    static let maximumBytes = 64 * 1024
    static let maximumRecommendationBytes = 1024 * 1024
    static let allowedTypes: Set<String> = [
        "pipeline-record",
        "recovery-ready", "hook-status", "hook-recovery", "socket-telemetry", "caption-state", "player-recovery", "player-observation", "embed-blocked",
        "bridge-ready", "inspection", "capability", "chat", "caption", "live-stats", "gift",
        "media-links", "quick-recover", "limiter", "bridge-error", "command-result", "audio-chunk", "audio-complete",
        "socket-open", "force-start", "force-return", "media-url", "player-state", "recommendation-scan-progress"
    ]

    static func decode(data: Data, origin: String, isMainFrame: Bool) throws -> BridgeEnvelope {
        guard origin == allowedOrigin else { throw BridgeValidationError.origin }
        guard data.count <= maximumRecommendationBytes else { throw BridgeValidationError.oversized }
        guard let envelope = try? JSONDecoder().decode(BridgeEnvelope.self, from: data), envelope.version == 1 else { throw BridgeValidationError.malformed }
        guard data.count <= maximumBytes || envelope.type == "recommendation-scan-progress" else { throw BridgeValidationError.oversized }
        if envelope.type == "recommendation-scan-progress", let items = envelope.payload["items"]?.arrayValue, items.count > 300 { throw BridgeValidationError.oversized }
        guard allowedTypes.contains(envelope.type) else { throw BridgeValidationError.unsupported }
        return envelope
    }

    static func validatedHTTPS(_ value: String?) -> URL? {
        guard let value, let url = URL(string: value), url.scheme == "https" else { return nil }
        return url
    }
}
