package app.tiktoklivecompanion

import android.util.Base64
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class CompanionUiState(
    val tab: CompanionTab = CompanionTab.SONG,
    val source: RecognitionSource = RecognitionSource.MICROPHONE,
    val recognitionStatus: String = "Bereit für manuelle Erkennung",
    val result: RecognitionResult? = null,
    val connected: Boolean = false,
    val hookAvailable: Boolean = false,
    val captionsAvailable: Boolean = false,
    val chats: List<String> = emptyList(),
    val chatEntries: List<ChatLine> = emptyList(),
    val liveValues: Map<String, String> = emptyMap(),
    val chatterCounts: Map<String, Int> = emptyMap(),
    val pageInfo: Map<String, String> = emptyMap(),
    val mutedAuthors: Set<String> = emptySet(),
    val limiterEnabled: Boolean = false,
    val limiterThreshold: Int = -6,
    val ttsEnabled: Boolean = false,
    val ttsVolume: Int = 100,
    val ttsLanguage: TtsLanguage = TtsLanguage.AUTO,
    val ttsSpeakNames: Boolean = true,
    val ttsShortenNames: Boolean = true,
    val speechQueue: List<SpeechRequest> = emptyList(),
    val error: String? = null,
    val videoExpanded: Boolean = false,
    val streamName: String = ""
) {
    val topChatters: List<Pair<String, Int>>
        get() = chatterCounts.entries.sortedWith(compareByDescending<Map.Entry<String, Int>> { it.value }.thenBy { it.key }).take(5).map { it.key to it.value }
}

class CompanionViewModel(private val recognizer: RecognitionEngine, private val preferences: CompanionPreferences? = null) : ViewModel() {
    private val mutable = MutableStateFlow(CompanionUiState())
    val state: StateFlow<CompanionUiState> = mutable
    var sendCommand: ((String, Map<String, Any>) -> Unit)? = null
    var loadUrl: ((String) -> Unit)? = null
    private var speechSequence = 0L

    private companion object {
        val liveStatLabels = mapOf(
            "viewerCount" to "Zuschauer*innen",
            "totalViewers" to "Aufrufe gesamt",
            "likeCount" to "Likes",
            "followerCount" to "Follower gesamt",
            "shareCount" to "Teilungen"
        )
    }

    init {
        recognizer.onResult = { result -> mutable.update { it.copy(result = result, recognitionStatus = if (result.matched) "Song erkannt" else "Kein passender Song erkannt") } }
        recognizer.onError = { message -> mutable.update { it.copy(error = message, recognitionStatus = message) } }
        preferences?.let { stored ->
            viewModelScope.launch { stored.source.collectLatest { source -> mutable.update { it.copy(source = source) } } }
            viewModelScope.launch { stored.mutedAuthors.collectLatest { authors -> mutable.update { it.copy(mutedAuthors = authors) } } }
            viewModelScope.launch { stored.limiterEnabled.collectLatest { enabled -> mutable.update { it.copy(limiterEnabled = enabled) } } }
            viewModelScope.launch { stored.limiterThreshold.collectLatest { threshold -> mutable.update { it.copy(limiterThreshold = threshold) } } }
            viewModelScope.launch { stored.ttsEnabled.collectLatest { value -> mutable.update { it.copy(ttsEnabled = value) } } }
            viewModelScope.launch { stored.ttsVolume.collectLatest { value -> mutable.update { it.copy(ttsVolume = value) } } }
            viewModelScope.launch { stored.ttsLanguage.collectLatest { value -> mutable.update { it.copy(ttsLanguage = value) } } }
            viewModelScope.launch { stored.ttsSpeakNames.collectLatest { value -> mutable.update { it.copy(ttsSpeakNames = value) } } }
            viewModelScope.launch { stored.ttsShortenNames.collectLatest { value -> mutable.update { it.copy(ttsShortenNames = value) } } }
        }
    }

    fun selectTab(tab: CompanionTab) = mutable.update { it.copy(tab = tab) }
    fun selectSource(source: RecognitionSource) {
        mutable.update { it.copy(source = source) }
        preferences?.let { stored -> viewModelScope.launch { stored.setSource(source) } }
    }
    fun clearError() = mutable.update { it.copy(error = null) }
    fun toggleVideoExpanded() = mutable.update { it.copy(videoExpanded = !it.videoExpanded) }
    fun setStreamName(name: String) = mutable.update { it.copy(streamName = name) }
    fun openStream() {
        val url = StreamNameNormalizer.liveUrl(mutable.value.streamName)
        if (url == null) { reportError("Ungültiger Streamname · erlaubt sind Buchstaben, Ziffern, Punkt und Unterstrich"); return }
        mutable.update { it.copy(connected = false, hookAvailable = false, captionsAvailable = false, chats = emptyList(), chatEntries = emptyList(), speechQueue = emptyList(), liveValues = emptyMap(), chatterCounts = emptyMap(), pageInfo = emptyMap()) }
        loadUrl?.invoke(url)
    }
    fun reportError(message: String) = mutable.update { it.copy(error = message, recognitionStatus = message) }
    fun muteAuthor(author: String) {
        val normalized = author.trim().take(80)
        if (normalized.isEmpty()) return
        val updated = mutable.value.mutedAuthors + normalized
        mutable.update { it.copy(mutedAuthors = updated, chats = it.chats.filterNot { line -> line.startsWith("$normalized:") }, chatEntries = it.chatEntries.filterNot { line -> line.author == normalized }, chatterCounts = it.chatterCounts - normalized) }
        preferences?.let { stored -> viewModelScope.launch { stored.setMutedAuthors(updated) } }
    }
    fun setLimiterEnabled(enabled: Boolean) {
        mutable.update { it.copy(limiterEnabled = enabled) }
        preferences?.let { stored -> viewModelScope.launch { stored.setLimiterEnabled(enabled) } }
        pushLimiter()
    }
    fun setLimiterThreshold(threshold: Int) {
        val clamped = threshold.coerceIn(-30, -1)
        mutable.update { it.copy(limiterThreshold = clamped) }
        preferences?.let { stored -> viewModelScope.launch { stored.setLimiterThreshold(clamped) } }
        pushLimiter()
    }
    fun setTtsEnabled(enabled: Boolean) { mutable.update { it.copy(ttsEnabled = enabled) }; preferences?.let { stored -> viewModelScope.launch { stored.setTtsEnabled(enabled) } } }
    fun setTtsVolume(volume: Int) { val value = volume.coerceIn(0, 100); mutable.update { it.copy(ttsVolume = value) }; preferences?.let { stored -> viewModelScope.launch { stored.setTtsVolume(value) } } }
    fun setTtsLanguage(language: TtsLanguage) { mutable.update { it.copy(ttsLanguage = language) }; preferences?.let { stored -> viewModelScope.launch { stored.setTtsLanguage(language) } } }
    fun setTtsSpeakNames(enabled: Boolean) { mutable.update { it.copy(ttsSpeakNames = enabled) }; preferences?.let { stored -> viewModelScope.launch { stored.setTtsSpeakNames(enabled) } } }
    fun setTtsShortenNames(enabled: Boolean) { mutable.update { it.copy(ttsShortenNames = enabled) }; preferences?.let { stored -> viewModelScope.launch { stored.setTtsShortenNames(enabled) } } }
    fun requestSpeak(line: ChatLine) = enqueueSpeech(line)
    fun consumeSpeech(id: Long) = mutable.update { it.copy(speechQueue = it.speechQueue.filterNot { request -> request.id == id }) }
    private fun enqueueSpeech(line: ChatLine) {
        val current = mutable.value
        val author = if (current.ttsShortenNames) line.author.take(24) else line.author
        val spoken = if (current.ttsSpeakNames && author.isNotBlank()) "$author sagt ${line.content}" else line.content
        val languageTag = current.ttsLanguage.tag ?: when (line.language.lowercase()) { "de", "de-de" -> "de-DE"; "en", "en-us", "en-gb" -> "en-US"; else -> null }
        val request = SpeechRequest(++speechSequence, spoken.take(1_000), languageTag)
        mutable.update { it.copy(speechQueue = (it.speechQueue + request).takeLast(5)) }
    }
    private fun pushLimiter() {
        val current = mutable.value
        sendCommand?.invoke("set-limiter", mapOf("enabled" to current.limiterEnabled, "threshold" to current.limiterThreshold))
    }
    fun recognize() {
        mutable.update { it.copy(result = null, error = null, recognitionStatus = "Erkennung läuft · maximal 12 Sekunden") }
        if (mutable.value.source == RecognitionSource.MICROPHONE) recognizer.recognizeMicrophone()
        else { recognizer.startPcmStream(); sendCommand?.invoke("start-webview-audio", emptyMap()) }
    }

    fun handle(envelope: BridgeEnvelope) {
        mutable.update { it.copy(connected = true) }
        when (envelope.type) {
            "bridge-ready" -> pushLimiter()
            "capability" -> {
                val feature = envelope.payload["feature"] as? String
                val available = envelope.payload["available"] as? Boolean ?: false
                if (feature == "websocket-hook") mutable.update { it.copy(hookAvailable = available || it.hookAvailable) }
                if (feature == "webview-audio" && !available && mutable.value.source == RecognitionSource.WEBVIEW) {
                    recognizer.cancel(); mutable.update { it.copy(recognitionStatus = "WebView-Audio nicht verfügbar · Mikrofon wählen") }
                }
                if (feature == "limiter" && !available) mutable.update { it.copy(error = "Pegelschutz nicht verfügbar · Player oder Web Audio fehlt") }
            }
            "inspection" -> {
                val info = buildMap {
                    (envelope.payload["title"] as? String)?.takeIf { it.isNotBlank() }?.let { put("Titel", it) }
                    (envelope.payload["url"] as? String)?.takeIf { it.isNotBlank() }?.let { put("URL", it) }
                    put("Video vorhanden", if (envelope.payload["videoPresent"] as? Boolean == true) "ja" else "nein")
                    put("Untertitel-Steuerung", if (envelope.payload["captionsControlPresent"] as? Boolean == true) "ja" else "nein")
                }
                mutable.update { it.copy(captionsAvailable = envelope.payload["captionsControlPresent"] as? Boolean ?: false, pageInfo = info) }
            }
            "chat" -> {
                val author = envelope.payload["nickname"] as? String ?: ""
                val content = envelope.payload["content"] as? String ?: ""
                val language = envelope.payload["language"] as? String ?: ""
                if (author in mutable.value.mutedAuthors) return
                val entry = ChatLine(author.take(128), content.take(1_000), language.take(24))
                val line = entry.visibleText
                mutable.update { current ->
                    val counts = if (author.isBlank()) current.chatterCounts else current.chatterCounts + (author to (current.chatterCounts[author] ?: 0) + 1)
                    current.copy(chats = (current.chats + line).takeLast(50), chatEntries = (current.chatEntries + entry).takeLast(50), chatterCounts = counts)
                }
                if (mutable.value.ttsEnabled) enqueueSpeech(entry)
            }
            "live-stats" -> mutable.update { current ->
                val mapped = buildMap {
                    for ((key, label) in liveStatLabels) {
                        val value = envelope.payload[key] ?: continue
                        val textValue = value.toString().takeIf { it.isNotBlank() } ?: continue
                        put(label, textValue)
                    }
                    if ((envelope.payload["kind"] as? String) == "follow") put("Follows seit Start", ((current.liveValues["Follows seit Start"]?.toIntOrNull() ?: 0) + 1).toString())
                }
                current.copy(liveValues = current.liveValues + mapped)
            }
            "audio-chunk" -> {
                val encoded = envelope.payload["data"] as? String ?: return
                val sampleRate = (envelope.payload["sampleRate"] as? Number)?.toInt() ?: 48_000
                runCatching { Base64.decode(encoded, Base64.DEFAULT) }.getOrNull()?.let { recognizer.appendPcm16(it, sampleRate) }
            }
            "audio-complete" -> recognizer.finishPcmStream()
            "force-return" -> {
                val ok = envelope.payload["ok"] as? Boolean
                if (ok == false) mutable.update { it.copy(error = "Force: automatische Rückkehr zum LIVE-Stream fehlgeschlagen · bitte manuell zurück") }
            }
            "bridge-error" -> mutable.update { it.copy(error = envelope.payload["message"] as? String ?: "WebView-Bridge-Fehler") }
        }
    }

    override fun onCleared() { recognizer.cancel(); super.onCleared() }
}
