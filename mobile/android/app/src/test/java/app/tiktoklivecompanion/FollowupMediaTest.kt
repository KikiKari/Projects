package app.tiktoklivecompanion

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.io.File

private class FollowupFakeEngine : RecognitionEngine {
    override var onResult: ((RecognitionResult) -> Unit)? = null
    override var onError: ((String) -> Unit)? = null
    override fun recognizeMicrophone() {}
    override fun startPcmStream(sampleRate: Int) {}
    override fun appendPcm16(bytes: ByteArray, sampleRate: Int) {}
    override fun finishPcmStream() {}
    override fun cancel() {}
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class FollowupMediaTest {
    private fun envelope(type: String, payload: Map<String, Any?>) = BridgeEnvelope(1, type, "", 1, "2026-07-22T12:00:00Z", payload)

    @Test fun mediaUrlsRequireHttpsDeduplicateAndKeepTwelve() {
        val model = CompanionViewModel(FollowupFakeEngine())
        model.handle(envelope("media-url", mapOf("url" to "javascript:alert(1)", "kind" to "network")))
        repeat(14) { model.handle(envelope("media-url", mapOf("url" to "https://cdn.example/live-$it.m3u8", "kind" to "network"))) }
        model.handle(envelope("media-url", mapOf("url" to "https://cdn.example/live-13.m3u8", "kind" to "player")))
        assertEquals(12, model.state.value.mediaUrls.size)
        assertFalse(model.state.value.mediaUrls.any { it.url.startsWith("javascript:") })
        assertEquals("player", model.state.value.mediaUrls.last().kind)
    }

    @Test fun explicitStreamOpenStartsBackgroundPlayback() {
        val model = CompanionViewModel(FollowupFakeEngine())
        var started = false
        model.backgroundPlaybackChanged = { started = it }
        model.setStreamName("creator")
        model.openStream()
        assertTrue(started)
    }

    @Test fun debugLogIsOptInPayloadFreeAndBounded() {
        val model = CompanionViewModel(FollowupFakeEngine())
        model.handle(envelope("chat", mapOf("content" to "secret")))
        assertTrue(model.state.value.debugEvents.isEmpty())
        model.setDebugEnabled(true)
        repeat(205) { model.handle(envelope("command-result", mapOf("data" to "secret-$it"))) }
        assertEquals(200, model.state.value.debugEvents.size)
        assertFalse(model.state.value.debugEvents.any { it.contains("secret") })
    }

    @Test fun followupUiAndBackgroundServiceStayInTheirIntendedAreas() {
        val sourceRoot = listOf(File("src/main"), File("app/src/main"), File("mobile/android/app/src/main")).first { File(it, "AndroidManifest.xml").isFile }
        val ui = File(sourceRoot, "java/app/tiktoklivecompanion/MainActivity.kt").readText()
        val chat = ui.substringAfter("private fun ChatTab").substringBefore("private fun LiveTab")
        val live = ui.substringAfter("private fun LiveTab").substringBefore("private fun PlayerTab")
        assertTrue(chat.contains("takeLast(5)"))
        assertTrue(chat.contains("Top-Chatter"))
        assertFalse(live.contains("Top-Chatter"))
        assertTrue(live.contains("Personen stummschalten"))
        assertTrue(ui.substringAfter("private fun MoreTab").contains("Debugmodus"))
        val manifest = File(sourceRoot, "AndroidManifest.xml").readText()
        assertTrue(manifest.contains("foregroundServiceType=\"mediaPlayback\""))
        assertTrue(File(sourceRoot, "java/app/tiktoklivecompanion/BackgroundPlaybackService.kt").readText().contains("startForeground"))
    }
}
