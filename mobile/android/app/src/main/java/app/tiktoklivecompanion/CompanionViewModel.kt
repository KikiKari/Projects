package app.tiktoklivecompanion

import android.util.Base64
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject

data class CompanionUiState(
    val tab: CompanionTab = CompanionTab.SONG,
    val source: RecognitionSource = RecognitionSource.MICROPHONE,
    val recognitionStatus: String = "Bereit für manuelle Erkennung",
    val result: RecognitionResult? = null,
    val connected: Boolean = false,
    val hookAvailable: Boolean = false,
    val captionsAvailable: Boolean = false,
    val chats: List<String> = emptyList(),
    val liveValues: Map<String, String> = emptyMap(),
    val mediaLinks: List<MobileMediaLink> = emptyList(),
    val mutedAuthors: Set<String> = emptySet(),
    val gameModeEnabled: Boolean = true,
    val shortenNames: Boolean = true,
    val keepSpeechActive: Boolean = true,
    val autoReconnectEnabled: Boolean = true,
    val limiterEnabled: Boolean = false,
    val limiterStrength: Int = 30,
    val error: String? = null
)

class CompanionViewModel(private val recognizer: RecognitionEngine, private val preferences: CompanionPreferences? = null) : ViewModel() {
    private val mutable = MutableStateFlow(CompanionUiState())
    val state: StateFlow<CompanionUiState> = mutable
    var sendCommand: ((String, Map<String, Any>) -> Unit)? = null
    private val recentSpeech = LinkedHashMap<String, Long>()
    private val repeatWindowMs = 20_000L

    init {
        recognizer.onResult = { result -> mutable.update { it.copy(result = result, recognitionStatus = if (result.matched) "Song erkannt" else "Kein passender Song erkannt") } }
        recognizer.onError = { message -> mutable.update { it.copy(error = message, recognitionStatus = message) } }
        preferences?.let { stored ->
            viewModelScope.launch { stored.source.collectLatest { source -> mutable.update { it.copy(source = source) } } }
            viewModelScope.launch { stored.mutedAuthors.collectLatest { authors -> mutable.update { it.copy(mutedAuthors = authors) } } }
        }
    }

    fun selectTab(tab: CompanionTab) = mutable.update { it.copy(tab = tab) }
    fun setGameMode(enabled: Boolean) = mutable.update { it.copy(gameModeEnabled = enabled) }
    fun setShortenNames(enabled: Boolean) = mutable.update { it.copy(shortenNames = enabled) }
    fun setKeepSpeechActive(enabled: Boolean) = mutable.update { it.copy(keepSpeechActive = enabled) }
    fun setAutoReconnect(enabled: Boolean) {
        mutable.update { it.copy(autoReconnectEnabled = enabled) }
        sendCommand?.invoke("set-auto-reconnect", mapOf("enabled" to enabled))
    }
    fun setLimiter(enabled: Boolean, strength: Int = mutable.value.limiterStrength) {
        val safeStrength = strength.coerceIn(0, 100)
        mutable.update { it.copy(limiterEnabled = enabled, limiterStrength = safeStrength) }
        sendCommand?.invoke("set-limiter", mapOf("enabled" to enabled, "strength" to safeStrength))
    }
    fun selectSource(source: RecognitionSource) {
        mutable.update { it.copy(source = source) }
        preferences?.let { stored -> viewModelScope.launch { stored.setSource(source) } }
    }
    fun clearError() = mutable.update { it.copy(error = null) }
    fun reportError(message: String) = mutable.update { it.copy(error = message, recognitionStatus = message) }
    fun muteAuthor(author: String) {
        val normalized = author.trim().take(80)
        if (normalized.isEmpty()) return
        val updated = mutable.value.mutedAuthors + normalized
        mutable.update { it.copy(mutedAuthors = updated, chats = it.chats.filterNot { line -> line.startsWith("$normalized:") }) }
        preferences?.let { stored -> viewModelScope.launch { stored.setMutedAuthors(updated) } }
    }
    fun recognize() {
        mutable.update { it.copy(result = null, error = null, recognitionStatus = "Erkennung läuft · maximal 12 Sekunden") }
        if (mutable.value.source == RecognitionSource.MICROPHONE) recognizer.recognizeMicrophone()
        else { recognizer.startPcmStream(); sendCommand?.invoke("start-webview-audio", emptyMap()) }
    }

    fun spokenLineAllowed(line: String, now: Long = System.currentTimeMillis()): Boolean {
        val normalized = line.lowercase().replace(Regex("\\s+"), " ").trim()
        if (normalized.isEmpty()) return false
        val iterator = recentSpeech.iterator()
        while (iterator.hasNext()) {
            if (now - iterator.next().value > repeatWindowMs) iterator.remove()
        }
        val last = recentSpeech[normalized] ?: 0L
        recentSpeech[normalized] = now
        return now - last > repeatWindowMs
    }

    fun handle(envelope: BridgeEnvelope) {
        mutable.update { it.copy(connected = true) }
        when (envelope.type) {
            "capability" -> {
                val feature = envelope.payload["feature"] as? String
                val available = envelope.payload["available"] as? Boolean ?: false
                if (feature == "websocket-hook") mutable.update { it.copy(hookAvailable = available) }
                if (feature == "webview-audio" && !available && mutable.value.source == RecognitionSource.WEBVIEW) {
                    recognizer.cancel(); mutable.update { it.copy(recognitionStatus = "WebView-Audio nicht verfügbar · Mikrofon wählen") }
                }
            }
            "inspection" -> mutable.update { it.copy(captionsAvailable = envelope.payload["captionsControlPresent"] as? Boolean ?: false) }
            "chat" -> {
                val author = envelope.payload["nickname"] as? String ?: ""
                val content = envelope.payload["content"] as? String ?: ""
                if (author in mutable.value.mutedAuthors) return
                val line = if (author.isBlank()) content else "$author: $content"
                mutable.update { it.copy(chats = (it.chats + line).takeLast(50)) }
            }
            "live-stats" -> mutable.update { current -> current.copy(liveValues = current.liveValues + envelope.payload.mapValues { it.value?.toString() ?: "" }) }
            "media-links" -> {
                val rawLinks = envelope.payload["links"]
                val links = when (rawLinks) {
                    is JSONArray -> (0 until rawLinks.length()).mapNotNull { rawLinks.optJSONObject(it) }
                    is List<*> -> rawLinks.mapNotNull { it as? JSONObject }
                    else -> emptyList()
                }.mapNotNull { item ->
                    val url = item.optString("url").takeIf { value -> value.isNotBlank() } ?: return@mapNotNull null
                    val type = item.optString("type").takeIf { value -> value.isNotBlank() } ?: return@mapNotNull null
                    val label = item.optString("label").takeIf { value -> value.isNotBlank() } ?: type
                    if (!url.startsWith("https://")) return@mapNotNull null
                    MobileMediaLink(url = url, type = type, label = label)
                }
                mutable.update { it.copy(mediaLinks = links.take(12)) }
            }
            "quick-recover" -> mutable.update { it.copy(liveValues = it.liveValues + ("Auto-Reconnect" to "aktiv")) }
            "limiter" -> mutable.update { it.copy(liveValues = it.liveValues + ("Pegelschutz" to "${envelope.payload["strength"] ?: it.limiterStrength}%")) }
            "audio-chunk" -> {
                val encoded = envelope.payload["data"] as? String ?: return
                val sampleRate = (envelope.payload["sampleRate"] as? Number)?.toInt() ?: 48_000
                runCatching { Base64.decode(encoded, Base64.DEFAULT) }.getOrNull()?.let { recognizer.appendPcm16(it, sampleRate) }
            }
            "audio-complete" -> recognizer.finishPcmStream()
            "bridge-error" -> mutable.update { it.copy(error = envelope.payload["message"] as? String ?: "WebView-Bridge-Fehler") }
        }
    }

    override fun onCleared() { recognizer.cancel(); super.onCleared() }
}
