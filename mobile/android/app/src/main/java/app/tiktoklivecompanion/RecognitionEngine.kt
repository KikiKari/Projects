package app.tiktoklivecompanion

interface RecognitionEngine {
    var onResult: ((RecognitionResult) -> Unit)?
    var onError: ((String) -> Unit)?
    fun recognizeMicrophone()
    fun startPcmStream(sampleRate: Int = 48_000)
    fun appendPcm16(bytes: ByteArray, sampleRate: Int)
    fun finishPcmStream()
    fun cancel()
}
