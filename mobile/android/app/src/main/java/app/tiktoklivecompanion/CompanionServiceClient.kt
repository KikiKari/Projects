package app.tiktoklivecompanion

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.File
import java.util.UUID
import java.time.Instant

class CompanionServiceClient(context: Context) {
    private val root = File(context.filesDir, "pipeline-outbox").apply { mkdirs() }
    private val preferences = context.getSharedPreferences("pipeline-client", Context.MODE_PRIVATE)
    private val clientId = preferences.getString("clientId", null) ?: UUID.randomUUID().toString().also { preferences.edit().putString("clientId", it).apply() }
    private val sessionId = UUID.randomUUID().toString()
    private val tabId = UUID.randomUUID().toString()
    private val mutex = Mutex()
    private val flushMutex = Mutex()
    private val registeredDocuments = mutableSetOf<String>()
    private var currentDocument = sessionId
    private val http = OkHttpClient.Builder().followRedirects(false).followSslRedirects(false).build()
    var baseUrl: String
        get() = preferences.getString("baseUrl", "") ?: ""
        set(value) { preferences.edit().putString("baseUrl", value.trim()).apply() }
    var pairingCode = ""
    var universalKey = ""
    var auddToken = ""
    suspend fun publishData(pipeline: String, data: Map<String, Any?>, documentId: String = currentDocument) {
        capture(BridgeEnvelope(1, "pipeline-snapshot", "companion", 0, Instant.now().toString(), mapOf("pipeline" to pipeline, "data" to data, "documentId" to documentId)))
    }
    suspend fun request(route: String, body: JSONObject? = null): ByteArray = withContext(Dispatchers.IO) {
        val uri = java.net.URI(baseUrl)
        require(uri.scheme == "https" && uri.host != null && uri.userInfo == null && uri.rawQuery == null) { "Companion-Dienst benötigt eine HTTPS-Adresse" }
        val builder = Request.Builder().url(baseUrl.trimEnd('/') + route).header("Authorization", "Bearer $pairingCode")
        if (body != null) builder.post(body.toString().toRequestBody("application/json".toMediaType()))
        http.newCall(builder.build()).execute().use { response ->
            check(response.isSuccessful) { "Companion-Dienst HTTP ${response.code}" }
            response.body?.bytes() ?: byteArrayOf()
        }
    }
    suspend fun capture(envelope: BridgeEnvelope) = withContext(Dispatchers.IO) {
        if (universalKey.isBlank()) return@withContext
        mutex.withLock {
            val document = envelope.payload["documentId"] as? String ?: currentDocument
            if (envelope.type == "bridge-ready") currentDocument = document
            val pipeline = when(envelope.type) {
                "pipeline-record", "pipeline-snapshot" -> envelope.payload["pipeline"] as? String ?: "debug-logs"
                "caption" -> "title"
                "chat" -> "chat"
                "live-stats" -> "live"
                "page-info", "inspection" -> "profile"
                "media-links", "media-url" -> "media-links"
                "pipeline-document" -> "browser-tab"
                else -> "debug-logs"
            }
            val raw = JSONObject(mapOf("type" to envelope.type, "payload" to envelope.payload, "sequence" to envelope.sequence))
            val initial = if (registeredDocuments.add(document)) listOf("title", "chat", "speech-service", "sherpa", "top-chatters", "profile", "live", "songs", "media-links", "live-logs", "debug-logs", "browser-tab").filter { it != pipeline && it != "debug-logs" && !(pipeline == "title" && it == "live-logs") } else emptyList()
            val types = (initial + listOf(pipeline, "debug-logs") + if (pipeline == "title") listOf("live-logs") else emptyList()).distinct()
            for (type in types) {
                val id = UUID.randomUUID().toString()
                val sourceSequence = preferences.getLong("sequence", 0L) + 1
                preferences.edit().putLong("sequence", sourceSequence).commit()
                val event = JSONObject().put("eventId", id).put("clientId", clientId).put("sessionId", sessionId).put("tabId", tabId)
                    .put("sourceSequence", sourceSequence)
                    .put("documentId", document).put("pipeline", type)
                    .put("capturedAt", Instant.now().toString()).put("availability", if (type in initial) "unavailable" else "available").put("source", "android-webview-bridge")
                    .put("structured", if (type in initial) JSONObject().put("reason", "not-yet-observed") else raw).put("raw", if (type in initial) JSONObject.NULL else raw)
                var encoded = event.toString()
                for (secret in listOf(pairingCode, universalKey, auddToken).filter { it.isNotEmpty() }) encoded = encoded.replace(secret, "[credential removed]")
                val file = File(root, "$id.json")
                val sanitized = JSONObject(encoded).put("credentialsRedacted", encoded != event.toString())
                val temporary = File(root, "$id.tmp")
                temporary.writeText(sanitized.toString())
                check(temporary.renameTo(file)) { "Pipeline konnte nicht gespeichert werden" }
            }
        }
        flush()
    }
    private suspend fun flushLocked() {
        if (baseUrl.isBlank() || pairingCode.isBlank() || universalKey.isBlank()) return
        request("/v1/pipelines/key", JSONObject().put("key", universalKey))
        for (file in root.listFiles().orEmpty().filter { it.extension == "json" }.sortedBy { JSONObject(it.readText()).optLong("sourceSequence") }) {
            request("/v1/pipelines/events", JSONObject(file.readText()))
            check(file.delete()) { "Pipeline-Bestätigung konnte nicht gespeichert werden" }
        }
    }
    suspend fun flush() = withContext(Dispatchers.IO) {
        if (!flushMutex.tryLock()) return@withContext
        try { flushLocked() } finally { flushMutex.unlock() }
    }
}
