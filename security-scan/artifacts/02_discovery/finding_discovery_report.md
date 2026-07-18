# Finding discovery

All nine source-like runtime files in the target snapshot were read in full. Two distinct resource-exhaustion candidates crossed the hostile-page to extension boundary and were promoted for validation.

1. `TLC-BRIDGE-UNBOUNDED-001`: unbounded page-bridge objects can be cloned and persisted in per-tab extension state.
2. `TLC-GZIP-EXPANSION-002`: a compressed WebSocket frame is bounded only before decompression, while output size and concurrent work are not bounded.

Exact counterevidence suppressed extension-context XSS, credentialed profile SSRF, CDN suffix bypass, arbitrary web-origin runtime messaging, account-changing DOM automation, remote script loading and unredacted debug URL export.
