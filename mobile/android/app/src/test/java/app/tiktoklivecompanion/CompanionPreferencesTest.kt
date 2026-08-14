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
    @Test fun storesRecognitionSourceAndDurableMutes() = runTest {
        val preferences = CompanionPreferences(ApplicationProvider.getApplicationContext<Context>())
        preferences.setSource(RecognitionSource.WEBVIEW)
        preferences.setMutedAuthors(setOf("spam-author"))
        assertEquals(RecognitionSource.WEBVIEW, preferences.source.first())
        assertTrue("spam-author" in preferences.mutedAuthors.first())
    }
}
