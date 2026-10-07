package app.tiktoklivecompanion

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

private class FakeEngine : RecognitionEngine {
    override var onResult: ((RecognitionResult) -> Unit)? = null
    override var onError: ((String) -> Unit)? = null
    var microphoneStarts = 0; var streamStarts = 0
    override fun recognizeMicrophone() { microphoneStarts++ }
    override fun startPcmStream(sampleRate: Int) { streamStarts++ }
    override fun appendPcm16(bytes: ByteArray, sampleRate: Int) {}
    override fun finishPcmStream() {}
    override fun cancel() {}
}

class CompanionViewModelTest {
    @Test fun recognitionStartsOnlyAfterExplicitAction() {
        val engine = FakeEngine(); val model = CompanionViewModel(engine)
        assertEquals(0, engine.microphoneStarts)
        model.recognize(); assertEquals(1, engine.microphoneStarts)
        model.selectSource(RecognitionSource.WEBVIEW); model.recognize(); assertEquals(1, engine.streamStarts)
    }

    @Test fun speechDeduplicatesExactRepeats() {
        val model = CompanionViewModel(FakeEngine())
        assertTrue(model.spokenLineAllowed("Smoke One: Ja lecker", now = 1_000))
        assertFalse(model.spokenLineAllowed("Smoke One:  Ja lecker", now = 2_000))
        assertTrue(model.spokenLineAllowed("Smoke One: Ja lecker", now = 25_000))
    }

    @Test fun mobileControlsUpdateStateAndCommands() {
        val model = CompanionViewModel(FakeEngine())
        val commands = mutableListOf<Pair<String, Map<String, Any>>>()
        model.sendCommand = { command, payload -> commands += command to payload }
        model.setAutoReconnect(false)
        model.setLimiter(true, 90)
        assertFalse(model.state.value.autoReconnectEnabled)
        assertTrue(model.state.value.limiterEnabled)
        assertEquals(90, model.state.value.limiterStrength)
        assertEquals("set-auto-reconnect", commands.first().first)
        assertEquals("set-limiter", commands.last().first)
    }
}
