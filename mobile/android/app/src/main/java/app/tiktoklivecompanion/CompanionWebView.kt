package app.tiktoklivecompanion

import android.content.Context
import android.content.Intent
import android.view.MotionEvent
import android.view.ViewConfiguration
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import androidx.annotation.RawRes
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import org.json.JSONObject
import kotlin.math.abs

private fun Context.raw(@RawRes id: Int) = resources.openRawResource(id).bufferedReader().use { it.readText() }

/**
 * FrameLayout, das kurze Taps erkennt, ohne Touch-Events zu konsumieren:
 * Scrollen, Long-Press und Interaktion im WebView bleiben vollständig erhalten.
 */
private class TapDetectingFrameLayout(context: Context, private val onTap: () -> Unit) : FrameLayout(context) {
    private val slop = ViewConfiguration.get(context).scaledTouchSlop
    private val tapTimeout = ViewConfiguration.getTapTimeout().toLong() + 100L
    private var downX = 0f
    private var downY = 0f
    private var downTime = 0L
    private var candidate = false

    override fun onInterceptTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> { downX = event.x; downY = event.y; downTime = event.eventTime; candidate = event.pointerCount == 1 }
            MotionEvent.ACTION_POINTER_DOWN -> candidate = false
            MotionEvent.ACTION_MOVE -> if (abs(event.x - downX) > slop || abs(event.y - downY) > slop) candidate = false
            MotionEvent.ACTION_UP -> if (candidate && event.eventTime - downTime <= tapTimeout) onTap()
            MotionEvent.ACTION_CANCEL -> candidate = false
        }
        return false // Events nie abfangen, nur beobachten
    }
}

@Composable fun CompanionWebView(viewModel: CompanionViewModel, modifier: Modifier = Modifier, onTap: () -> Unit = {}) {
    AndroidView(modifier = modifier, factory = { context ->
        val webView = WebView(context).apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.mediaPlaybackRequiresUserGesture = true
            settings.allowFileAccess = false
            settings.allowContentAccess = false
            settings.setSupportMultipleWindows(false)
            WebView.setWebContentsDebuggingEnabled(BuildConfig.DEBUG)
            if (WebViewFeature.isFeatureSupported(WebViewFeature.START_SAFE_BROWSING)) WebViewCompat.startSafeBrowsing(context) {}
            val bridgeSource = listOf(R.raw.content_core, R.raw.proto_main, R.raw.webview_bridge).joinToString("\n") { context.raw(it) }
            if (WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT)) WebViewCompat.addDocumentStartJavaScript(this, bridgeSource, setOf(BridgeValidator.ALLOWED_ORIGIN))
            if (WebViewFeature.isFeatureSupported(WebViewFeature.WEB_MESSAGE_LISTENER)) {
                WebViewCompat.addWebMessageListener(this, "tlcBridge", setOf(BridgeValidator.ALLOWED_ORIGIN)) { _, message, sourceOrigin, isMainFrame, _ ->
                    message.data?.let { BridgeValidator.decode(it, sourceOrigin.toString().removeSuffix("/"), isMainFrame) }?.let(viewModel::handle)
                }
            }
            webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                    val uri = request.url
                    if (uri.scheme == "https" && uri.host == "www.tiktok.com") return false
                    if (uri.scheme == "https") context.startActivity(Intent(Intent.ACTION_VIEW, uri))
                    return true
                }
            }
            webChromeClient = object : WebChromeClient() {}
            viewModel.sendCommand = { command, payload -> post { evaluateJavascript("globalThis.TLC_MOBILE_BRIDGE?.command(${JSONObject.quote(command)}, ${JSONObject(payload).toString()})", null) } }
            viewModel.loadUrl = { url -> post { loadUrl(url) } }
            loadUrl("https://www.tiktok.com/live")
        }
        TapDetectingFrameLayout(context, onTap).apply { addView(webView, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT)) }
    })
}
