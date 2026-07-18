# Security Review: tiktok-live-companion-extension-0.5.0

## Scope

Standard full-directory review of the unchanged TikTok LIVE Companion 0.5.0 Manifest V3 extension. All nine source-like runtime files were read in full; release ZIP integrity was verified separately. Validation used complete static traces and one bounded package-API reproduction captured before the later stability pause. No further stress testing was performed.

- Scan mode: repository
- Target kind: directory_snapshot
- Target ID: target_sha256_5c9433c817053e575d66d0c5c0780d7aa8bea89a35dea098a44ebcd84850f90b
- Snapshot digest: codex-security-snapshot/v1:sha256:5b89ebe334f65c943b58b77979f4136950e147af9c97de54c24f8a024586957c
- Inventory strategy: directory
- Included paths: .
- Excluded paths: none
- Runtime or test status: Existing Node extension test passed. No live TikTok account or production stream was used.

Limitations and exclusions:
- Exact Chrome memory and session-storage failure thresholds vary by version and device.
- No live public target was tested.

### Scan Summary

| Field | Value |
| --- | --- |
| Reportable findings | 2 |
| Severity mix | low: 2 |
| Confidence mix | high: 1, medium: 1 |
| Coverage | complete |
| Validation mode | static source-to-sink analysis plus one bounded local decoder check |

Canonical artifacts: `scan-manifest.json`, `findings.json`, and `coverage.json`. This report is a deterministic projection of those files.

## Threat Model

TikTok page content, DOM, metadata, MAIN-world scripts and WebSocket frames are untrusted inputs crossing into an isolated content script, privileged service worker, session storage and extension-owned side panel.

### Assets

- extension package integrity
- captured chat and caption content
- signed temporary media URLs
- per-tab state integrity
- local player-control integrity and availability

### Trust Boundaries

- TikTok MAIN world to isolated content script
- content script to service worker
- service worker to chrome.storage.session
- extension state to side-panel rendering and user exports

### Attacker Capabilities

- influence page data and markup
- supply malformed binary/protobuf/gzip input when controlling a page/WebSocket producer
- reproduce public page-bridge markers from the same page realm

### Security Objectives

- keep TikTok-controlled values as data
- bind actions and state to the intended tab
- avoid remote exfiltration
- bound hostile parsing and storage work
- keep signed URL values local and user-directed

### Assumptions

- Chrome 114+ enforces Manifest V3 isolation
- the OS, browser binary and other installed extensions are not malicious
- the product has no backend, account system, analytics or cookie permission

## Findings

| Finding | Severity | Confidence | Detailed write-up |
| --- | --- | --- | --- |
| [Compressed WebSocket output and concurrent decodes are unbounded](#finding-1) | low | high | [Open report](findings/unbounded-gzip-expansion/unbounded-gzip-expansion.md) |
| [Page bridge accepts byte-unbounded event payloads](#finding-2) | low | medium | [Open report](findings/unbounded-page-bridge/unbounded-page-bridge.md) |

### Confidence Scale

| Label | Meaning |
| --- | --- |
| high | Direct evidence supports the finding with no material unresolved blocker. |
| medium | Evidence supports a plausible issue, but material runtime or reachability proof remains. |
| low | Evidence is incomplete and the item is retained only for explicit follow-up. |

<a id="finding-1"></a>

### [1] Compressed WebSocket output and concurrent decodes are unbounded

| Field | Value |
| --- | --- |
| Severity | low |
| Confidence | high |
| Confidence rationale | Direct source evidence plus a bounded local package-API check demonstrated a 32 KiB compressed input expanding to 32 MiB with substantial process-memory growth. |
| Category | resource-exhaustion |
| CWE | CWE-409, CWE-400 |
| Affected lines | hook.js:28-33, hook.js:70-80, proto-main.js:208-227 |

#### Summary

See the [detailed technical write-up](findings/unbounded-gzip-expansion/unbounded-gzip-expansion.md).

#### Validation

See the [detailed technical write-up](findings/unbounded-gzip-expansion/unbounded-gzip-expansion.md).

#### Dataflow

See the [detailed technical write-up](findings/unbounded-gzip-expansion/unbounded-gzip-expansion.md).

#### Reachability

See the [detailed technical write-up](findings/unbounded-gzip-expansion/unbounded-gzip-expansion.md).

#### Severity

See the [detailed technical write-up](findings/unbounded-gzip-expansion/unbounded-gzip-expansion.md).

#### Remediation

See the [detailed technical write-up](findings/unbounded-gzip-expansion/unbounded-gzip-expansion.md).

<a id="finding-2"></a>

### [2] Page bridge accepts byte-unbounded event payloads

| Field | Value |
| --- | --- |
| Severity | low |
| Confidence | medium |
| Confidence rationale | The complete source-to-sink route and missing byte controls are directly visible, but the exact live Chrome failure threshold was not measured. |
| Category | resource-exhaustion |
| CWE | CWE-20, CWE-400 |
| Affected lines | content.js:696-708, background.js:118-120, background.js:190-255 |

#### Summary

See the [detailed technical write-up](findings/unbounded-page-bridge/unbounded-page-bridge.md).

#### Validation

See the [detailed technical write-up](findings/unbounded-page-bridge/unbounded-page-bridge.md).

#### Dataflow

See the [detailed technical write-up](findings/unbounded-page-bridge/unbounded-page-bridge.md).

#### Reachability

See the [detailed technical write-up](findings/unbounded-page-bridge/unbounded-page-bridge.md).

#### Severity

See the [detailed technical write-up](findings/unbounded-page-bridge/unbounded-page-bridge.md).

#### Remediation

See the [detailed technical write-up](findings/unbounded-page-bridge/unbounded-page-bridge.md).

## Structural Hardening

The scan also produced derived, unsealed design guidance based on the complete finding collection. These proposals describe options and tradeoffs; they do not indicate that any finding has been remediated.

[Open the structural hardening portfolio](hardening/hardening.md)

## Reviewed Surfaces

| Surface | Risk Area | Outcome | Notes |
| --- | --- | --- | --- |
| Page MAIN world to extension state | Input validation and resource exhaustion | Reported | Public marker and unbounded nested objects cross into session state. Evidence: artifacts/05_findings/TLC-BRIDGE-UNBOUNDED-001/candidate_ledger.jsonl, artifacts/05_findings/TLC-BRIDGE-UNBOUNDED-001/validation_report.md, artifacts/05_findings/TLC-BRIDGE-UNBOUNDED-001/attack_path_analysis_report.md |
| WebSocket gzip and protobuf decoder | Compressed-input and parser resource exhaustion | Reported | Compressed bytes are capped, decompressed and concurrent work are not. Evidence: artifacts/05_findings/TLC-GZIP-EXPANSION-002/candidate_ledger.jsonl, artifacts/05_findings/TLC-GZIP-EXPANSION-002/validation_report.md, artifacts/05_findings/TLC-GZIP-EXPANSION-002/attack_path_analysis_report.md |
| Captured values to extension-owned side panel | Extension-context XSS | Rejected | All reviewed remote values use textContent; no innerHTML, eval or remote script sink survived. Evidence: artifacts/03_coverage/repository_coverage_ledger.md |
| Public profile fallback request | SSRF and credential leakage | Rejected | The HTTPS origin is fixed, the handle is encoded and credentials are omitted. Evidence: artifacts/03_coverage/repository_coverage_ledger.md |
| DOM and webRequest media URL discovery | Origin allowlist bypass and signed URL exposure | Rejected | Exact/dot-suffix CDN allowlisting and media classification apply before storage; debug export redacts query values. Evidence: artifacts/03_coverage/repository_coverage_ledger.md |
| Side-panel commands to player and hook operations | Authorization and confused deputy | Rejected | No externally connectable runtime API exists; active TikTok-tab checks and fixed action allowlists constrain operations. Evidence: artifacts/03_coverage/repository_coverage_ledger.md |
| Manifest and bundled executable code | Supply chain and remote code execution | No issue found | All scripts are local; no eval, native messaging, cookie or all-sites permission is declared. ZIP hashes are handled by release QA. Evidence: artifacts/02_discovery/work_ledger.jsonl |

## Open Questions And Follow Up

- Which per-message, per-tab, decompressed and in-flight byte budgets fit low-memory Chrome and Edge systems?
  - Follow-up prompt: Benchmark only the future fixed build with bounded synthetic messages on a disposable local browser profile; record peak RSS and recovery behavior without using a live TikTok stream.
