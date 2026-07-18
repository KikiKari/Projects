# Validation summary

| Ledger row | Instance key | Root control | Entrypoint/source | Sink/control | Disposition | Counterevidence or proof gap | Survives |
|---|---|---|---|---|---|---|---|
| COV-01 | `resource-exhaustion:content.js:696` | `content.js:696-708` | TikTok MAIN-world `postMessage` | runtime clone and `storage.session` write | reportable | Exact live quota threshold was not measured; same-realm source and missing byte controls are confirmed. | yes |
| COV-02 | `resource-exhaustion:proto-main.js:208` | `proto-main.js:208-211` | binary WebSocket frame at `hook.js:28-33` | unbounded decompression to `arrayBuffer` | reportable | Browser termination threshold varies; 32 KiB expanded to 32 MiB with about 120 MiB RSS growth. | yes |
| COV-03 | — | `sidepanel.js` text sinks | captured page values | extension DOM | suppressed | Every reviewed remote value uses `textContent`; no executable HTML sink. | no |
| COV-04 | — | `content.js:269-299` | normalized profile handle | fixed TikTok HTTPS fetch | suppressed | Fixed origin, encoded handle, credentials omitted. | no |
| COV-05 | — | `content-core.js:62-111` | discovered URL | media state | suppressed | Exact/dot-suffix host allowlist and media classification. | no |
| COV-06 | — | fixed action dispatch | extension UI click | TikTok player/hook command | suppressed | No external messaging and fixed reversible action allowlist. | no |
| COV-07 | — | `proto-main.js:20-76` | binary protobuf | field parser | suppressed | Wire, length, field and truncation guards; exceptions contained. | no |
| COV-08 | — | `manifest.json` | installed package | extension execution | suppressed | Local scripts only; no eval, native messaging or all-site access. | no |
| COV-09 | — | export builders | session state | user download | suppressed | Explicit user action and signed query redaction in debug output. | no |
