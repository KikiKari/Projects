package app.tiktoklivecompanion

import android.Manifest
import android.content.Context
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import androidx.annotation.RequiresPermission
import com.shazam.shazamkit.AudioSampleRateInHz
import com.shazam.shazamkit.DeveloperToken
import com.shazam.shazamkit.DeveloperTokenProvider
import com.shazam.shazamkit.MatchResult
import com.shazam.shazamkit.ShazamKit
import com.shazam.shazamkit.ShazamKitResult.Success
import kotlinx.coroutines.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.util.concurrent.atomic.AtomicBoolean

fun createRecognitionEngine(context: Context): RecognitionEngine = AppleShazamRecognitionEngine(context.applicationContext)

private class CachedTokenProvider(private val endpoint: String, private val client: OkHttpClient = OkHttpClient()) : DeveloperTokenProvider {
    @Volatile private var cached: Pair<String, Long>? = null
    fun refresh() {
        require(endpoint.startsWith("https://")) { "ShazamKit token service is not configured" }
        val request = Request.Builder().url(endpoint).header("X-TLC-Platform", "android").post(ByteArray(0).toRequestBody("application/json".toMediaType())).build()
        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) error("Token service HTTP ${response.code}")
            val json = JSONObject(response.body?.string().orEmpty())
            val expiry = java.time.Instant.parse(json.getString("expiresAt")).toEpochMilli()
            cached = json.getString("token") to expiry
        }
    }
    override fun provideDeveloperToken(): DeveloperToken {
        val current = cached
        if (current == null || current.second <= System.currentTimeMillis() + 30_000) refresh()
        return DeveloperToken(cached!!.first)
    }
}

private class AppleShazamRecognitionEngine(private val context: Context) : RecognitionEngine {
    override var onResult: ((RecognitionResult) -> Unit)? = null
    override var onError: ((String) -> Unit)? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val tokenProvider = CachedTokenProvider(BuildConfig.SHAZAM_TOKEN_URL)
    private var stream = ByteArrayOutputStream()
    private var streamRate = 48_000
    private val cancelled = AtomicBoolean(false)

    @RequiresPermission(Manifest.permission.RECORD_AUDIO)
    override fun recognizeMicrophone() {
        cancel(); cancelled.set(false)
        scope.launch {
            try { match(recordTwelveSeconds(), 48_000, RecognitionSource.MICROPHONE) }
            catch (error: Throwable) { onError?.invoke(error.message ?: "ShazamKit-Fehler") }
        }
    }

    override fun startPcmStream(sampleRate: Int) { cancel(); cancelled.set(false); streamRate = sampleRate; stream = ByteArrayOutputStream() }
    override fun appendPcm16(bytes: ByteArray, sampleRate: Int) { if (!cancelled.get() && stream.size() < sampleRate * 2 * 12) { streamRate = sampleRate; stream.write(bytes, 0, minOf(bytes.size, sampleRate * 2 * 12 - stream.size())) } }
    override fun finishPcmStream() { val data = stream.toByteArray(); scope.launch { runCatching { match(data, streamRate, RecognitionSource.WEBVIEW) }.onFailure { onError?.invoke(it.message ?: "ShazamKit-Fehler") } } }
    override fun cancel() { cancelled.set(true); stream.reset() }

    @RequiresPermission(Manifest.permission.RECORD_AUDIO)
    private fun recordTwelveSeconds(): ByteArray {
        val size = AudioRecord.getMinBufferSize(48_000, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        val record = AudioRecord(MediaRecorder.AudioSource.UNPROCESSED, 48_000, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, size * 2)
        val out = ByteArrayOutputStream(48_000 * 2 * 12)
        val buffer = ByteArray(size)
        try { record.startRecording(); while (!cancelled.get() && out.size() < 48_000 * 2 * 12) { val read = record.read(buffer, 0, buffer.size); if (read > 0) out.write(buffer, 0, minOf(read, 48_000 * 2 * 12 - out.size())) } } finally { record.stop(); record.release() }
        return out.toByteArray()
    }

    private suspend fun match(audio: ByteArray, sampleRate: Int, source: RecognitionSource) {
        require(audio.isNotEmpty()) { "Kein Audio empfangen" }
        tokenProvider.refresh()
        val rate = when (sampleRate) { 16_000 -> AudioSampleRateInHz.SAMPLE_RATE_16000; 32_000 -> AudioSampleRateInHz.SAMPLE_RATE_32000; 44_100 -> AudioSampleRateInHz.SAMPLE_RATE_44100; else -> AudioSampleRateInHz.SAMPLE_RATE_48000 }
        val generator = (ShazamKit.createSignatureGenerator(rate) as? Success)?.data ?: error("SignatureGenerator nicht verfügbar")
        generator.append(audio, audio.size, System.currentTimeMillis())
        val catalog = ShazamKit.createShazamCatalog(tokenProvider)
        val session = (ShazamKit.createSession(catalog) as? Success)?.data ?: error("ShazamKit-Session nicht verfügbar")
        when (val result = session.match(generator.generateSignature())) {
            is MatchResult.Match -> result.matchedMediaItems.firstOrNull()?.let { item -> onResult?.invoke(RecognitionResult(true, item.title.orEmpty(), item.artist.orEmpty(), item.subtitle, item.artworkURL?.toString(), (item.webURL ?: item.appleMusicURL)?.toString(), item.matchOffsetInMs?.toDouble()?.div(1000), source)) } ?: onResult?.invoke(RecognitionResult(false, "", "", source = source))
            is MatchResult.NoMatch -> onResult?.invoke(RecognitionResult(false, "", "", source = source))
            is MatchResult.Error -> error(result.exception.message ?: "ShazamKit match failed")
        }
    }
}
