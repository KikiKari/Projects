package app.tiktoklivecompanion

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.annotation.RawRes
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import org.json.JSONObject

private fun Context.raw(@RawRes id: Int) = resources.openRawResource(id).bufferedReader().use { it.readText() }

@Composable fun CompanionWebView(viewModel: CompanionViewModel, modifier: Modifier = Modifier) {
    AndroidView(modifier = modifier, factory = { context ->
        WebView(context).apply {
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
            loadUrl("https://www.tiktok.com/live")
        }
    })
}
