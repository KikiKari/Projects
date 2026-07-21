package app.tiktoklivecompanion

import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class BridgeValidatorTest {
    private val ready = """{"version":1,"type":"bridge-ready","streamId":"","sequence":1,"timestamp":"2026-07-18T12:00:00Z","payload":{}}"""
    @Test fun acceptsMainFrameTikTokEnvelope() { assertEquals("bridge-ready", BridgeValidator.decode(ready, BridgeValidator.ALLOWED_ORIGIN, true)?.type) }
    @Test fun rejectsWrongOriginAndType() {
        assertNull(BridgeValidator.decode(ready, "https://evil.example", true))
        assertNull(BridgeValidator.decode(ready.replace("bridge-ready", "unknown"), BridgeValidator.ALLOWED_ORIGIN, true))
    }
    @Test fun acceptsSameOriginSubframe() { assertEquals("bridge-ready", BridgeValidator.decode(ready, BridgeValidator.ALLOWED_ORIGIN, false)?.type) }
    @Test fun acceptsNewDiagnosticTypes() {
        for (type in listOf("socket-open", "force-return")) {
            assertEquals(type, BridgeValidator.decode(ready.replace("bridge-ready", type), BridgeValidator.ALLOWED_ORIGIN, true)?.type)
        }
    }
    @Test fun validatesExternalLinks() { assertNotNull(BridgeValidator.safeHttpsUrl("https://www.shazam.com/song/1")); assertNull(BridgeValidator.safeHttpsUrl("javascript:alert(1)")) }
}
