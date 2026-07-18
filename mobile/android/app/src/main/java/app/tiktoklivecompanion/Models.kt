package app.tiktoklivecompanion

enum class CompanionTab(val label: String) { LIVE("Live"), CHAT("Chat"), SONG("Song"), PLAYER("Player"), MORE("Mehr") }
enum class RecognitionSource(val label: String) { MICROPHONE("Mikrofon"), WEBVIEW("WebView (experimentell)") }

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
