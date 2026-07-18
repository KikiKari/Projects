# Repository coverage ledger

| Row | Boundary | Files checked | Family | Source / control / sink | Candidate | Disposition | Evidence |
|---|---|---|---|---|---|---|---|
| COV-01 | Page MAIN world to isolated world | `content.js`, `background.js` | Input validation / resource exhaustion | `postMessage` marker to runtime message to `storage.session` | TLC-BRIDGE-UNBOUNDED-001 | reportable | Same-origin marker is public; no per-object or byte bound. |
| COV-02 | WebSocket to decoder | `hook.js`, `proto-main.js` | Decompression / parser DoS | compressed frame to `DecompressionStream` and `arrayBuffer` | TLC-GZIP-EXPANSION-002 | reportable | 16 MiB pre-decode cap does not bound output or concurrency. |
| COV-03 | Remote text to extension UI | `sidepanel.html`, `sidepanel.js` | XSS / template injection | captured values to DOM | — | suppressed | Remote values use `textContent`; no HTML or dynamic-code sinks. |
| COV-04 | Profile fallback network request | `content.js` | SSRF / credential leakage | normalized handle to fixed TikTok HTTPS URL | — | suppressed | Fixed origin, `encodeURIComponent`, and `credentials: omit`. |
| COV-05 | Media discovery | `content-core.js`, `background.js`, `manifest.json` | Origin bypass / data injection | DOM and webRequest URLs to stored media links | — | suppressed | HTTP(S) plus exact or dot-suffix CDN allowlist and media classification. |
| COV-06 | UI to privileged actions | `sidepanel.js`, `background.js`, `content.js` | Authorization / confused deputy | explicit extension UI clicks to fixed player and hook actions | — | suppressed | No externally-connectable API, active TikTok-tab checks and fixed action allowlists. |
| COV-07 | Binary parser | `proto-main.js` | Parser confusion / crash | remote protobuf bytes to bounded field reader | — | suppressed | Wire types, lengths, field numbers and truncation are validated and exceptions contained. |
| COV-08 | Release manifests and executable loading | `manifest.json`, all JS | Supply chain / RCE | installed package to extension execution | — | suppressed | No remote scripts, eval, native messaging, cookies or all-sites permission. ZIP integrity is verified separately. |
| COV-09 | Diagnostic and caption export | `background.js`, `sidepanel.js` | Sensitive-data exposure | local session state to user-triggered file download | — | suppressed | Signed query values are redacted in debug output; caption export is explicit. |
