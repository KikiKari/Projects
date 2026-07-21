package app.tiktoklivecompanion

import android.net.Uri
import org.json.JSONObject

object BridgeValidator {
    const val ALLOWED_ORIGIN = "https://www.tiktok.com"
    const val MAX_BYTES = 64 * 1024
    private val allowedTypes = setOf("bridge-ready", "inspection", "capability", "chat", "caption", "live-stats", "gift", "bridge-error", "command-result", "audio-chunk", "audio-complete", "socket-open", "force-start", "force-return", "player-state", "media-url")

    // Subframes derselben Origin sind erlaubt: TikTok kann den Webcast-WebSocket in einem Same-Origin-Iframe öffnen (0PE-52).
    fun decode(raw: String, origin: String, isMainFrame: Boolean = true): BridgeEnvelope? {
        if (origin != ALLOWED_ORIGIN || raw.toByteArray().size > MAX_BYTES) return null
        return runCatching {
            val json = JSONObject(raw)
            val type = json.getString("type")
            if (json.getInt("version") != 1 || type !in allowedTypes) return null
            val payloadJson = json.optJSONObject("payload") ?: JSONObject()
            val payload = payloadJson.keys().asSequence().associateWith { key -> payloadJson.opt(key).takeUnless { it === JSONObject.NULL } }
            BridgeEnvelope(1, type, json.optString("streamId"), json.getLong("sequence"), json.getString("timestamp"), payload)
        }.getOrNull()
    }

    fun safeHttpsUrl(value: String?): Uri? = value?.let(Uri::parse)?.takeIf { it.scheme == "https" && !it.host.isNullOrBlank() }
}
