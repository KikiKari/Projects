# Security Hardening Review: TikTok LIVE Companion 0.5.0

## Evidence Basis

I inspected the page-message bridge, tab-state persistence, WebSocket hook and bundled protobuf/gzip decoder in the scanned 0.5.0 snapshot. The two surviving findings are low-severity availability weaknesses: one accepts byte-unbounded page-bridge objects, while the other bounds compressed frames but not decompressed output or concurrent decode work.

## Constraints

The supplied 0.5.0 ZIPs and sources are immutable release evidence. The product must remain local and static: no backend, telemetry, cookies, API keys or remote analytics. No additional stress test is warranted after the observed Codex stability incident, so future browser thresholds remain an explicit measurement question.

## Opportunity Portfolio

No structural opportunity qualified. Although both findings concern resource limits, they sit at different boundaries and do not justify a new shared service, process or policy engine. A manufactured architectural layer would add complexity, allocations and failure modes without improving the local extension's trust model.

The proportionate controls for a future release are:

- validate fixed schemas and primitive/string/array sizes at `content.js` before runtime messaging;
- enforce a per-message and per-tab byte budget before `chrome.storage.session` writes;
- stream gzip output through a hard decompressed-byte limit and cancel on overflow;
- cap concurrent decodes and aggregate in-flight bytes in `hook.js`;
- add deterministic, bounded regression tests for rejection and recovery.

## Recommendation Summary

I recommend local remediation in the next version while leaving 0.5.0 untouched and documenting the residual risk. This preserves the extension's simple local architecture and directly restores the two violated invariants. A structural redesign becomes reasonable only if the decoder grows more formats, multiple page bridges appear, or measurement shows that local budgets cannot reliably contain memory pressure.

## Next Decisions

Choose explicit byte budgets for low-memory Chrome/Edge environments, decide whether overflow drops one event or disables the hook temporarily, and define user-visible recovery messaging. None of these proposals should be described as implemented until the next-version source is changed and revalidated.
