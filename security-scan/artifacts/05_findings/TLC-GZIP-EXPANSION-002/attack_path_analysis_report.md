# TLC-GZIP-EXPANSION-002 attack-path analysis

## Attack path

1. The installed MAIN-world hook observes a binary WebSocket message or a synthetic message dispatched by same-page script code.
2. `hook.js:28-33` rejects only compressed/input frames larger than 16 MiB and starts an asynchronous decode for each accepted frame.
3. `proto-main.js:208-225` recognizes gzip and streams it into `Response.arrayBuffer()` without limiting decompressed output.
4. The full output is allocated before protobuf parsing and before any parser exception can be contained.
5. A small compressed frame can therefore cause disproportionate memory/CPU work and temporarily disable the tab or Companion workflow.

## Attack Path Facts

- **Assumptions:** a TikTok WebSocket endpoint or code in the same page realm can deliver/dispatch a binary frame.
- **Context:** the effect crosses remote/page-controlled binary input into the bundled decoder, but remains tab- and browser-profile-scoped.
- **In scope:** yes. WebSocket frames, gzip content and protobuf messages are explicitly untrusted in the threat model.
- **Exposure:** the hook attaches to WebSockets constructed after installation on matching TikTok pages.
- **Identity:** no service identity, cookies, API keys, or privileged account action are used.
- **Cross-boundary behavior:** verified from the MAIN-world message listener to the bundled decompressor and decoder.
- **Vector:** remote/page-context binary input.
- **Preconditions:** the hook is installed and a controllable binary message reaches a wrapped WebSocket. An ordinary viewer or chat participant cannot do this directly.
- **Attacker input control:** plausible and dynamically demonstrated at the package API once the precondition is met.
- **Category:** CWE-409 / CWE-400, uncontrolled resource consumption through compression expansion and concurrency.
- **Mitigations:** 16 MiB compressed-input cap, strict protobuf field/length validation, exception containment, and no persistence across unrelated tabs.
- **Auth scope:** local extension processing of page-originated data; no auth bypass.
- **Impact surface:** runtime CPU/memory and availability.
- **Target reach:** one victim browser tab/profile at a time.
- **Secrets:** none.
- **Counterevidence:** errors are caught and the compressed input is capped. This limits parser crashes and raw frame size but is not dispositive because allocation occurs before the catch and output size is unbounded.
- **Blindspots:** Chrome-specific termination thresholds were not measured after the prior stability incident; no further stress test was run.
- **Confidence:** high for the missing bound, medium for user-visible impact magnitude.

## Severity and policy

Impact is medium and likelihood is medium because attacker reach is constrained to a page/WebSocket producer. The mandatory matrix yields **Low (P3)**. The final policy decision is **report** as a narrow availability weakness. It is not a High/Critical release blocker.
