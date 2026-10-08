package app.tiktoklivecompanion

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import org.videolan.libvlc.MediaPlayer

/** Owns VLC's replacement PCM output. Player must be stopped before release. */
class NativeVlcAudio(private val report: (Boolean, Double, Double, Double, String?) -> Unit) {
    companion object { init { System.loadLibrary("tlc_audio") } }
    private external fun attach(player: Long): Long
    private external fun configure(handle: Long, enabled: Boolean, strength: Int)
    private external fun detach(handle: Long)
    private val main = Handler(Looper.getMainLooper())
    @Volatile private var closing = false
    @Volatile private var failed = false
    @Volatile private var paused = false
    @Volatile private var enabled = false
    private var handle = 0L
    private var writtenFrames = 0L
    private var lastReport = 0L
    private var started = false
    private val track: AudioTrack

    init {
        val minimum = AudioTrack.getMinBufferSize(48000, AudioFormat.CHANNEL_OUT_STEREO, AudioFormat.ENCODING_PCM_FLOAT)
        check(minimum > 0) { "Float-PCM-Ausgabe nicht verfügbar" }
        track = AudioTrack(
            AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_MOVIE).build(),
            AudioFormat.Builder().setSampleRate(48000).setChannelMask(AudioFormat.CHANNEL_OUT_STEREO).setEncoding(AudioFormat.ENCODING_PCM_FLOAT).build(),
            maxOf(minimum, 480 * 2 * 4), AudioTrack.MODE_STREAM, 0)
        check(track.state == AudioTrack.STATE_INITIALIZED) { "AudioTrack konnte nicht starten" }
    }

    fun install(player: MediaPlayer) {
        check(handle == 0L)
        handle = attach(player.instance)
        check(handle != 0L) { "Native VLC-Audio-Callbacks nicht verfügbar" }
    }

    fun setProtection(active: Boolean, strength: Int) {
        enabled = active
        if (handle != 0L) configure(handle, active, strength.coerceIn(0, 100))
    }

    private fun fail(message: String) {
        if (failed || closing) return
        failed = true
        runCatching { track.pause(); track.flush() }
        main.post { if (!closing) report(false, -100.0, -100.0, 0.0, message) }
    }

    /** Called from a VLC audio thread. PTS offset uses libvlc_clock's timebase. */
    @Suppress("unused")
    fun writePcm(samples: FloatArray, untilPresentationUs: Long, input: Double, output: Double, reduction: Double) {
        if (closing || failed || paused) return
        try {
            if (!started) {
                // Keep waits interruptible so stopping a distant PTS cannot hold the UI.
                if (untilPresentationUs > 2_000_000) { fail("VLC-Audiozeit außerhalb des Ausgabefensters"); return }
                val deadline = SystemClock.elapsedRealtimeNanos() + maxOf(0, untilPresentationUs) * 1000
                while (!closing && !paused && SystemClock.elapsedRealtimeNanos() < deadline) Thread.sleep(1)
                if (closing || paused) return
                track.play(); started = true
            }
            var offset = 0
            while (offset < samples.size && !closing && !paused && !failed) {
                val count = track.write(samples, offset, samples.size - offset, AudioTrack.WRITE_BLOCKING)
                if (count <= 0) { if (!closing && !paused) fail("AudioTrack-Ausgabe fehlgeschlagen ($count)"); return }
                offset += count; writtenFrames += count / 2
            }
            val now = SystemClock.elapsedRealtime()
            if (now - lastReport >= 100) {
                lastReport = now
                main.post { if (!closing && !failed) report(enabled, input, output, reduction, null) }
            }
        } catch (error: Exception) { fail("Native Audioausgabe: ${error.javaClass.simpleName}") }
    }

    @Suppress("unused")
    fun controlOutput(operation: Int) {
        if (closing || failed) return
        try {
            when (operation) {
                0 -> { paused = true; track.pause() }
                1 -> { paused = false; if (started) track.play() }
                2 -> { track.pause(); track.flush(); writtenFrames = 0; started = false }
                3 -> {
                    val deadline = SystemClock.elapsedRealtime() + 2000
                    while (!closing && !paused && (track.playbackHeadPosition.toLong() and 0xffffffffL) < writtenFrames && SystemClock.elapsedRealtime() < deadline) Thread.sleep(2)
                }
            }
        } catch (error: Exception) { fail("Native Audiosteuerung: ${error.javaClass.simpleName}") }
    }

    /** Interrupt output BEFORE MediaPlayer.stop; detach only AFTER it returns. */
    fun beginStop() { closing = true; runCatching { track.pause(); track.flush() } }
    fun releaseAfterPlayerStopped() {
        check(closing)
        if (handle != 0L) { detach(handle); handle = 0 }
        track.release()
    }
}
