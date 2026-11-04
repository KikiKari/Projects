package app.tiktoklivecompanion

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.concurrent.TimeUnit

internal class MonitorWorker(context: Context, parameters: WorkerParameters) : CoroutineWorker(context, parameters) {
    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val preferences = MonitorPreferences(applicationContext)
        val config = preferences.load()
        if (config.enabled) {
            val probe = MonitorProbe()
            config.handles.forEachIndexed { slot, handle ->
                if (handle.isNotEmpty() && !isStopped) {
                    val revision = preferences.revision(slot)
                    val row = probe.check(handle, config.maxLinks)
                    preferences.saveStatus(slot, row, revision)
                }
            }
        }
        Result.success()
    }

    companion object {
        private const val NAME = "status-monitor-periodic"
        fun schedule(context: Context, config: MonitorConfig) {
            val manager = WorkManager.getInstance(context)
            if (!config.enabled || config.handles.none { it.isNotEmpty() }) {
                manager.cancelUniqueWork(NAME)
                return
            }
            val constraints = Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()
            val request = PeriodicWorkRequestBuilder<MonitorWorker>(maxOf(15, config.intervalMinutes).toLong(), TimeUnit.MINUTES)
                .setConstraints(constraints).build()
            manager.enqueueUniquePeriodicWork(NAME, ExistingPeriodicWorkPolicy.UPDATE, request)
        }
    }
}
