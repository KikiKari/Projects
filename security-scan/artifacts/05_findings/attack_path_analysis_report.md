# Attack-path analysis summary

| Candidate | Boundary | Impact | Likelihood | Final severity | Priority | Policy |
|---|---|---|---|---|---|---|
| TLC-BRIDGE-UNBOUNDED-001 | TikTok MAIN world to extension session state | medium | medium | low | P3 | report |
| TLC-GZIP-EXPANSION-002 | binary WebSocket input to decompressor/decoder | medium | medium | low | P3 | report |

Neither issue enables account takeover, code execution, cross-origin data access, cookie theft, secret exposure, or a durable account action. Both are bounded to integrity/availability of one user's local Companion workflow.
