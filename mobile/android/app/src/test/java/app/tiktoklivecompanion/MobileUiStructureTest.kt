package app.tiktoklivecompanion

import java.io.File
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MobileUiStructureTest {
    private fun bridgeSource(): String = listOf(
        File("src/main/res/raw/webview_bridge.js"),
        File("app/src/main/res/raw/webview_bridge.js")
    ).first { it.isFile }.readText()

    @Test fun landscapeVideoReservesScrollableContentHeight() {
        assertTrue(mobileVideoHeightDp(360, true) <= 104)
        assertTrue(360 - 160 - mobileVideoHeightDp(360, true) >= 96)
        assertTrue(mobileVideoHeightDp(800, false) == 400)
    }
    @Test fun capabilityRowsAreRenderedOnlyByLiveTab() {
        val sourceFile = listOf(File("src/main/java/app/tiktoklivecompanion/MainActivity.kt"), File("app/src/main/java/app/tiktoklivecompanion/MainActivity.kt")).first { it.isFile }
        val source = sourceFile.readText()
        val song = source.substringAfter("private fun SongTab").substringBefore("private fun CapabilityRows")
        val live = source.substringAfter("private fun LiveTab").substringBefore("private fun PlayerTab")
        assertFalse(song.contains("CapabilityRows(state)"))
        assertTrue(live.contains("CapabilityRows(state)"))
        assertTrue(source.split("CapabilityRows(state)").size - 1 == 1)
    }

    @Test fun mobilePlayerFocusUsesCenterFrameThenLiveOverviewAndPureFullscreen() {
        val source = bridgeSource()
        assertTrue(source.contains("[data-e2e=\"live-content-container\"]"))
        assertTrue(source.contains("[data-e2e=\"live-room-content\"]"))
        assertTrue(source.contains("[data-e2e=\"live-second-screen-container\"]"))
        assertTrue(source.contains("data-tlc-mobile-content-root"))
        assertTrue(source.contains("data-tlc-mobile-primary-video"))
        assertTrue(source.contains("data-tlc-mobile-second-screen"))
        assertTrue(source.contains("display:none!important"))
        assertFalse(source.contains("--tlc-scroll-y"))
        assertFalse(source.contains("object-fit:contain"))
        assertFalse(source.contains("[data-tlc-mobile-player=\"true\"] video"))
        assertTrue(source.contains("optionale cookies ablehnen"))
        assertTrue(source.contains("node.shadowRoot"))
    }
}
