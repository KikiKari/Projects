package app.tiktoklivecompanion

import java.io.File
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MobileUiStructureTest {
    @Test fun capabilityRowsAreRenderedOnlyByLiveTab() {
        val sourceFile = listOf(File("src/main/java/app/tiktoklivecompanion/MainActivity.kt"), File("app/src/main/java/app/tiktoklivecompanion/MainActivity.kt")).first { it.isFile }
        val source = sourceFile.readText()
        val song = source.substringAfter("private fun SongTab").substringBefore("private fun CapabilityRows")
        val live = source.substringAfter("private fun LiveTab").substringBefore("private fun PlayerTab")
        assertFalse(song.contains("CapabilityRows(state)"))
        assertTrue(live.contains("CapabilityRows(state)"))
        assertTrue(source.split("CapabilityRows(state)").size - 1 == 1)
    }
}
