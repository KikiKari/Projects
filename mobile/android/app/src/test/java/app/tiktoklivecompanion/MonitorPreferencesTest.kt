package app.tiktoklivecompanion

import androidx.test.core.app.ApplicationProvider
import android.content.Context
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class MonitorPreferencesTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()

    @Before fun clear() {
        context.getSharedPreferences("status-monitor", Context.MODE_PRIVATE).edit().clear().commit()
    }

    @Test fun configurationSurvivesNewInstance() {
        val expected = MonitorConfig(
            handles = listOf("one", "two") + List(7) { "" },
            selectedSlots = listOf(8, 2, 4, 0), gridNine = true, intervalMinutes = 12, enabled = false,
            showLinks = true, autoSort = true, skipOnline = true, reverse = true,
        )
        MonitorPreferences(context).save(expected)
        assertEquals(expected, MonitorPreferences(context).load())
    }

    @Test fun invalidStoredConfigurationFallsBackToDefaults() {
        context.getSharedPreferences("status-monitor", Context.MODE_PRIVATE).edit()
            .putString("selectedSlots", "[0,0,1,2]").commit()
        assertEquals(MonitorConfig(), MonitorPreferences(context).load())
    }

    @Test fun oldResultCannotReturnAfterHandleIsReassignedAndRestored() {
        val preferences = MonitorPreferences(context)
        val first = MonitorConfig(handles = listOf("alice") + List(8) { "" })
        preferences.save(first)
        val oldRevision = preferences.revision(0)
        preferences.save(first.copy(handles = listOf("bob") + List(8) { "" }))
        preferences.save(first)
        preferences.saveStatus(0, MonitorRow("alice", MonitorStatus.ONLINE, listOf("https://example.invalid/secret"), 123), oldRevision)
        assertEquals(MonitorStatus.UNKNOWN, preferences.loadRows(first)[0].status)
        val revision = preferences.revision(0)
        preferences.saveStatus(0, MonitorRow("alice", MonitorStatus.ONLINE, listOf("https://example.invalid/secret"), 124), revision)
        val reloaded = MonitorPreferences(context).loadRows(first)[0]
        assertEquals(MonitorStatus.ONLINE, reloaded.status)
        assertEquals(emptyList<String>(), reloaded.sources)
    }

    @Test fun olderStatusCannotReplaceNewerStatus() {
        val preferences = MonitorPreferences(context)
        val config = MonitorConfig(handles = listOf("alice") + List(8) { "" })
        preferences.save(config)
        val revision = preferences.revision(0)
        preferences.saveStatus(0, MonitorRow("alice", MonitorStatus.ONLINE, checkedAtMillis = 200), revision)
        preferences.saveStatus(0, MonitorRow("alice", MonitorStatus.OFFLINE, checkedAtMillis = 100), revision)
        val row = preferences.loadRows(config)[0]
        assertEquals(MonitorStatus.ONLINE, row.status)
        assertEquals(200L, row.checkedAtMillis ?: -1L)
    }
}
