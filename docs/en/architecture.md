# Architecture

The extension has six runtime areas:

- `content-core.js`: pure normalization and metadata analysis;
- `content.js`: isolated-world DOM inspection and local player/audio actions;
- `proto-main.js`: minimal protobuf decoder for public LIVE events;
- `hook.js`: MAIN-world WebSocket proxy that only adds listeners;
- `background.js`: passive CDN observation and volatile per-tab state;
- `sidepanel.*`: local rendering, export, and copy actions.

The hook never replaces `WebSocket.send()`. Page content is untrusted and displayed with `textContent`. Stream data, captions, chat, and diagnostics use `storage.session`; `storage.local` contains only auto-hook, speech-continuity, and speech-volume preferences.

See the [Mermaid source](../diagrams/architecture.mmd).

## Text alternative

The TikTok tab supplies public DOM/metadata to the isolated content script and observed WebSocket events to the MAIN-world hook. Both forward sanitized results to the service worker. It keeps volatile per-tab state and sends it to the side panel. CDN requests are observed passively only.
