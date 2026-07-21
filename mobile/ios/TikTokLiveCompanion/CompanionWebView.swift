import SwiftUI
import UIKit
import WebKit

struct CompanionWebView: UIViewRepresentable {
    @ObservedObject var state: CompanionState
    let url = URL(string: "https://www.tiktok.com/live")!

    func makeCoordinator() -> Coordinator { Coordinator(state: state) }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        for resource in ["content-core", "proto-main", "webview-bridge"] {
            if let path = Bundle.main.path(forResource: resource, ofType: "js"), let script = try? String(contentsOfFile: path) {
                // Auch Subframes injizieren: Der Webcast-WebSocket kann in einem Same-Origin-Iframe laufen (0PE-52).
                controller.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: false))
            }
        }
        controller.add(context.coordinator, name: "tlcBridge")
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let view = WKWebView(frame: .zero, configuration: configuration)
        // Desktop-Layout erzwingen: Die mobile TikTok-Seite öffnet den Webcast-WebSocket nicht zuverlässig (0PE-52).
        view.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.scrollView.contentInsetAdjustmentBehavior = .never
        context.coordinator.webView = view
        state.sendCommand = { [weak view] command, payload in
            guard JSONSerialization.isValidJSONObject(payload),
                  let data = try? JSONSerialization.data(withJSONObject: payload),
                  let json = String(data: data, encoding: .utf8) else { return }
            guard let commandData = try? JSONEncoder().encode(command),
                  let quoted = String(data: commandData, encoding: .utf8) else { return }
            view?.evaluateJavaScript("globalThis.TLC_MOBILE_BRIDGE?.command(\(quoted), \(json))")
        }
        state.loadURL = { [weak view] target in
            guard target.scheme == "https", target.host == "www.tiktok.com" else { return }
            view?.load(URLRequest(url: target, cachePolicy: .reloadIgnoringLocalCacheData))
        }
        // Tap-Erkennung ohne die WebView-Bedienung zu stören: Events werden nicht konsumiert.
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tap.cancelsTouchesInView = false
        tap.delegate = context.coordinator
        view.addGestureRecognizer(tap)
        view.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData))
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate, UIGestureRecognizerDelegate {
        let state: CompanionState
        weak var webView: WKWebView?
        init(state: CompanionState) { self.state = state }

        @objc func handleTap() { Task { @MainActor in state.toggleVideoExpanded() } }
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.frameInfo.securityOrigin.protocol == "https",
                  message.frameInfo.securityOrigin.host == "www.tiktok.com",
                  JSONSerialization.isValidJSONObject(message.body),
                  let data = try? JSONSerialization.data(withJSONObject: message.body),
                  let envelope = try? BridgeValidator.decode(data: data, origin: BridgeValidator.allowedOrigin, isMainFrame: message.frameInfo.isMainFrame) else { return }
            Task { @MainActor in state.handle(envelope) }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else { return decisionHandler(.cancel) }
            if url.scheme == "https", url.host == "www.tiktok.com" { decisionHandler(.allow) }
            else { if url.scheme == "https" { UIApplication.shared.open(url) }; decisionHandler(.cancel) }
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url, url.scheme == "https", url.host == "www.tiktok.com" {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}
