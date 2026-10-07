package app.tiktoklivecompanion

import org.json.JSONObject

/** Export projection: no free-form payload, URLs, identities, chat or caption text. */
object RecoveryDiagnostics {
    private val ids = setOf("id", "documentId", "hookDocumentId", "socketId", "hookAttemptId")
    private val numbers = setOf("attempt", "detectedAtMs", "scheduledAtMs", "startedAtMs", "configuredDelayMs", "effectiveDelayMs", "socketOpenAtMs", "firstFrameAtMs", "firstDecodedAtMs", "completedAtMs", "endedAtMs", "actualWaitMs", "scheduleOverrunMs", "disconnectToDecodedMs", "connectToDecodedMs", "elapsedMs", "closeCode", "activityTtlMs", "mediaProgressAtMs", "currentTime")
    private val flags = setOf("enabled", "connected", "installed", "playing", "paused", "ended", "userPaused", "vlcActive", "wasClean", "metadataPresent", "menuAvailable", "websocket", "dom", "playerText")
    private val words = setOf("disabled", "waiting", "unavailable", "scheduled", "connecting", "native", "socket-open", "first-frame", "first-decoded-message", "connected", "failed", "cancelled", "socket-close", "stream-changed", "configuration-changed", "native-takeover", "native-connected", "qualified-data", "timeout", "connect-error", "policy-rejected", "protocol-unverified", "protocol-error", "send-error", "document-ended", "socket-created", "socket-error", "hook-reconnect", "normal", "embed", "tiktok", "extension", "chat", "caption", "live", "gift", "playing", "awaiting-gesture", "media-progress", "player-changed", "user-paused", "vlc-changed", "loading", "login-required", "ended", "retry-wait", "player-stall", "stalled", "error", "waiting")
    fun project(payload: Map<String, Any?>): Map<String, Any?> = buildMap {
        for ((key, value) in payload) when {
            key == "atUtc" -> put(key, (value as? String)?.takeIf { runCatching { java.time.Instant.parse(it) }.isSuccess })
            key in ids -> put(key, (value as? String)?.takeIf { it.matches(Regex("[a-fA-F0-9-]{32,36}")) })
            key in numbers -> put(key, (value as? Number)?.takeIf { it.toDouble().isFinite() })
            key in flags -> put(key, value as? Boolean)
            key in setOf("phase", "reason", "stage", "controller", "mode", "owner", "kind") -> put(key, (value as? String)?.takeIf { it in words })
        }
    }
    fun event(envelope: BridgeEnvelope): String = JSONObject(mapOf("type" to envelope.type, "sequence" to envelope.sequence, "timestamp" to (envelope.timestamp.takeIf { runCatching { java.time.Instant.parse(it) }.isSuccess }),
        "payload" to JSONObject(project(envelope.payload)))).toString()
    fun hook(payload: Map<String, Any?>): Map<String, Any?> = mapOf<String, Any?>(
        "socketOpenAtMs" to null, "firstFrameAtMs" to null, "firstDecodedAtMs" to null,
        "completedAtMs" to null, "disconnectToDecodedMs" to null, "connectToDecodedMs" to null) + project(payload)
}
