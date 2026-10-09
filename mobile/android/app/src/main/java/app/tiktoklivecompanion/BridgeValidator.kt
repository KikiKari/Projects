package app.tiktoklivecompanion

import android.net.Uri
import org.json.JSONObject

object BridgeValidator {
    const val ALLOWED_ORIGIN = "https://www.tiktok.com"
    const val MAX_BYTES = 64 * 1024
    private val allowedTypes = setOf("pipeline-record", "recovery-ready", "hook-status", "hook-recovery", "socket-telemetry", "caption-state", "player-recovery", "player-observation", "embed-blocked", "bridge-ready", "inspection", "capability", "chat", "caption", "live-stats", "gift", "media-links", "media-url", "quick-recover", "limiter", "bridge-error", "command-result", "audio-chunk", "audio-complete", "socket-open", "force-start", "force-return", "player-state", "recommendation-scan-progress")

    fun decode(raw: String, origin: String, isMainFrame: Boolean): BridgeEnvelope? {
        if (origin != ALLOWED_ORIGIN || raw.toByteArray().size > MAX_BYTES) return null
        return runCatching {
            val json = JSONObject(raw)
            val type = json.getString("type")
            if (json.getInt("version") != 1 || type !in allowedTypes) return null
            val payloadJson = json.optJSONObject("payload") ?: JSONObject()
            val payload = payloadJson.keys().asSequence().associateWith { key -> convert(payloadJson.opt(key)) }
            BridgeEnvelope(1, type, json.optString("streamId"), json.getLong("sequence"), json.getString("timestamp"), payload)
        }.getOrNull()
    }

    private fun convert(value: Any?): Any? = when (value) {
        JSONObject.NULL -> null
        is JSONObject -> value.keys().asSequence().associateWith { convert(value.opt(it)) }
        is org.json.JSONArray -> (0 until value.length()).map { convert(value.opt(it)) }
        else -> value
    }

    fun safeHttpsUrl(value: String?): Uri? = value?.let(Uri::parse)?.takeIf { it.scheme == "https" && !it.host.isNullOrBlank() }
}
