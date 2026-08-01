# Security Review: KikiKari/Projects working tree at 280f478

## Scope

Security diff review of the browser, offscreen speech, loopback bootstrap, and catalog-driven Sherpa installation changes against 280f478.

- Scan mode: working_tree
- Target kind: git_worktree
- Target ID: git-remote-sha256:95df322da607f2c689709e5dadd7aef57a1617918c7fb344d3b7ad8e61ab1e0a
- Revision: 280f47890833f2c9e2fe1f5862d5daa7886cb9f1
- Snapshot digest: codex-security-snapshot/v1:sha256:5aac94bb1e98051289e2ccb4978c1f7343a031012c91baf0cb633789fbe643b1
- Inventory strategy: diff
- Included paths: plugin-source/browser-extension/background.js, plugin-source/browser-extension/content.js, plugin-source/browser-extension/manifest.json, plugin-source/browser-extension/offscreen.html, plugin-source/browser-extension/offscreen.js, plugin-source/browser-extension/sidepanel.html, plugin-source/browser-extension/sidepanel.js, plugin-source/companion-service/install-sherpa.ps1, plugin-source/companion-service/server.mjs, plugin-source/companion-service/setup.ps1, plugin-source/companion-service/voice-catalog.json
- Excluded paths: none
- Runtime or test status: not recorded

Limitations and exclusions:
- No second-extension browser reproduction was performed.
- No official upstream release asset was replaced or found malicious.

### Scan Summary

| Field | Value |
| --- | --- |
| Reportable findings | 2 |
| Severity mix | low: 2 |
| Confidence mix | high: 1, medium: 1 |
| Coverage | complete |
| Validation mode | Static trace plus focused local service tests and exact Windows archive-containment validation. |

Canonical artifacts: `scan-manifest.json`, `findings.json`, and `coverage.json`. This report is a deterministic projection of those files.

## Threat Model

The diff crosses browser-tab, extension-origin, loopback-service, local-filesystem, and upstream-model trust boundaries.

### Assets

- Pairing bearer
- AudD configuration
- Per-tab speech state
- Per-user model directory

### Trust Boundaries

- TikTok page to extension
- Extension to loopback service
- GitHub release assets to local filesystem

### Attacker Capabilities

- Malicious installed extension with loopback permission
- Compromised exact allowlisted release asset

### Security Objectives

- Bind bootstrap to the product extension
- Keep extracted objects within the approved staging root

### Assumptions

- The service remains bound to 127.0.0.1
- Official asset metadata is available for release pinning

## Findings

| Finding | Severity | Confidence | Detailed write-up |
| --- | --- | --- | --- |
| [Sherpa voice archives lack integrity and safe-extraction controls](#finding-1) | low | high | [Open report](findings/sherpa-archive-integrity-containment/sherpa-archive-integrity-containment.md) |
| [Loopback bootstrap does not bind pairing to the product extension origin](#finding-2) | low | medium | [Open report](findings/loopback-bootstrap-origin-binding/loopback-bootstrap-origin-binding.md) |

### Confidence Scale

| Label | Meaning |
| --- | --- |
| high | Direct evidence supports the finding with no material unresolved blocker. |
| medium | Evidence supports a plausible issue, but material runtime or reachability proof remains. |
| low | Evidence is incomplete and the item is retained only for explicit follow-up. |

<a id="finding-1"></a>

### [1] Sherpa voice archives lack integrity and safe-extraction controls

| Field | Value |
| --- | --- |
| Severity | low |
| Confidence | high |
| Confidence rationale | Static tracing and an exact bsdtar 3.8.4 containment regression confirmed the link-mediated outside-root write. |
| Category | supply-chain |
| CWE | CWE-494, CWE-22 |
| Affected lines | plugin-source/companion-service/install-sherpa.ps1:29-50, plugin-source/companion-service/voice-catalog.json:3 |

#### Summary

See the [detailed technical write-up](findings/sherpa-archive-integrity-containment/sherpa-archive-integrity-containment.md).

#### Validation

See the [detailed technical write-up](findings/sherpa-archive-integrity-containment/sherpa-archive-integrity-containment.md).

#### Dataflow

See the [detailed technical write-up](findings/sherpa-archive-integrity-containment/sherpa-archive-integrity-containment.md).

#### Reachability

See the [detailed technical write-up](findings/sherpa-archive-integrity-containment/sherpa-archive-integrity-containment.md).

#### Severity

See the [detailed technical write-up](findings/sherpa-archive-integrity-containment/sherpa-archive-integrity-containment.md).

#### Remediation

See the [detailed technical write-up](findings/sherpa-archive-integrity-containment/sherpa-archive-integrity-containment.md).

<a id="finding-2"></a>

### [2] Loopback bootstrap does not bind pairing to the product extension origin

| Field | Value |
| --- | --- |
| Severity | low |
| Confidence | medium |
| Confidence rationale | The static trace is direct; browser protocol confirmation with a second extension was not performed. |
| Category | authentication |
| CWE | CWE-346 |
| Affected lines | plugin-source/companion-service/setup.ps1:33, plugin-source/companion-service/server.mjs:344 |

#### Summary

See the [detailed technical write-up](findings/loopback-bootstrap-origin-binding/loopback-bootstrap-origin-binding.md).

#### Validation

See the [detailed technical write-up](findings/loopback-bootstrap-origin-binding/loopback-bootstrap-origin-binding.md).

#### Dataflow

See the [detailed technical write-up](findings/loopback-bootstrap-origin-binding/loopback-bootstrap-origin-binding.md).

#### Reachability

See the [detailed technical write-up](findings/loopback-bootstrap-origin-binding/loopback-bootstrap-origin-binding.md).

#### Severity

See the [detailed technical write-up](findings/loopback-bootstrap-origin-binding/loopback-bootstrap-origin-binding.md).

#### Remediation

See the [detailed technical write-up](findings/loopback-bootstrap-origin-binding/loopback-bootstrap-origin-binding.md).

## Structural Hardening

The scan also produced derived, unsealed design guidance based on the complete finding collection. These proposals describe options and tradeoffs; they do not indicate that any finding has been remediated.

[Open the structural hardening portfolio](hardening/hardening.md)

## Reviewed Surfaces

| Surface | Risk Area | Outcome | Notes |
| --- | --- | --- | --- |
| Browser tab isolation and offscreen speech | not recorded | No issue found | No additional canonical notes were recorded. Evidence: artifacts/02_discovery/work_ledger.jsonl |
| Loopback pairing bootstrap | not recorded | Reported | No additional canonical notes were recorded. Evidence: artifacts/05_findings/CAND-PAIR-BOOTSTRAP/validation_report.md, artifacts/05_findings/CAND-PAIR-BOOTSTRAP/attack_path_report.md |
| Catalog-driven Sherpa archive installation | not recorded | Reported | No additional canonical notes were recorded. Evidence: artifacts/05_findings/CAND-SHERPA-ARCHIVE/validation_report.md, artifacts/05_findings/CAND-SHERPA-ARCHIVE/attack_path_report.md, artifacts/05_findings/CAND-SHERPA-ARCHIVE/validation_artifacts/observed-outside-write.txt |
| Player replacement and sidepanel DOM changes | not recorded | No issue found | No additional canonical notes were recorded. Evidence: artifacts/02_discovery/work_ledger.jsonl |
