package app.tiktoklivecompanion

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class CompanionPreferencesTest {
    @Test fun speechFilterAndRefreshSurviveRecreationIndependently() = runTest {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val preferences = CompanionPreferences(context)
        for (filter in listOf(false, true)) for (game in listOf(false, true)) {
            preferences.setFilterExternalSpeechTriggers(filter)
            preferences.setGameMode(game)
            preferences.setAutoChatRefreshEnabled(true)
            preferences.setAutoChatRefreshMinutes(7)
            val restored = CompanionPreferences(context)
            assertEquals(filter, restored.filterExternalSpeechTriggers.first())
            assertEquals(game, restored.gameMode.first())
            assertTrue(restored.autoChatRefreshEnabled.first())
            assertEquals(7, restored.autoChatRefreshMinutes.first())
        }
    }

    @Test fun limiterStrengthSurvivesRecreationWithoutThresholdRounding() = runTest {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val preferences = CompanionPreferences(context)
        for (strength in listOf(25, 75, 100)) {
            preferences.setLimiter(true, strength)
            val restored = CompanionPreferences(context)
            assertEquals(strength, restored.limiterStrength.first())
            assertTrue(restored.limiterEnabled.first())
        }
        preferences.setLimiterThreshold(-17)
        assertEquals(50, CompanionPreferences(context).limiterStrength.first())
    }
    @Test fun storesRecognitionSourceAndDurableMutes() = runTest {
        val preferences = CompanionPreferences(ApplicationProvider.getApplicationContext<Context>())
        preferences.setSource(RecognitionSource.WEBVIEW)
        preferences.setMutedAuthors(setOf("spam-author"))
        assertEquals(RecognitionSource.WEBVIEW, preferences.source.first())
        assertTrue("spam-author" in preferences.mutedAuthors.first())
    }
}
