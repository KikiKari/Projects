package app.tiktoklivecompanion

enum class CompanionTab(val label: String) { LIVE("Live"), CHAT("Chat"), SONG("Song"), PLAYER("Player"), MORE("Mehr") }
enum class RecognitionSource(val label: String) { MICROPHONE("Mikrofon"), WEBVIEW("WebView (experimentell)") }
enum class TtsLanguage(val label: String, val tag: String?) { AUTO("Auto", null), GERMAN("Deutsch", "de-DE"), ENGLISH("Englisch", "en-US") }

data class ChatLine(val author: String, val content: String, val language: String = "") {
    val visibleText: String get() = if (author.isBlank()) content else "$author: $content"
}

data class ParticipantStats(val messages: Int = 0, val words: Int = 0)
data class TopChatter(val author: String, val messages: Int, val words: Int)
data class SpeechRequest(val id: Long, val text: String, val languageTag: String?)
data class StreamMediaUrl(val url: String, val kind: String)

data class RecognitionResult(
    val matched: Boolean,
    val title: String,
    val artist: String,
    val album: String? = null,
    val artworkUrl: String? = null,
    val songUrl: String? = null,
    val matchOffset: Double? = null,
    val source: RecognitionSource
)

data class BridgeEnvelope(
    val version: Int,
    val type: String,
    val streamId: String,
    val sequence: Long,
    val timestamp: String,
    val payload: Map<String, Any?>
)
