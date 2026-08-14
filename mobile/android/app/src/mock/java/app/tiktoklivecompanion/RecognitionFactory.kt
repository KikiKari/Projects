package app.tiktoklivecompanion

import android.content.Context

fun createRecognitionEngine(context: Context): RecognitionEngine = object : RecognitionEngine {
    override var onResult: ((RecognitionResult) -> Unit)? = null
    override var onError: ((String) -> Unit)? = null
    override fun recognizeMicrophone() { onError?.invoke("ShazamKit nicht konfiguriert") }
    override fun startPcmStream(sampleRate: Int) { onError?.invoke("ShazamKit nicht konfiguriert") }
    override fun appendPcm16(bytes: ByteArray, sampleRate: Int) {}
    override fun finishPcmStream() {}
    override fun cancel() {}
}
