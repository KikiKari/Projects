package app.tiktoklivecompanion

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Test

class CompanionEndpointTest {
    @Test fun workingLocalServiceWinsEvenWithInvalidAlternative() = runTest {
        val attempted = mutableListOf<String>()
        assertEquals(CompanionEndpoint.local, CompanionEndpoint.select("not a URL") { attempted += it })
        assertEquals(listOf(CompanionEndpoint.local), attempted)
    }
    @Test fun localhostIsTriedBeforeAlternative() = runTest {
        val attempted = mutableListOf<String>()
        val result = CompanionEndpoint.select("service.example:443") {
            attempted += it
            if (it == CompanionEndpoint.local) error("not listening")
        }
        assertEquals("http://localhost:43117", result)
        assertEquals(listOf(CompanionEndpoint.local, result), attempted)
    }
    @Test fun configuredHostIsProbedAfterBothLocalFailures() = runTest {
        val attempted = mutableListOf<String>()
        assertEquals("https://service.example:443", CompanionEndpoint.select("service.example:443") {
            attempted += it
            if (it.startsWith("http:")) error("not listening")
        })
        assertEquals(listOf(CompanionEndpoint.local, "http://localhost:43117", "https://service.example:443"), attempted)
    }
    @Test fun missingAlternativeReportsLocalFailureInsteadOfHttpsRequirement() = runTest {
        try { CompanionEndpoint.select("") { error("not listening") }; fail() }
        catch (error: IllegalArgumentException) { assertTrue(error.message!!.contains("Kein lokaler")) }
    }
    @Test fun cancellationDoesNotTriggerFallback() = runTest {
        var calls = 0
        try { CompanionEndpoint.select("service.example") { calls++; throw CancellationException() }; fail() }
        catch (_: CancellationException) { assertEquals(1, calls) }
    }
    @Test fun credentialsQueriesAndRemoteCleartextAreRejected() {
        for (url in listOf("https://user:secret@host", "https://host/?key=value", "https://host/#fragment", "http://100.94.134.39:43117", "https://host/path")) {
            try { CompanionEndpoint.normalize(url); fail(url) } catch (_: IllegalArgumentException) { }
        }
        assertEquals("https://100.94.134.39", CompanionEndpoint.normalize("100.94.134.39"))
        assertEquals("http://localhost:43117", CompanionEndpoint.normalize("http://localhost:43117"))
    }
}
