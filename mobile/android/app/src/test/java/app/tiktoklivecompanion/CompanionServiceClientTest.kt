package app.tiktoklivecompanion

import androidx.test.core.app.ApplicationProvider
import android.content.Context
import kotlinx.coroutines.runBlocking
import okhttp3.OkHttpClient
import okhttp3.Response
import okhttp3.Protocol
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.ResponseBody.Companion.toResponseBody
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class CompanionServiceClientTest {
    private fun client(respond: (okhttp3.Request) -> Pair<Int, String>): CompanionServiceClient {
        val context = ApplicationProvider.getApplicationContext<Context>()
        context.getSharedPreferences("pipeline-client", Context.MODE_PRIVATE).edit().clear().commit()
        return CompanionServiceClient(context).apply {
            pairingCode = "test-pairing"
            http = OkHttpClient.Builder().followRedirects(false).followSslRedirects(false).addInterceptor {
                val request = it.request()
                assertEquals("Bearer test-pairing", request.header("Authorization"))
                val (code, text) = respond(request)
                Response.Builder().request(request).protocol(Protocol.HTTP_1_1).code(code).message("test")
                    .body(text.toResponseBody("application/json".toMediaType())).build()
            }.build()
        }
    }
    private val healthy = """{"ok":true,"version":"0.8.2","bootstrapPairing":true}"""

    @Test fun localCatalogDoesNotNeedConfiguredAlternative() = runBlocking {
        val calls = mutableListOf<String>()
        val service = client {
            calls += it.url.toString()
            200 to if (it.url.encodedPath == "/v1/health") healthy else "{\"catalog\":[]}"
        }
        service.baseUrl = "invalid alternative"
        assertTrue(JSONObject(String(service.request("/v1/voices"))).has("catalog"))
        assertEquals(listOf("http://127.0.0.1:43117/v1/health", "http://127.0.0.1:43117/v1/voices"), calls)
    }
    @Test fun unrelatedLocalServerCannotCaptureVoiceRequest() = runBlocking {
        val calls = mutableListOf<String>()
        val service = client {
            calls += it.url.toString()
            200 to when {
                it.url.scheme == "http" -> "{\"ok\":true}"
                it.url.encodedPath == "/v1/health" -> healthy
                else -> "{\"catalog\":[]}"
            }
        }
        service.baseUrl = "service.example:8443"
        service.request("/v1/voices")
        assertEquals(listOf("http://127.0.0.1:43117/v1/health", "http://localhost:43117/v1/health", "https://service.example:8443/v1/health", "https://service.example:8443/v1/voices"), calls)
    }
    @Test fun failedInstallIsNotReplayedOnAnotherService() = runBlocking {
        val calls = mutableListOf<String>()
        val service = client {
            calls += it.method + " " + it.url.toString()
            if (it.method == "POST") 500 to "{}" else 200 to healthy
        }
        service.baseUrl = "service.example"
        try { service.request("/v1/voices/install", JSONObject().put("voiceId", "test")); fail() }
        catch (_: IllegalStateException) { }
        assertEquals(2, calls.size)
        assertEquals(1, calls.count { it.startsWith("POST ") })
        assertFalse(calls.any { it.contains("service.example") })
    }
}
