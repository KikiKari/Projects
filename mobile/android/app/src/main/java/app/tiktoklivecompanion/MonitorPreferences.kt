package app.tiktoklivecompanion

import android.content.Context
import org.json.JSONArray

/** Only configuration is durable. Status and signed media URLs remain in memory. */
internal class MonitorPreferences(context: Context) {
    private val preferences = context.applicationContext.getSharedPreferences("status-monitor", Context.MODE_PRIVATE)

    fun load(): MonitorConfig = try {
        val handles = JSONArray(preferences.getString("handles", "[]"))
        val slots = JSONArray(preferences.getString("selectedSlots", "[0,1,2,3]"))
        MonitorConfig(
            handles = List(MonitorConfig.SLOT_COUNT) { index -> MonitorConfig.normalizeHandle(handles.optString(index, "")) },
            selectedSlots = List(4) { slots.optInt(it, -1) },
            gridNine = preferences.getBoolean("gridNine", false),
            intervalMinutes = preferences.getInt("intervalMinutes", 5),
            enabled = preferences.getBoolean("enabled", true),
            maxLinks = preferences.getInt("maxLinks", 5),
            showLinks = preferences.getBoolean("showLinks", false),
            autoSort = preferences.getBoolean("autoSort", false),
            skipOnline = preferences.getBoolean("skipOnline", false),
            reverse = preferences.getBoolean("reverse", false),
        )
    } catch (_: Exception) {
        MonitorConfig()
    }

    fun save(config: MonitorConfig) {
        synchronized(statusLock) {
            val previous = load()
            val edit = preferences.edit()
                .putString("handles", JSONArray(config.handles).toString())
                .putString("selectedSlots", JSONArray(config.selectedSlots).toString())
                .putBoolean("gridNine", config.gridNine)
                .putInt("intervalMinutes", config.intervalMinutes)
                .putBoolean("enabled", config.enabled)
                .putInt("maxLinks", config.maxLinks)
                .putBoolean("showLinks", config.showLinks)
                .putBoolean("autoSort", config.autoSort)
                .putBoolean("skipOnline", config.skipOnline)
                .putBoolean("reverse", config.reverse)
            config.handles.indices.filter { previous.handles[it] != config.handles[it] }.forEach { slot ->
                edit.putLong("revision-$slot", preferences.getLong("revision-$slot", 0) + 1)
                    .remove("status-$slot").remove("status-handle-$slot").remove("checked-$slot")
            }
            edit.apply()
        }
    }

    fun revision(slot: Int): Long = synchronized(statusLock) {
        require(slot in 0 until MonitorConfig.SLOT_COUNT)
        preferences.getLong("revision-$slot", 0)
    }

    fun saveStatus(slot: Int, row: MonitorRow, expectedRevision: Long) {
        synchronized(statusLock) {
            if (preferences.getLong("revision-$slot", 0) != expectedRevision) return
            if (load().handles[slot] != row.handle) return
            val priorHandle = preferences.getString("status-handle-$slot", "")
            if (priorHandle == row.handle && preferences.getLong("checked-$slot", 0) > (row.checkedAtMillis ?: 0)) return
            preferences.edit().putString("status-$slot", row.status.name)
                .putString("status-handle-$slot", row.handle)
                .putLong("checked-$slot", row.checkedAtMillis ?: 0).apply()
        }
    }

    fun loadRows(config: MonitorConfig): List<MonitorRow> = config.handles.mapIndexed { slot, handle ->
        val storedHandle = preferences.getString("status-handle-$slot", "")
        val status = if (handle.isNotEmpty() && handle == storedHandle) {
            runCatching { MonitorStatus.valueOf(preferences.getString("status-$slot", "UNKNOWN") ?: "UNKNOWN") }
                .getOrDefault(MonitorStatus.UNKNOWN).let { if (it == MonitorStatus.CHECKING) MonitorStatus.UNKNOWN else it }
        } else MonitorStatus.UNKNOWN
        MonitorRow(handle, status, checkedAtMillis = preferences.getLong("checked-$slot", 0).takeIf { it > 0 && handle == storedHandle })
    }

    companion object { private val statusLock = Any() }
}
