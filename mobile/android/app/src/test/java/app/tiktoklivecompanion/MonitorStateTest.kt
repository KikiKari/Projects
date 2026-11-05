package app.tiktoklivecompanion

import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Test

class MonitorStateTest {
    @Test fun aPlayingSourceDoesNotLoseGridPriorityWhileBeingRechecked() {
        val rows = List(9) { i -> when (i) {
            7 -> MonitorRow("creator7", MonitorStatus.CHECKING, listOf("https://example.invalid/live.m3u8"))
            8 -> MonitorRow("creator8", MonitorStatus.ONLINE)
            else -> MonitorRow("creator$i", MonitorStatus.OFFLINE)
        } }
        assertEquals(listOf(7, 8, 0, 1), monitorGridSlots(MonitorConfig(autoSort = true), rows))
    }
    @Test fun onlinePriorityFillsGridFromAllNineSlots() {
        val rows = List(9) { MonitorRow("creator$it", if (it == 7 || it == 8) MonitorStatus.ONLINE else MonitorStatus.OFFLINE) }
        assertEquals(listOf(7, 8, 0, 1), monitorGridSlots(MonitorConfig(autoSort = true), rows))
        assertEquals(listOf(8, 7, 6, 5), monitorGridSlots(MonitorConfig(autoSort = true, reverse = true), rows))
        assertEquals(listOf(0, 1, 2, 3), monitorGridSlots(MonitorConfig(), rows))
        assertEquals(listOf(7, 8), monitorGridSlots(MonitorConfig(gridNine = true, autoSort = true), rows).take(2))
    }
    @Test fun sourcesAdvanceIndependentlyAndOnlyManualRestartWraps() {
        assertEquals(1, nextMonitorSource(0, 3, manual = false))
        assertEquals(2, nextMonitorSource(1, 3, manual = false))
        assertEquals(null, nextMonitorSource(2, 3, manual = false))
        assertEquals(0, nextMonitorSource(2, 3, manual = true))
        assertEquals(null, nextMonitorSource(0, 0, manual = true))
    }
    @Test fun sourceLabelsDoNotInventQuality() {
        assertEquals("HLS · 720p", monitorSourceLabel("https://a.tiktokcdn.com/live_720p.m3u8"))
        assertEquals("FLV · HD", monitorSourceLabel("https://a.tiktokcdn.com/live_hd.flv"))
        assertEquals("HLS · Qualität unbekannt", monitorSourceLabel("https://a.tiktokcdn.com/live.m3u8"))
    }
    @Test fun defaultSelectionAndNormalization() {
        val config = MonitorConfig()
        assertEquals(9, config.handles.size)
        assertEquals(listOf(0, 1, 2, 3), config.selectedSlots)
        assertEquals("creator.name", MonitorConfig.normalizeHandle(" @Creator.Name "))
    }

    @Test(expected = IllegalArgumentException::class)
    fun duplicateHandlesAreRejected() {
        MonitorConfig(handles = listOf("creator", "creator") + List(7) { "" })
    }

    @Test(expected = IllegalArgumentException::class)
    fun duplicateGridAssignmentsAreRejected() {
        MonitorConfig(selectedSlots = listOf(0, 1, 1, 2))
    }

    @Test fun lateResponseCannotOverwriteReassignedSlot() {
        val rows = List(9) { MonitorRow(if (it == 0) "new" else "") }
        val result = MonitorRow("old", MonitorStatus.ONLINE, listOf("https://example.invalid/video"))
        assertSame(rows, applyMonitorResult(rows, 0, result))
    }

    @Test fun resultChangesOnlyItsOwnSlot() {
        val rows = List(9) { MonitorRow("creator$it") }
        val result = MonitorRow("creator4", MonitorStatus.ONLINE, listOf("https://example.invalid/video"))
        val updated = applyMonitorResult(rows, 4, result)
        assertEquals(result, updated[4])
        assertEquals(rows[3], updated[3])
        assertEquals(rows[5], updated[5])
    }
}
