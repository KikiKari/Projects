package app.tiktoklivecompanion

import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.json.JSONObject

private class RecoveryEngine : RecognitionEngine {
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
class RecoveryIntegrationTest {
    private fun model() = CompanionViewModel(RecoveryEngine())
    private fun e(type: String, payload: Map<String, Any?>) = BridgeEnvelope(1, type, "/@private/live", 2, "2026-10-07T12:00:00Z", payload)
    @Test fun hookAndPlayerTimersAreIndependent() {
        val m = model(); val commands = mutableListOf<Pair<String, Map<String, Any>>>()
        m.sendCommand = { n,p -> commands.add(n to p) }
        assertFalse(m.state.value.hookReconnectEnabled)
        m.setAutoReconnectDelay(8); m.setHookReconnectDelay(2); m.setHookReconnect(true)
        assertEquals(8,m.state.value.autoReconnectDelaySeconds)
        assertEquals(2,m.state.value.hookReconnectDelaySeconds)
        assertTrue(commands.any { it.first == "set-hook-reconnect" && it.second["delaySeconds"] == 2 })
    }
    @Test fun hookLossDoesNotNavigateOrSendPlayerCommands() {
        val m=model(); var navigation=0; val commands=mutableListOf<String>()
        m.loadUrl={navigation++}; m.sendCommand={n,_->commands.add(n)}
        repeat(5) { m.handle(e("hook-status",mapOf("installed" to true,"connected" to false))); m.handle(e("hook-recovery",mapOf("phase" to "scheduled"))) }
        assertEquals(0,navigation); assertTrue(commands.isEmpty())
    }
    @Test fun exportsExcludeSecretsAndKeepCaptionExportSeparate() {
        val m=model(); m.setDebugEnabled(true); m.setAuddToken("API-SECRET")
        m.handle(e("chat",mapOf("nickname" to "PRIVATE-AUTHOR","content" to "PRIVATE-CHAT")))
        m.handle(e("caption",mapOf("text" to "PRIVATE-CAPTION","endpoint" to "https://private/?token=TOKEN")))
        m.handle(e("socket-telemetry",mapOf("stage" to "socket-open","socketId" to "11111111-1111-1111-1111-111111111111","url" to "https://private/?token=TOKEN")))
        val report=m.debugReport(false)
        for (secret in listOf("API-SECRET","PRIVATE-AUTHOR","PRIVATE-CHAT","PRIVATE-CAPTION","TOKEN","/@private")) assertFalse(secret,report.contains(secret))
        assertTrue(m.captionRawJson().contains("PRIVATE-CAPTION")); assertFalse(m.captionRawJson().contains("TOKEN"))
        assertTrue(JSONObject(report).getJSONObject("hookRecovery").isNull("firstDecodedAtMs"))
    }
    @Test fun inspectionDoesNotOverrideObservedCaptions() {
        val m=model(); m.handle(e("caption-state",mapOf("websocket" to true,"menuAvailable" to false)))
        m.handle(e("inspection",mapOf("captionsControlPresent" to false)))
        assertTrue(m.state.value.captionsAvailable)
        m.handle(e("caption-state",mapOf("websocket" to false,"menuAvailable" to true)))
        assertFalse(m.state.value.captionsAvailable)
    }
    @Test fun staleDocumentCannotOverwriteNewState() {
        val m=model(); val a="11111111-1111-1111-1111-111111111111"; val b="22222222-2222-2222-2222-222222222222"
        m.handle(e("hook-recovery",mapOf("documentId" to a,"phase" to "native")))
        m.noteNavigation("https://www.tiktok.com/@next/live")
        m.handle(e("hook-recovery",mapOf("documentId" to b,"phase" to "connected")))
        m.handle(e("hook-recovery",mapOf("documentId" to a,"phase" to "failed")))
        assertEquals("connected",m.state.value.hookRecovery["phase"])
    }
    @Test fun embedRepeatedClicksCoalesceAndPlayingIsObserved() {
        val m=model(); var loads=0; m.loadUrl={loads++}; m.setStreamName("creator")
        m.openEmbed(); m.openEmbed(); m.openEmbed()
        assertEquals(1,loads); assertEquals("loading",m.state.value.embedPhase)
        m.handle(e("player-observation",mapOf("playing" to false)))
        assertEquals("loading",m.state.value.embedPhase)
        m.handle(e("player-observation",mapOf("playing" to true)))
        assertEquals("playing",m.state.value.embedPhase)
        m.openNormal(); assertEquals(2,loads)
    }
    @Test fun embedLoginStopsAutomaticStartup() {
        val m=model(); m.setStreamName("creator"); m.openEmbed()
        m.handle(e("embed-blocked",mapOf("reason" to "login-required")))
        assertEquals("login-required",m.state.value.embedPhase)
    }
    @Test fun selectedVlcSourceSurvivesNewCandidates() {
        val m=model();m.handle(e("media-url",mapOf("url" to "https://cdn.example/one.flv")));m.toggleVlcReplacement()
        m.handle(e("media-url",mapOf("url" to "https://cdn.example/two.m3u8")))
        assertEquals("https://cdn.example/one.flv",m.state.value.vlcReplacementUrl)
    }
    @Test fun bridgeDecodesCaptionArraysAndRecoveryTypes() {
        val raw="""{"version":1,"type":"caption","sequence":1,"timestamp":"2026-10-07T12:00:00Z","payload":{"contents":[{"lang":"de","text":"Hallo"}]}}"""
        val m=model();m.handle(BridgeValidator.decode(raw,BridgeValidator.ALLOWED_ORIGIN,true)!!)
        assertEquals("Hallo",m.state.value.captionRecords.single().text)
        for(t in listOf("hook-recovery","socket-telemetry","caption-state","player-recovery")) assertNotNull(BridgeValidator.decode(raw.replace("\"caption\"","\"$t\""),BridgeValidator.ALLOWED_ORIGIN,true))
    }
}
