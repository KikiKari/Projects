package app.tiktoklivecompanion

import org.junit.Assert.assertEquals
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
}
