package app.tiktoklivecompanion

import java.util.Locale

/** Configuration may be persisted; signed stream URLs in [MonitorRow] must not be. */
internal data class MonitorConfig(
    val handles: List<String> = List(SLOT_COUNT) { "" },
    val selectedSlots: List<Int> = listOf(0, 1, 2, 3),
    val gridNine: Boolean = false,
    val intervalMinutes: Int = 5,
    val enabled: Boolean = true,
    val maxLinks: Int = 5,
    val showLinks: Boolean = false,
    val autoSort: Boolean = false,
    val skipOnline: Boolean = false,
    val reverse: Boolean = false,
) {
    init {
        require(handles.size == SLOT_COUNT)
        require(handles.all { it.isEmpty() || HANDLE.matches(it) })
        require(handles.filter(String::isNotEmpty).distinct().size == handles.count(String::isNotEmpty))
        require(selectedSlots.size == 4 && selectedSlots.distinct().size == 4 && selectedSlots.all { it in 0 until SLOT_COUNT })
        require(intervalMinutes in 1..60)
        require(maxLinks in 5..30)
    }

    companion object {
        const val SLOT_COUNT = 9
        private val HANDLE = Regex("[a-z0-9._]{1,24}")
        fun normalizeHandle(value: String): String = value.trim().removePrefix("@").lowercase(Locale.ROOT)
    }
}

internal enum class MonitorStatus { UNKNOWN, CHECKING, ONLINE, OFFLINE, ERROR }

/** Online priority applies to the grid, while explicit 2×2 assignments remain the fallback. */
internal fun monitorGridSlots(config: MonitorConfig, rows: List<MonitorRow>): List<Int> {
    require(rows.size == MonitorConfig.SLOT_COUNT)
    val all = (0 until MonitorConfig.SLOT_COUNT).toList()
    val assigned = if (config.gridNine) all else config.selectedSlots
    val candidates = if (config.autoSort && !config.gridNine) assigned + all.filterNot { it in assigned } else assigned
    val ordered = if (config.reverse) candidates.reversed() else candidates
    return (if (config.autoSort) ordered.sortedBy {
        val row = rows[it]
        row.status != MonitorStatus.ONLINE && !(row.status == MonitorStatus.CHECKING && row.sources.isNotEmpty())
    } else ordered)
        .take(if (config.gridNine) 9 else 4)
}

/** The identity is captured with every request so stale responses cannot cross slots. */
internal data class MonitorRow(
    val handle: String,
    val status: MonitorStatus = MonitorStatus.UNKNOWN,
    val sources: List<String> = emptyList(),
    val checkedAtMillis: Long? = null,
)

internal fun applyMonitorResult(rows: List<MonitorRow>, slot: Int, result: MonitorRow): List<MonitorRow> {
    require(rows.size == MonitorConfig.SLOT_COUNT)
    require(slot in rows.indices)
    if (rows[slot].handle != result.handle) return rows
    return rows.toMutableList().apply { this[slot] = result }
}

/** Automatic failover stops after the last source; a manual restart cycles. */
internal fun nextMonitorSource(index: Int, count: Int, manual: Boolean): Int? {
    require(count >= 0)
    if (count == 0) return null
    require(index in 0 until count)
    return if (index + 1 < count) index + 1 else if (manual) 0 else null
}

private val resolutionPattern = Regex("(?:^|[^0-9])(\\d{3,4})p(?:[^0-9]|$)")
private val hdPattern = Regex("(?:_|-)hd(?:\\.|_|-|$)")
private val sdPattern = Regex("(?:_|-)sd\\d*(?:\\.|_|-|$)")
private val ldPattern = Regex("(?:_|-)ld(?:\\.|_|-|$)")

/** Display only information recoverable from the URL; do not invent a quality. */
internal fun monitorSourceLabel(url: String): String {
    val comparable = runCatching { java.net.URI(url) }.getOrNull()?.let {
        "${it.rawPath.orEmpty()}?${it.rawQuery.orEmpty()}".lowercase(Locale.ROOT)
    }.orEmpty()
    val format = if (comparable.substringBefore('?').contains(".m3u8")) "HLS" else "FLV"
    val resolution = resolutionPattern.find(comparable)?.groupValues?.get(1)
    val quality = when {
        resolution != null -> "${resolution}p"
        hdPattern.containsMatchIn(comparable) -> "HD"
        sdPattern.containsMatchIn(comparable) -> "SD"
        ldPattern.containsMatchIn(comparable) -> "LD"
        else -> "Qualität unbekannt"
    }
    return "$format · $quality"
}
