package app.tiktoklivecompanion

import org.junit.Assert.assertEquals
import org.junit.Test

class ServiceVoiceTest {
    @Test fun explicitStyleGroupOverridesLanguage() {
        val voice = ServiceVoice("sherpa-de-supertonic-5", "Stil 1", "de-DE", true, 128774318, "OpenRAIL-M", "Effekt Stimmen")
        assertEquals("Effekt Stimmen", voice.displayGroup)
        assertEquals("sherpa-de-supertonic-5", voice.id)
    }
    @Test fun olderServiceAnswersKeepScriptGrouping() {
        for ((culture, expected) in mapOf("ru-RU" to "Kyrillisch", "ja-JP" to "Asiatisch", "fa-IR" to "Abjad", "ne-NP" to "Indisch", "de-DE" to "Weitere Stimmen")) {
            assertEquals(expected, ServiceVoice("old", "Old", culture, false, 0, "").displayGroup)
        }
    }
}
