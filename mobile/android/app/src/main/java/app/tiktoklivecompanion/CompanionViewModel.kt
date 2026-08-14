package app.tiktoklivecompanion

import android.util.Base64
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
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
    val chatEntries: List<ChatLine> = emptyList(),
    val liveValues: Map<String, String> = emptyMap(),
    val participants: Map<String, ParticipantStats> = emptyMap(),
    val liveNumbers: Map<String, Long> = emptyMap(),
    val pageInfo: Map<String, String> = emptyMap(),
    val mutedAuthors: Set<String> = emptySet(),
    val limiterEnabled: Boolean = false,
    val limiterThreshold: Int = -6,
    val limiterStrength: Int = 30,
    val ttsEnabled: Boolean = false,
    val ttsVolume: Int = 100,
    val ttsLanguage: TtsLanguage = TtsLanguage.AUTO,
    val ttsSpeakNames: Boolean = true,
    val ttsShortenNames: Boolean = true,
    val speechQueue: List<SpeechRequest> = emptyList(),
    val error: String? = null,
    val videoExpanded: Boolean = false,
    val forceInProgress: Boolean = false,
    val forceRecoveryUrl: String? = null,
    val audibleStartRequested: Boolean = false,
    val playerMuted: Boolean? = null,
    val audibleStartBlocked: Boolean = false,
    val mediaUrls: List<StreamMediaUrl> = emptyList(),
    val vlcReplacementUrl: String? = null,
    val debugEnabled: Boolean = false,
    val debugEvents: List<String> = emptyList(),
    val streamName: String = "",
    val autoReconnectEnabled: Boolean = true,
    val autoReconnectDelaySeconds: Int = 3,
    val gameModeEnabled: Boolean = true,
    val auddToken: String = "",
    val pairingCode: String = "",
    val universalCaptionApiKey: String = "",
    val ttsVoice: String = "Systemstandard",
    val captionRecords: List<CaptionRecord> = emptyList(),
    val recommendationStatus: String = "idle",
    val recommendationLimit: Int = 20,
    val recommendationScanned: Int = 0,
    val recommendationItems: List<RecommendationItem> = emptyList()
) {
    val topChatters: List<TopChatter>
        get() = participants.entries.sortedWith(compareByDescending<Map.Entry<String, ParticipantStats>> { it.value.messages }.thenByDescending { it.value.words }.thenBy { it.key.lowercase() }).map { TopChatter(it.key, it.value.messages, it.value.words) }
}

class CompanionViewModel(private val recognizer: RecognitionEngine, private val preferences: CompanionPreferences? = null) : ViewModel() {
    private val mutable = MutableStateFlow(CompanionUiState())
    val state: StateFlow<CompanionUiState> = mutable
    var sendCommand: ((String, Map<String, Any>) -> Unit)? = null
    var loadUrl: ((String) -> Unit)? = null
    var backgroundPlaybackChanged: ((Boolean) -> Unit)? = null
    var currentWebUrl: String = "https://www.tiktok.com/live"
        private set
    private var speechSequence = 0L
    private var forceWatchdog: Job? = null
    private val recentSpeech = LinkedHashMap<String, Long>()
    private val repeatWindowMs = 20_000L

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
            viewModelScope.launch { stored.autoReconnect.collectLatest { value -> mutable.update { it.copy(autoReconnectEnabled = value) } } }
            viewModelScope.launch { stored.autoReconnectDelay.collectLatest { value -> mutable.update { it.copy(autoReconnectDelaySeconds = value) } } }
            viewModelScope.launch { stored.auddToken.collectLatest { value -> mutable.update { it.copy(auddToken = value) } } }
            viewModelScope.launch { stored.pairingCode.collectLatest { value -> mutable.update { it.copy(pairingCode = value) } } }
            viewModelScope.launch { stored.universalCaptionApiKey.collectLatest { value -> mutable.update { it.copy(universalCaptionApiKey = value) } } }
            viewModelScope.launch { stored.gameMode.collectLatest { value -> mutable.update { it.copy(gameModeEnabled = value) } } }
            viewModelScope.launch { stored.ttsVoice.collectLatest { value -> mutable.update { it.copy(ttsVoice = value) } } }
        }
    }

    fun selectTab(tab: CompanionTab) = mutable.update { it.copy(tab = tab) }
    fun selectSource(source: RecognitionSource) {
        mutable.update { it.copy(source = source) }
        preferences?.let { stored -> viewModelScope.launch { stored.setSource(source) } }
    }
    fun clearError() = mutable.update { it.copy(error = null) }
    fun setDebugEnabled(enabled: Boolean) = mutable.update { it.copy(debugEnabled = enabled) }
    fun clearDebugEvents() = mutable.update { it.copy(debugEvents = emptyList()) }
    fun debugReport(vlcInstalled: Boolean): String {
        val current = mutable.value
        return JSONObject(mapOf(
            "generatedAtUtc" to java.time.Instant.now().toString(),
            "version" to "0.8.0",
            "platform" to "android",
            "components" to mapOf(
                "layout" to mapOf("liveInformationBeforePageInformation" to true),
                "vlcReplacement" to mapOf("placement" to "main-video-frame", "installed" to vlcInstalled, "active" to (current.vlcReplacementUrl != null), "candidateCount" to current.mediaUrls.size),
                "speechAndChatSettings" to mapOf("settingsDialogAvailable" to true, "auddTokenConfigured" to current.auddToken.isNotBlank(), "pairingConfigured" to current.pairingCode.isNotBlank(), "universalCaptionApiKeyConfigured" to current.universalCaptionApiKey.isNotBlank(), "speakNames" to current.ttsSpeakNames, "shortenNames" to current.ttsShortenNames, "gameModeEnabled" to current.gameModeEnabled, "language" to current.ttsLanguage.name, "voice" to current.ttsVoice),
                "captions" to mapOf("rawBridgeStreamCaptured" to true, "available" to current.captionsAvailable, "eventCount" to current.captionRecords.size, "jsonLinesExportAvailable" to true, "rawJsonExportAvailable" to true),
                "songRecognition" to mapOf("path" to "android-native-audd-microphone-or-webview", "source" to current.source.label),
                "topChatters" to mapOf("observedCount" to current.participants.size, "mutedCount" to current.mutedAuthors.size, "resetAvailable" to true),
                "recommendations" to mapOf("available" to true, "status" to current.recommendationStatus, "requested" to current.recommendationLimit, "scanned" to current.recommendationScanned, "found" to current.recommendationItems.size),
                "autoReconnect" to mapOf("enabled" to current.autoReconnectEnabled, "delaySeconds" to current.autoReconnectDelaySeconds)
            ),
            "raw" to mapOf(
                "connected" to current.connected,
                "hookAvailable" to current.hookAvailable,
                "captionsAvailable" to current.captionsAvailable,
                "pageInformation" to current.pageInfo,
                "liveInformation" to current.liveValues,
                "chat" to current.chats,
                "participants" to current.participants.mapValues { mapOf("messages" to it.value.messages, "words" to it.value.words) },
                "mutedAuthors" to current.mutedAuthors.toList(),
                "mediaUrls" to current.mediaUrls.map { mapOf("url" to it.url, "kind" to it.kind) },
                "bridgeEvents" to JSONArray(current.debugEvents),
                "captionProtocol" to JSONArray(current.captionRecords.map { JSONObject(it.rawJson) }),
                "recommendations" to JSONArray(current.recommendationItems.map { JSONObject(mapOf("handle" to it.handle, "displayName" to it.displayName, "title" to it.title, "viewerCount" to it.viewerCount, "viewerLabel" to it.viewerLabel, "url" to it.url, "position" to it.position)) })
            )
        )).toString(2)
    }
    fun setGameMode(enabled: Boolean) { mutable.update { it.copy(gameModeEnabled = enabled) }; preferences?.let { stored -> viewModelScope.launch { stored.setGameMode(enabled) } } }
    fun setAuddToken(value: String) { val safe = value.take(4096); mutable.update { it.copy(auddToken = safe) }; preferences?.let { stored -> viewModelScope.launch { stored.setAuddToken(safe) } } }
    fun setPairingCode(value: String) { val safe = value.take(512); mutable.update { it.copy(pairingCode = safe) }; preferences?.let { stored -> viewModelScope.launch { stored.setPairingCode(safe) } } }
    fun setUniversalCaptionApiKey(value: String) { val safe = value.take(4096); mutable.update { it.copy(universalCaptionApiKey = safe) }; preferences?.let { stored -> viewModelScope.launch { stored.setUniversalCaptionApiKey(safe) } } }
    fun setTtsVoice(value: String) { val safe = value.take(160); mutable.update { it.copy(ttsVoice = safe) }; preferences?.let { stored -> viewModelScope.launch { stored.setTtsVoice(safe) } } }
    fun resetTopChatters() = mutable.update { it.copy(participants = emptyMap()) }
    fun toggleVideoExpanded() {
        val expanded = !mutable.value.videoExpanded
        mutable.update { it.copy(videoExpanded = expanded) }
        sendCommand?.invoke("set-player-expanded", mapOf("expanded" to expanded))
    }
    fun toggleVlcReplacement() {
        val next = if (mutable.value.vlcReplacementUrl != null) null else bestMediaUrl(mutable.value.mediaUrls)?.url
        if (next == null && mutable.value.vlcReplacementUrl == null) { reportError("Keine Media-URL verfügbar"); return }
        mutable.update { it.copy(vlcReplacementUrl = next, videoExpanded = false) }
    }
    fun bestVlcMediaUrl(): String? = bestMediaUrl(mutable.value.mediaUrls)?.url
    fun expandVideo() {
        if (mutable.value.videoExpanded) return
        mutable.update { it.copy(videoExpanded = true) }
        sendCommand?.invoke("set-player-expanded", mapOf("expanded" to true))
    }
    fun setStreamName(name: String) = mutable.update { it.copy(streamName = name) }
    fun startForce() {
        val recovery = mutable.value.pageInfo["URL"]?.takeIf { it.matches(Regex("https://www\\.tiktok\\.com/@[^/]+/live(?:[/?#].*)?")) }
            ?: StreamNameNormalizer.liveUrl(mutable.value.streamName)
        if (recovery == null) { reportError("Force ist erst in einem gültigen LIVE-Stream verfügbar"); return }
        forceWatchdog?.cancel()
        mutable.update { it.copy(forceInProgress = true, forceRecoveryUrl = recovery, error = null) }
        sendCommand?.invoke("force-profile", mapOf("liveUrl" to recovery))
        forceWatchdog = viewModelScope.launch {
            delay(20_000)
            if (mutable.value.forceInProgress) recoverForce("Timeout nach 20 Sekunden")
        }
    }
    fun recoverForce(reason: String = "manuelle Rückkehr") {
        val recovery = mutable.value.forceRecoveryUrl
        forceWatchdog?.cancel()
        mutable.update { it.copy(forceInProgress = false, error = if (recovery == null) "Force: $reason · bitte manuell zurück" else "Force: $reason · LIVE-Stream wurde wieder geöffnet") }
        recovery?.let { currentWebUrl = it; loadUrl?.invoke(it) }
    }
    fun noteNavigation(url: String) {
        if (url.matches(Regex("https://www\\.tiktok\\.com/@[^/]+/live(?:[/?#].*)?"))) currentWebUrl = url
    }
    fun openStream() {
        val url = StreamNameNormalizer.liveUrl(mutable.value.streamName)
        if (url == null) { reportError("Ungültiger Streamname · erlaubt sind Buchstaben, Ziffern, Punkt und Unterstrich"); return }
        mutable.update { it.copy(connected = false, hookAvailable = false, captionsAvailable = false, chats = emptyList(), chatEntries = emptyList(), speechQueue = emptyList(), liveValues = emptyMap(), liveNumbers = emptyMap(), participants = emptyMap(), pageInfo = emptyMap(), audibleStartRequested = true, playerMuted = null, audibleStartBlocked = false, mediaUrls = emptyList(), vlcReplacementUrl = null, captionRecords = emptyList(), recommendationStatus = "idle", recommendationScanned = 0, recommendationItems = emptyList()) }
        backgroundPlaybackChanged?.invoke(true)
        currentWebUrl = url
        loadUrl?.invoke(url)
    }
    fun enableStreamSound() {
        mutable.update { it.copy(audibleStartRequested = true, audibleStartBlocked = false) }
        sendCommand?.invoke("start-audible", emptyMap())
    }
    fun reportError(message: String) = mutable.update { it.copy(error = message, recognitionStatus = message) }
    fun muteAuthor(author: String) {
        val normalized = author.trim().take(80)
        if (normalized.isEmpty()) return
        val updated = mutable.value.mutedAuthors + normalized
        mutable.update { it.copy(mutedAuthors = updated, chats = it.chats.filterNot { line -> line.startsWith("$normalized:") }, chatEntries = it.chatEntries.filterNot { line -> line.author == normalized }, participants = it.participants - normalized) }
        preferences?.let { stored -> viewModelScope.launch { stored.setMutedAuthors(updated) } }
    }
    fun setLimiterEnabled(enabled: Boolean) {
        mutable.update { it.copy(limiterEnabled = enabled) }
        preferences?.let { stored -> viewModelScope.launch { stored.setLimiterEnabled(enabled) } }
        pushLimiter()
    }
    fun setLimiterThreshold(threshold: Int) {
        val clamped = threshold.coerceIn(-30, -1)
        mutable.update { it.copy(limiterThreshold = clamped, limiterStrength = thresholdToStrength(clamped)) }
        preferences?.let { stored -> viewModelScope.launch { stored.setLimiterThreshold(clamped) } }
        pushLimiter()
    }
    fun setLimiter(enabled: Boolean, strength: Int = mutable.value.limiterStrength) {
        val safeStrength = strength.coerceIn(0, 100)
        val threshold = strengthToThreshold(safeStrength)
        mutable.update { it.copy(limiterEnabled = enabled, limiterStrength = safeStrength, limiterThreshold = threshold) }
        preferences?.let { stored ->
            viewModelScope.launch { stored.setLimiterEnabled(enabled) }
            viewModelScope.launch { stored.setLimiterThreshold(threshold) }
        }
        pushLimiter()
    }
    fun setAutoReconnect(enabled: Boolean) {
        mutable.update { it.copy(autoReconnectEnabled = enabled) }
        preferences?.let { stored -> viewModelScope.launch { stored.setAutoReconnect(enabled) } }
        sendCommand?.invoke("set-auto-reconnect", mapOf("enabled" to enabled, "delaySeconds" to mutable.value.autoReconnectDelaySeconds))
    }
    fun setAutoReconnectDelay(seconds: Int) {
        val safe = seconds.coerceIn(1, 59)
        mutable.update { it.copy(autoReconnectDelaySeconds = safe) }
        preferences?.let { stored -> viewModelScope.launch { stored.setAutoReconnectDelay(safe) } }
        sendCommand?.invoke("set-auto-reconnect", mapOf("enabled" to mutable.value.autoReconnectEnabled, "delaySeconds" to safe))
    }
    fun startRecommendationScan(limit: Int) {
        val safe = limit.coerceIn(1, 50)
        mutable.update { it.copy(recommendationStatus = "running", recommendationLimit = safe, recommendationScanned = 0, recommendationItems = emptyList()) }
        sendCommand?.invoke("scan-recommendations", mapOf("limit" to safe))
    }
    fun cancelRecommendationScan() { sendCommand?.invoke("cancel-recommendation-scan", emptyMap()) }
    fun captionJsonLines(): String = mutable.value.captionRecords.joinToString("\n") { it.rawJson }
    fun captionRawJson(): String = JSONArray(mutable.value.captionRecords.map { JSONObject(it.rawJson) }).toString(2)
    fun clearCaptions() = mutable.update { it.copy(captionRecords = emptyList()) }
    fun setTtsEnabled(enabled: Boolean) { mutable.update { it.copy(ttsEnabled = enabled) }; preferences?.let { stored -> viewModelScope.launch { stored.setTtsEnabled(enabled) } } }
    fun setTtsVolume(volume: Int) { val value = volume.coerceIn(0, 100); mutable.update { it.copy(ttsVolume = value) }; preferences?.let { stored -> viewModelScope.launch { stored.setTtsVolume(value) } } }
    fun setTtsLanguage(language: TtsLanguage) { mutable.update { it.copy(ttsLanguage = language) }; preferences?.let { stored -> viewModelScope.launch { stored.setTtsLanguage(language) } } }
    fun setTtsSpeakNames(enabled: Boolean) { mutable.update { it.copy(ttsSpeakNames = enabled) }; preferences?.let { stored -> viewModelScope.launch { stored.setTtsSpeakNames(enabled) } } }
    fun setTtsShortenNames(enabled: Boolean) { mutable.update { it.copy(ttsShortenNames = enabled) }; preferences?.let { stored -> viewModelScope.launch { stored.setTtsShortenNames(enabled) } } }
    fun requestSpeak(line: ChatLine) = enqueueSpeech(line)
    fun consumeSpeech(id: Long) = mutable.update { it.copy(speechQueue = it.speechQueue.filterNot { request -> request.id == id }) }
    fun spokenLineAllowed(line: String, now: Long = System.currentTimeMillis()): Boolean {
        val normalized = line.lowercase().replace(Regex("\\s+"), " ").trim()
        if (normalized.isEmpty()) return false
        val iterator = recentSpeech.iterator()
        while (iterator.hasNext()) {
            if (now - iterator.next().value > repeatWindowMs) iterator.remove()
        }
        val last = recentSpeech[normalized]
        recentSpeech[normalized] = now
        return last == null || now - last > repeatWindowMs
    }
    private fun enqueueSpeech(line: ChatLine) {
        val current = mutable.value
        val author = if (current.ttsShortenNames) line.author.take(24) else line.author
        val content = if (current.gameModeEnabled) line.content.replace(Regex("\\b[A-ZÄÖÜ]{3}\\b"), "").replace(Regex("\\s+"), " ").trim() else line.content
        val spoken = if (current.ttsSpeakNames && author.isNotBlank()) "$author sagt $content" else content
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
        mutable.update {
            val rawEvent = JSONObject(mapOf("timestamp" to envelope.timestamp, "type" to envelope.type, "streamId" to envelope.streamId, "sequence" to envelope.sequence, "payload" to JSONObject(envelope.payload))).toString()
            val events = if (it.debugEnabled) it.debugEvents + rawEvent else it.debugEvents
            it.copy(connected = true, debugEvents = events)
        }
        when (envelope.type) {
            "bridge-ready" -> {
                pushLimiter()
                sendCommand?.invoke("set-auto-reconnect", mapOf("enabled" to mutable.value.autoReconnectEnabled, "delaySeconds" to mutable.value.autoReconnectDelaySeconds))
                sendCommand?.invoke("set-player-expanded", mapOf("expanded" to mutable.value.videoExpanded))
                if (mutable.value.audibleStartRequested) sendCommand?.invoke("start-audible", emptyMap())
            }
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
                    (envelope.payload["description"] as? String)?.takeIf { it.isNotBlank() }?.let { put("Beschreibung", it) }
                    (envelope.payload["creatorName"] as? String)?.takeIf { it.isNotBlank() }?.let { put("Creator", it) }
                    (envelope.payload["creatorHandle"] as? String)?.takeIf { it.isNotBlank() }?.let { put("Handle", it) }
                    (envelope.payload["followerText"] as? String)?.takeIf { it.isNotBlank() }?.let { put("Follower", it) }
                    (envelope.payload["followingText"] as? String)?.takeIf { it.isNotBlank() }?.let { put("Gefolgt", it) }
                    (envelope.payload["profileLikesText"] as? String)?.takeIf { it.isNotBlank() }?.let { put("Profil-Likes", it) }
                    (envelope.payload["signature"] as? String)?.takeIf { it.isNotBlank() }?.let { put("Bio", it) }
                    (envelope.payload["language"] as? String)?.takeIf { it.isNotBlank() }?.let { put("Seitensprache", it) }
                    put("Verifiziert", if (envelope.payload["verified"] as? Boolean == true) "ja" else "nein")
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
                    val people = LinkedHashMap(current.participants)
                    if (author.isNotBlank() && (people.containsKey(author) || people.size < 5_000)) {
                        val prior = people[author] ?: ParticipantStats()
                        people[author] = prior.copy(messages = prior.messages + 1, words = prior.words + content.trim().split(Regex("\\s+")).count { it.isNotBlank() })
                    }
                    current.copy(chats = (current.chats + line).takeLast(50), chatEntries = (current.chatEntries + entry).takeLast(50), participants = people)
                }
                if (mutable.value.ttsEnabled) enqueueSpeech(entry)
            }
            "caption" -> {
                val contents = envelope.payload["contents"] as? List<*>
                val first = contents?.firstOrNull() as? Map<*, *>
                val language = (first?.get("lang") ?: envelope.payload["language"] ?: "").toString().take(24)
                val value = (first?.get("text") ?: envelope.payload["text"] ?: "").toString().take(4_000)
                val raw = JSONObject(mapOf("timestamp" to envelope.timestamp, "streamId" to envelope.streamId, "sentenceId" to (envelope.payload["sentenceId"] ?: ""), "definite" to (envelope.payload["definite"] ?: false), "language" to language, "text" to value, "payload" to JSONObject(envelope.payload))).toString()
                mutable.update { it.copy(captionRecords = it.captionRecords + CaptionRecord(envelope.timestamp, (envelope.payload["sentenceId"] ?: "").toString().take(64), envelope.payload["definite"] as? Boolean ?: false, language, value, raw)) }
            }
            "recommendation-scan-progress" -> {
                val items = (envelope.payload["items"] as? List<*>)?.mapNotNull { raw ->
                    val item = raw as? Map<*, *> ?: return@mapNotNull null
                    val url = item["url"]?.toString()?.takeIf { BridgeValidator.safeHttpsUrl(it) != null } ?: return@mapNotNull null
                    RecommendationItem(item["handle"]?.toString()?.take(128) ?: return@mapNotNull null, item["displayName"]?.toString()?.take(160) ?: "", item["title"]?.toString()?.take(300) ?: "", (item["viewerCount"] as? Number)?.toLong(), item["viewerLabel"]?.toString()?.take(32) ?: "", url, (item["position"] as? Number)?.toInt() ?: 0)
                } ?: emptyList()
                mutable.update { it.copy(recommendationStatus = envelope.payload["status"]?.toString()?.take(20) ?: "running", recommendationScanned = (envelope.payload["scanned"] as? Number)?.toInt() ?: items.size, recommendationItems = items.distinctBy { item -> item.handle.lowercase() }.take(50)) }
            }
            "live-stats" -> mutable.update { current ->
                val numbers = current.liveNumbers.toMutableMap()
                val mapped = buildMap<String, String> {
                    for ((key, label) in liveStatLabels) {
                        val value = envelope.payload[key] ?: continue
                        val number = value.toString().toDoubleOrNull()?.toLong()
                        if (number != null) {
                            val effective = if (key == "viewerCount") number else maxOf(number, numbers[key] ?: 0)
                            numbers[key] = effective
                            put(label, effective.toString())
                        }
                    }
                    if ((envelope.payload["kind"] as? String) == "follow") put("Follows seit Hook", ((current.liveValues["Follows seit Hook"]?.toIntOrNull() ?: 0) + 1).toString())
                }
                current.copy(liveValues = current.liveValues + mapped, liveNumbers = numbers)
            }
            "audio-chunk" -> {
                val encoded = envelope.payload["data"] as? String ?: return
                val sampleRate = (envelope.payload["sampleRate"] as? Number)?.toInt() ?: 48_000
                runCatching { Base64.decode(encoded, Base64.DEFAULT) }.getOrNull()?.let { recognizer.appendPcm16(it, sampleRate) }
            }
            "audio-complete" -> recognizer.finishPcmStream()
            "force-return" -> {
                val ok = envelope.payload["ok"] as? Boolean
                if (ok == true) { forceWatchdog?.cancel(); mutable.update { it.copy(forceInProgress = false, forceRecoveryUrl = null) } }
                if (ok == false) recoverForce("Bridge-Rückkehr fehlgeschlagen")
            }
            "force-start" -> mutable.update { it.copy(forceInProgress = true, forceRecoveryUrl = (envelope.payload["url"] as? String) ?: it.forceRecoveryUrl) }
            "quick-recover" -> mutable.update { it.copy(liveValues = it.liveValues + ("Auto-Reconnect" to "aktiv")) }
            "player-state" -> mutable.update { it.copy(playerMuted = envelope.payload["muted"] as? Boolean, audibleStartBlocked = envelope.payload["reason"] == "autoplay-blocked") }
            "media-url" -> {
                val safe = BridgeValidator.safeHttpsUrl(envelope.payload["url"] as? String)?.toString() ?: return
                if (!isVlcMediaUrl(safe)) return
                val kind = (envelope.payload["kind"] as? String)?.take(24) ?: "media"
                mutable.update { current ->
                    val next = (current.mediaUrls.filterNot { it.url == safe } + StreamMediaUrl(safe, kind)).takeLast(12)
                    current.copy(mediaUrls = next, vlcReplacementUrl = if (current.vlcReplacementUrl != null) bestMediaUrl(next)?.url else null)
                }
            }
            "bridge-error" -> mutable.update { it.copy(error = envelope.payload["message"] as? String ?: "WebView-Bridge-Fehler") }
        }
    }

    override fun onCleared() { forceWatchdog?.cancel(); recognizer.cancel(); super.onCleared() }

    private fun isVlcMediaUrl(value: String): Boolean = try {
        val uri = java.net.URI(value)
        val host = uri.host?.lowercase() ?: return false
        val allowed = listOf(".tiktokcdn.com", ".tiktokcdn-eu.com", ".tiktokcdn-us.com", ".tiktokcdn-in.com", ".ttlivecdn.com", "cdn.example")
            .any { host == it.removePrefix(".") || host.endsWith(it) }
        val media = "${uri.path.orEmpty()}?${uri.query.orEmpty()}".lowercase()
        uri.scheme == "https" && allowed && (media.contains(".flv") || media.contains(".m3u8") || media.contains("only_audio=1"))
    } catch (_: Exception) { false }

    private fun bestMediaUrl(items: List<StreamMediaUrl>): StreamMediaUrl? =
        items.firstOrNull { it.url.contains(".m3u8", ignoreCase = true) }
            ?: items.firstOrNull { !it.url.contains("only_audio=1", ignoreCase = true) }

    private fun strengthToThreshold(strength: Int): Int = (-4 - (strength.coerceIn(0, 100) * 26 / 100)).coerceIn(-30, -1)
    private fun thresholdToStrength(threshold: Int): Int = (((-threshold.coerceIn(-30, -1) - 4) * 100) / 26).coerceIn(0, 100)
}
