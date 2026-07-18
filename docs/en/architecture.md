# Architecture

The extension has six runtime areas:

- `content-core.js`: pure normalization and metadata analysis;
- `content.js`: isolated-world DOM inspection and local player/audio actions;
- `proto-main.js`: minimal protobuf decoder for public LIVE events;
- `hook.js`: MAIN-world WebSocket proxy that only adds listeners;
- `background.js`: passive CDN observation and volatile per-tab state;
- `sidepanel.*`: local rendering, export, and copy actions.

The hook never replaces `WebSocket.send()`. Page content is untrusted and displayed with `textContent`. Stream data, captions, chat, and diagnostics use `storage.session`; `storage.local` contains only auto-hook, speech-continuity, and speech-volume preferences.

## Mobile runtime areas

- `mobile/ios`: SwiftUI app with WKWebView, document-start `WKUserScript`, AVSpeechSynthesizer, and ShazamKit;
- `mobile/android`: Kotlin/Compose app with AndroidX WebKit, Android Text-to-Speech, and the ShazamKit AAR;
- `plugin-source/mobile-shared`: shared, versioned bridge for public TikTok DOM, metadata, and WebSocket events;
- `site/api/shazam-token.mjs`: Android token endpoint producing short-lived ES256 tokens while the Media Services private key remains server-side.

Mobile bridge messages are accepted only from the `https://www.tiktok.com` main frame, are bounded to 64 KiB, and use fixed event and command allowlists. The apps never read cookies or Web Storage. Stream state is volatile; preferences and permanent mutes use UserDefaults or DataStore.

Microphone recognition starts only after a click and runs for at most twelve seconds. WebView PCM is experimental; CORS, codec, or WebView failure stops capture and offers the microphone path.

See the [Mermaid source](../diagrams/architecture.mmd).

## Reproducible project visualization

![Isometric TikTok LIVE Companion platform architecture](../diagrams/tiktok-live-companion-architecture.svg)

- [Open the rotating GIF](../diagrams/tiktok-live-companion-architecture.gif)
- [SVG generator](../../assets/gen_tiktok_live_companion_flow.py)
- [GIF generator](../../assets/gen_tiktok_live_companion_flow_gif.py)
- [Shared data model](../../assets/flow_model.py)
- [Visualization contract](../diagrams/tiktok-live-companion-visualization-contract.md)

This view is project-specific: depth separates browser, iOS, and Android/HyperOS. Cyan denotes passive observation, coral denotes audio started only after user action, and amber denotes the short-lived Android token flow. Box size is schematic and does not measure performance or data volume.

## Text alternative

In the browser, the TikTok tab supplies public DOM/metadata to the isolated content script and observed WebSocket events to the MAIN-world hook. Both forward sanitized results to the service worker. It keeps volatile per-tab state and sends it to the side panel. CDN requests are observed passively only. On mobile, the same decoder is injected at document start into the allowed TikTok WebView and forwards only validated event envelopes to native state.
