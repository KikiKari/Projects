package app.tiktoklivecompanion

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager

/**
 * Hält den Prozess nach dem expliziten Öffnen eines LIVE-Streams für WebView-Audio aktiv.
 * Die eigentliche Wiedergabe bleibt im vorhandenen WebView; es wird kein zweiter Player erzeugt.
 */
class BackgroundPlaybackService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "LIVE-Wiedergabe", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Hält den Ton des geöffneten LIVE-Streams im Hintergrund aktiv"
                setSound(null, null)
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action ?: ACTION_START) {
            ACTION_STOP -> {
                commandSink?.invoke("pause")
                releaseWakeLock()
                @Suppress("DEPRECATION")
                stopForeground(true)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_PLAY -> commandSink?.invoke("play")
            ACTION_PAUSE -> commandSink?.invoke("pause")
        }
        startForeground(NOTIFICATION_ID, notification())
        acquireWakeLock()
        return START_STICKY
    }

    private fun notification(): Notification {
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        fun serviceAction(action: String, requestCode: Int): PendingIntent = PendingIntent.getService(this, requestCode, Intent(this, BackgroundPlaybackService::class.java).setAction(action), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_media_play)
                .setContentTitle("TikTok LIVE Companion")
                .setContentText("LIVE-Audio läuft im Hintergrund")
                .setContentIntent(open)
                .setOngoing(true)
                .setCategory(Notification.CATEGORY_TRANSPORT)
                .addAction(Notification.Action.Builder(null, "Play", serviceAction(ACTION_PLAY, 1)).build())
                .addAction(Notification.Action.Builder(null, "Pause", serviceAction(ACTION_PAUSE, 2)).build())
                .addAction(Notification.Action.Builder(null, "Stop", serviceAction(ACTION_STOP, 3)).build())
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setSmallIcon(android.R.drawable.ic_media_play)
                .setContentTitle("TikTok LIVE Companion")
                .setContentText("LIVE-Audio läuft im Hintergrund")
                .setContentIntent(open)
                .setOngoing(true)
                .addAction(android.R.drawable.ic_media_play, "Play", serviceAction(ACTION_PLAY, 1))
                .addAction(android.R.drawable.ic_media_pause, "Pause", serviceAction(ACTION_PAUSE, 2))
                .addAction(android.R.drawable.ic_delete, "Stop", serviceAction(ACTION_STOP, 3))
                .build()
        }
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        wakeLock = (getSystemService(POWER_SERVICE) as PowerManager).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "$packageName:live-audio").apply { acquire() }
    }

    private fun releaseWakeLock() { wakeLock?.takeIf { it.isHeld }?.release(); wakeLock = null }
    override fun onDestroy() { releaseWakeLock(); super.onDestroy() }
    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val ACTION_START = "app.tiktoklivecompanion.action.START_BACKGROUND_PLAYBACK"
        const val ACTION_PLAY = "app.tiktoklivecompanion.action.PLAY"
        const val ACTION_PAUSE = "app.tiktoklivecompanion.action.PAUSE"
        const val ACTION_STOP = "app.tiktoklivecompanion.action.STOP_BACKGROUND_PLAYBACK"
        private const val CHANNEL_ID = "live_playback"
        private const val NOTIFICATION_ID = 7001
        @Volatile var commandSink: ((String) -> Unit)? = null
    }
}
