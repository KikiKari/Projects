package app.tiktoklivecompanion

import android.content.Context
import android.webkit.JavascriptInterface
import android.webkit.WebView
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

@RunWith(AndroidJUnit4::class)
class WebViewPeakLimiterTest {
    class Probe {
        val done = CountDownLatch(1)
        @Volatile var result = ""
        @JavascriptInterface fun report(value: String) { result = value; done.countDown() }
    }
    @Test fun packagedAudioWorkletRendersAllProtectionLevelsInWebView() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val core = context.resources.openRawResource(R.raw.content_core).bufferedReader().use { it.readText() }
        val probe = Probe()
        var view: WebView? = null
        val script = """
            (async () => {
              try {
                const rows = [];
                for (const strength of [-1,25,75,100]) {
                  const ctx = new OfflineAudioContext(1,4800,48000);
                  const buffer = ctx.createBuffer(1,4800,48000);
                  buffer.getChannelData(0)[1000] = 0.95;
                  const source = ctx.createBufferSource(); source.buffer = buffer;
                  const limiter = await TLC_CONTENT_CORE.createPeakLimiterNode(ctx);
                  limiter.setProtection({enabled:strength >= 0,strength:Math.max(0,strength)});
                  source.connect(limiter).connect(ctx.destination); source.start();
                  const rendered = await ctx.startRendering();
                  const pcm = rendered.getChannelData(0);
                  let peak = 0, index = -1;
                  for (let i=0;i<pcm.length;i++) if(Math.abs(pcm[i])>peak){peak=Math.abs(pcm[i]);index=i;}
                  rows.push({strength,db:20*Math.log10(peak),delay:index-1000});
                  limiter.port.close();
                }
                TLCProbe.report(JSON.stringify({rows}));
              } catch(error) { TLCProbe.report(JSON.stringify({error:String(error)})); }
            })();
        """.trimIndent()
        try {
            instrumentation.runOnMainSync {
                view = WebView(context).apply {
                    settings.javaScriptEnabled = true
                    addJavascriptInterface(probe, "TLCProbe")
                    // Local test document; no TikTok content or live-policy claim.
                    loadDataWithBaseURL("https://appassets.androidplatform.net/", "<html><script>" + core + "</script><script>" + script + "</script></html>", "text/html", "utf-8", null)
                }
            }
            assertTrue("WebView AudioWorklet did not finish", probe.done.await(20, TimeUnit.SECONDS))
            val result = JSONObject(probe.result)
            assertFalse("WebView AudioWorklet: $result", result.has("error"))
            val rows = result.getJSONArray("rows")
            assertEquals(4, rows.length())
            val expected = listOf(20 * kotlin.math.log10(0.95), -10.5, -23.5, -30.0)
            repeat(4) { index ->
                val row = rows.getJSONObject(index)
                assertEquals("Strength ${row.getInt("strength")}", expected[index], row.getDouble("db"), 0.05)
                assertEquals("Lookahead must stay 5 ms", 240, row.getInt("delay"))
            }
        } finally { instrumentation.runOnMainSync { view?.destroy() } }
    }
}
