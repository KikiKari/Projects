package app.tiktoklivecompanion

import android.net.Uri
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import android.content.Context
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.videolan.libvlc.LibVLC
import org.videolan.libvlc.Media
import org.videolan.libvlc.MediaPlayer
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.math.PI
import kotlin.math.sin

@RunWith(AndroidJUnit4::class)
class NativeVlcAudioTest {
    @Test fun decodedPcmPassesThroughLimiterAndOutputStops() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val rate = 48000
        val wav = ByteBuffer.allocate(44 + rate * 4).order(ByteOrder.LITTLE_ENDIAN)
        wav.put("RIFF".toByteArray()).putInt(36 + rate * 4).put("WAVEfmt ".toByteArray())
        wav.putInt(16).putShort(1).putShort(2).putInt(rate).putInt(rate * 4).putShort(4).putShort(16)
        wav.put("data".toByteArray()).putInt(rate * 4)
        repeat(rate) { i -> val sample = (sin(i * 2 * PI * 8000 / rate) * 31000).toInt().toShort(); wav.putShort(sample).putShort(sample) }
        val file = File(context.cacheDir, "native-limiter-${System.nanoTime()}.wav")
        file.writeBytes(wav.array())
        try {
            var previousPeak = 0.0
            for (strength in listOf(-1, 25, 75, 100)) {
                val enabled = strength >= 0
                val received = CountDownLatch(1)
                var measured: Double? = null
                var failure: String? = null
                val vlc = LibVLC(context)
                val player = MediaPlayer(vlc)
                val output = NativeVlcAudio { active, input, result, _, error ->
                    if (error != null) { failure = error; received.countDown() }
                    else if (active == enabled && input > -3 && result > -90 && measured == null) { measured = result; received.countDown() }
                }
                try {
                    output.install(player)
                    output.setProtection(enabled, maxOf(0, strength))
                    val media = Media(vlc, Uri.fromFile(file))
                    player.media = media; media.release(); player.play()
                    assertTrue("No native PCM report at $strength%", received.await(15, TimeUnit.SECONDS))
                    assertNull(failure)
                    assertNotNull(measured)
                    if (enabled) assertTrue("$measured exceeds ceiling at $strength%", measured!! <= -4 - strength * 0.26 + 0.05)
                    else assertTrue("Bypass unexpectedly attenuated", measured!! > -3)
                    assertTrue("Strength must reduce monotonically", measured!! < previousPeak)
                    previousPeak = measured!!
                } finally {
                    output.beginStop(); player.stop(); output.releaseAfterPlayerStopped()
                    player.release(); vlc.release()
                }
            }
        } finally { file.delete() }
    }
}
