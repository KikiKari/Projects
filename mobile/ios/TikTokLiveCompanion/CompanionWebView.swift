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
                controller.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true))
            }
        }
        controller.add(context.coordinator, name: "tlcBridge")
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
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
        view.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData))
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        let state: CompanionState
        weak var webView: WKWebView?
        init(state: CompanionState) { self.state = state }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.frameInfo.isMainFrame,
                  message.frameInfo.securityOrigin.protocol == "https",
                  message.frameInfo.securityOrigin.host == "www.tiktok.com",
                  JSONSerialization.isValidJSONObject(message.body),
                  let data = try? JSONSerialization.data(withJSONObject: message.body),
                  let envelope = try? BridgeValidator.decode(data: data, origin: BridgeValidator.allowedOrigin, isMainFrame: true) else { return }
            Task { @MainActor in state.handle(envelope) }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else { return decisionHandler(.cancel) }
            if url.scheme == "https", url.host == "www.tiktok.com" { decisionHandler(.allow) }
            else { if url.scheme == "https" { UIApplication.shared.open(url) }; decisionHandler(.cancel) }
        }
    }
}
