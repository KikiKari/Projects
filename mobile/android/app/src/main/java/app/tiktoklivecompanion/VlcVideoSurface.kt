package app.tiktoklivecompanion

import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import org.videolan.libvlc.LibVLC
import org.videolan.libvlc.Media
import org.videolan.libvlc.MediaPlayer
import org.videolan.libvlc.util.VLCVideoLayout

@Composable
fun VlcVideoSurface(url: String, modifier: Modifier = Modifier, enabled: Boolean = false,
    strength: Int = 30, report: (Boolean, Double, Double, Double, String?) -> Unit = { _, _, _, _, _ -> }) {
    val context = LocalContext.current
    val videoLayout = remember { VLCVideoLayout(context) }
    val libVlc = remember(url) { LibVLC(context, arrayListOf("--network-caching=1500")) }
    val mediaPlayer = remember(url) { MediaPlayer(libVlc) }
    val output = remember(url) { mutableStateOf<NativeVlcAudio?>(null) }
    val currentReport = rememberUpdatedState(report)

    AndroidView(factory = { videoLayout }, modifier = modifier)

    DisposableEffect(mediaPlayer, videoLayout) {
        mediaPlayer.attachViews(videoLayout, null, false, false)
        onDispose {
            output.value?.beginStop()
            mediaPlayer.stop()
            output.value?.releaseAfterPlayerStopped()
            output.value = null
            mediaPlayer.detachViews()
            mediaPlayer.release()
            libVlc.release()
        }
    }

    LaunchedEffect(url) {
        mediaPlayer.stop()
        try {
            output.value = NativeVlcAudio { active, input, result, reduction, error -> currentReport.value(active, input, result, reduction, error) }
            output.value!!.install(mediaPlayer)
            output.value!!.setProtection(enabled, strength)
        } catch (error: Throwable) {
            output.value?.beginStop()
            output.value?.releaseAfterPlayerStopped()
            output.value = null
            currentReport.value(false, -100.0, -100.0, 0.0, "Native Audioausgabe nicht verfügbar: ${error.javaClass.simpleName}")
            return@LaunchedEffect
        }
        val media = Media(libVlc, Uri.parse(url))
        try {
            media.setHWDecoderEnabled(true, false)
            mediaPlayer.media = media
            mediaPlayer.play()
        } finally {
            media.release()
        }
    }
    LaunchedEffect(enabled, strength) { output.value?.setProtection(enabled, strength) }
}
