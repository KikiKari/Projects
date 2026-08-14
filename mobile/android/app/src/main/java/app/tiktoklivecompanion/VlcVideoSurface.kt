package app.tiktoklivecompanion

import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import org.videolan.libvlc.LibVLC
import org.videolan.libvlc.Media
import org.videolan.libvlc.MediaPlayer
import org.videolan.libvlc.util.VLCVideoLayout

@Composable
fun VlcVideoSurface(url: String, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val videoLayout = remember { VLCVideoLayout(context) }
    val libVlc = remember { LibVLC(context, arrayListOf("--network-caching=1500")) }
    val mediaPlayer = remember { MediaPlayer(libVlc) }

    AndroidView(factory = { videoLayout }, modifier = modifier)

    DisposableEffect(mediaPlayer, videoLayout) {
        mediaPlayer.attachViews(videoLayout, null, false, false)
        onDispose {
            mediaPlayer.stop()
            mediaPlayer.detachViews()
            mediaPlayer.release()
            libVlc.release()
        }
    }

    LaunchedEffect(url) {
        mediaPlayer.stop()
        val media = Media(libVlc, Uri.parse(url))
        try {
            media.setHWDecoderEnabled(true, false)
            mediaPlayer.media = media
            mediaPlayer.play()
        } finally {
            media.release()
        }
    }
}
