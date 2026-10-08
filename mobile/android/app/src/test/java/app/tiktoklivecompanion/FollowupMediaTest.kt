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

    @Test fun connectionWaitsForBridgeAndBrowserExitsPlayer() {
        val model = CompanionViewModel(FollowupFakeEngine())
        val commands = mutableListOf<String>()
        model.sendCommand = { name, _ -> commands += name }
        model.setConnectionEnabled(true)
        assertFalse(model.state.value.connectionEnabled)
        model.handle(envelope("capability", mapOf("feature" to "connection", "available" to true)))
        assertTrue(model.state.value.connectionEnabled)
        model.setConnectionEnabled(false)
        assertTrue(model.state.value.connectionEnabled)
        model.handle(envelope("capability", mapOf("feature" to "connection", "available" to false)))
        assertFalse(model.state.value.connectionEnabled)
        model.handle(envelope("media-url", mapOf("url" to "https://cdn.example/live.m3u8", "kind" to "network")))
        model.toggleVlcReplacement()
        assertTrue(model.state.value.vlcReplacementUrl != null)
        model.openNormal()
        assertEquals(null, model.state.value.vlcReplacementUrl)
        assertTrue(commands.contains("set-vlc-active"))
    }

    @Test fun limiterUsesPercentageAndReportsUnavailableAudioHonestly() {
        val model = CompanionViewModel(FollowupFakeEngine())
        var command = ""
        var payload = emptyMap<String, Any>()
        model.sendCommand = { name, value -> command = name; payload = value }
        model.setLimiter(true, 75)
        assertEquals("set-limiter", command)
        assertEquals(75, payload["strength"])
        assertFalse(payload.containsKey("threshold"))
        model.handle(envelope("capability", mapOf("feature" to "limiter", "available" to false)))
        assertFalse(model.state.value.limiterEnabled)
        assertTrue(model.state.value.error.orEmpty().contains("Pegelschutz"))
    }

    @Test fun mediaUrlsRequireHttpsDeduplicateAndKeepTwelve() {
        val model = CompanionViewModel(FollowupFakeEngine())
        model.handle(envelope("media-url", mapOf("url" to "javascript:alert(1)", "kind" to "network")))
        repeat(14) { model.handle(envelope("media-url", mapOf("url" to "https://cdn.example/live-$it.m3u8", "kind" to "network"))) }
        model.handle(envelope("media-url", mapOf("url" to "https://cdn.example/live-13.m3u8", "kind" to "player")))
        assertEquals(12, model.state.value.mediaUrls.size)
        assertFalse(model.state.value.mediaUrls.any { it.url.startsWith("javascript:") })
        assertEquals("player", model.state.value.mediaUrls.last().kind)
    }

    @Test fun inactiveWebviewCannotOverrideNativeLimiterAndStaleNativeReportsAreIgnored() {
        val model = CompanionViewModel(FollowupFakeEngine())
        val url = "https://cdn.example/live.m3u8"
        model.handle(envelope("media-url", mapOf("url" to url, "kind" to "network")))
        model.toggleVlcReplacement()
        model.setLimiter(true, 75)
        model.handle(envelope("capability", mapOf("feature" to "limiter", "available" to false)))
        assertTrue(model.state.value.limiterEnabled)
        model.reportNativeLimiter(url, true, -1.0, -23.5, 22.5, null)
        assertTrue(model.state.value.nativeLimiterStatus.contains("VLC intern"))
        model.reportNativeLimiter("https://cdn.example/old.m3u8", false, -100.0, -100.0, 0.0, "old failure")
        assertTrue(model.state.value.limiterEnabled)
        model.reportNativeLimiter(url, false, -100.0, -100.0, 0.0, "sink failed")
        assertFalse(model.state.value.limiterEnabled)
        assertEquals("sink failed", model.state.value.error)
    }

    @Test fun explicitStreamOpenStartsBackgroundPlayback() {
        val model = CompanionViewModel(FollowupFakeEngine())
        var started = false
        model.backgroundPlaybackChanged = { started = it }
        model.setStreamName("creator")
        model.openStream()
        assertTrue(started)
    }

    @Test fun debugLogIsOptInAndExcludesPayloadContent() {
        val model = CompanionViewModel(FollowupFakeEngine())
        model.handle(envelope("chat", mapOf("content" to "secret")))
        assertTrue(model.state.value.debugEvents.isEmpty())
        model.setDebugEnabled(true)
        repeat(205) { model.handle(envelope("command-result", mapOf("data" to "secret-$it"))) }
        assertEquals(205, model.state.value.debugEvents.size)
        assertFalse(model.state.value.debugEvents.first().contains("secret-0"))
        assertTrue(model.debugReport(false).contains("bridgeEvents"))
    }

    @Test fun releaseEightSettingsCaptionsRecommendationsAndReconnectArePersistedInState() {
        val model = CompanionViewModel(FollowupFakeEngine())
        model.setAuddToken("audd")
        model.setPairingCode("pair")
        model.setUniversalCaptionApiKey("caption")
        model.setAutoReconnectDelay(59)
        model.startRecommendationScan(99)
        model.handle(envelope("caption", mapOf("sentenceId" to "1", "definite" to true, "contents" to listOf(mapOf("lang" to "de", "text" to "Hallo")))))
        val state = model.state.value
        assertEquals(59, state.autoReconnectDelaySeconds)
        assertEquals(50, state.recommendationLimit)
        assertEquals(1, state.captionRecords.size)
        assertTrue(model.captionJsonLines().contains("Hallo"))
        assertTrue(model.debugReport(false).contains("0.8.2"))
        assertTrue(model.debugReport(false).contains("settingsDialogAvailable"))
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
        assertTrue(ui.contains("Sprach- und Chat Einstellungen"))
        assertTrue(ui.contains("JSON-L-Export"))
        assertTrue(ui.contains("RAW-JSON-Export"))
        assertTrue(live.contains("LIVE-Empfehlungen"))
        assertFalse(ui.contains("Direkte TikTok-Media-URLs sind temporär"))
        assertFalse(ui.contains("Es werden nur Ereignistyp und Zeit erfasst"))
        val manifest = File(sourceRoot, "AndroidManifest.xml").readText()
        assertTrue(manifest.contains("foregroundServiceType=\"mediaPlayback\""))
        assertTrue(File(sourceRoot, "java/app/tiktoklivecompanion/BackgroundPlaybackService.kt").readText().contains("startForeground"))
    }
}
