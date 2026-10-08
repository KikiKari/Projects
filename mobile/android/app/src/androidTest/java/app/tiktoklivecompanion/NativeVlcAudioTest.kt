package app.tiktoklivecompanion

import android.net.Uri
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import android.os.Bundle
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
            var previousPeak = Double.POSITIVE_INFINITY
            for (strength in listOf(-1, 25, 75, 100)) {
                val enabled = strength >= 0
                val received = CountDownLatch(1)
                var measured: Double? = null
                var measuredInput: Double? = null
                var failure: String? = null
                val vlc = LibVLC(context)
                val player = MediaPlayer(vlc)
                val output = NativeVlcAudio { active, input, result, _, error ->
                    if (error != null) { failure = error; received.countDown() }
                    else if (active == enabled && input > -3 && result > -90 && measured == null) { measuredInput = input; measured = result; received.countDown() }
                }
                try {
                    output.install(player)
                    output.setProtection(enabled, maxOf(0, strength))
                    val media = Media(vlc, Uri.fromFile(file))
                    player.media = media; media.release(); player.play()
                    assertTrue("No native PCM report at $strength%", received.await(15, TimeUnit.SECONDS))
                    assertNull(failure)
                    assertNotNull(measured)
                    InstrumentationRegistry.getInstrumentation().sendStatus(2, Bundle().apply {
                        putString("stream", "Native PCM: strength=$strength input=$measuredInput output=$measured previous=$previousPeak\n")
                    })
                    assertEquals("Decoded WAV peak must match signed PCM16 fixture", -1.732, measuredInput!!, 0.05)
                    if (enabled) assertTrue("$measured exceeds ceiling at $strength%", measured!! <= -4 - strength * 0.26 + 0.05)
                    else assertEquals("Bypass must preserve decoded PCM", measuredInput!!, measured!!, 0.05)
                    assertTrue("Strength $strength: $measured must be below $previousPeak", measured!! < previousPeak)
                    previousPeak = measured!!
                } finally {
                    output.beginStop(); player.stop(); output.releaseAfterPlayerStopped()
                    player.release(); vlc.release()
                }
            }
        } finally { file.delete() }
    }
    @Test fun protectionChangesPauseResumeAndSeekKeepNativeOutputAlive() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val rate = 48000
        val frames = rate * 12
        val wav = ByteBuffer.allocate(44 + frames * 4).order(ByteOrder.LITTLE_ENDIAN)
        wav.put("RIFF".toByteArray()).putInt(36 + frames * 4).put("WAVEfmt ".toByteArray())
        wav.putInt(16).putShort(1).putShort(2).putInt(rate).putInt(rate * 4).putShort(4).putShort(16)
        wav.put("data".toByteArray()).putInt(frames * 4)
        repeat(frames) { i -> val sample = (sin(i * 2 * PI * 8000 / rate) * 31000).toInt().toShort(); wav.putShort(sample).putShort(sample) }
        val file = File(context.cacheDir, "native-lifecycle-${System.nanoTime()}.wav")
        file.writeBytes(wav.array())
        val reports = java.util.concurrent.LinkedBlockingQueue<Double>()
        val failures = java.util.concurrent.LinkedBlockingQueue<String>()
        val vlc = LibVLC(context)
        val player = MediaPlayer(vlc)
        val output = NativeVlcAudio { _, _, peak, _, error ->
            if (error != null) failures.offer(error) else reports.offer(peak)
        }
        fun awaitPeak(expected: Double) {
            val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
            while (System.nanoTime() < deadline) {
                assertTrue("Native output error: $failures", failures.isEmpty())
                val peak = reports.poll(250, TimeUnit.MILLISECONDS) ?: continue
                if (kotlin.math.abs(peak - expected) < 0.05) return
            }
            fail("No native output at $expected dBFS")
        }
        try {
            output.install(player); output.setProtection(true, 25)
            val media = Media(vlc, Uri.fromFile(file))
            player.media = media; media.release(); player.play()
            awaitPeak(-10.5)
            output.setProtection(true, 100); reports.clear(); awaitPeak(-30.0)
            player.pause()
            Thread.sleep(300) // Drain already posted reports before observing pause.
            reports.clear()
            assertNull("PCM must stop while paused", reports.poll(350, TimeUnit.MILLISECONDS))
            player.play(); awaitPeak(-30.0)
            player.time = 6000
            reports.clear(); awaitPeak(-30.0)
            output.setProtection(false, 100); reports.clear(); awaitPeak(-1.732)
            output.beginStop(); player.stop()
            reports.clear()
            assertNull("No PCM callback after stop", reports.poll(300, TimeUnit.MILLISECONDS))
            assertTrue("Native output error: $failures", failures.isEmpty())
        } finally {
            output.beginStop(); player.stop(); output.releaseAfterPlayerStopped()
            player.release(); vlc.release(); file.delete()
        }
    }

}
