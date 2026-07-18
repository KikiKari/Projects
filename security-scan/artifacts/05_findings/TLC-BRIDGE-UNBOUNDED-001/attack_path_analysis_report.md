# TLC-BRIDGE-UNBOUNDED-001 attack-path analysis

## Attack path

1. Script code executes in the MAIN world of a matching `https://www.tiktok.com/*` tab.
2. It sends a same-window `postMessage` envelope using the public Companion source/version marker.
3. `content.js:696-708` accepts the route and forwards an attacker-selected caption, event, chat, or hook object into extension messaging.
4. `background.js:190-255` applies collection-count caps but no object, string, or aggregate-byte cap.
5. `background.js:118-120` structured-clones and persists the complete state in `chrome.storage.session`, allowing state spoofing or extension-specific resource exhaustion.

## Attack Path Facts

- **Assumptions:** attacker-controlled script is already executing in the TikTok page realm; no extension or OS compromise is assumed.
- **Context:** the effect crosses from the page realm into isolated extension state, but remains within the victim's active browser profile and tab-related Companion data.
- **In scope:** yes. The threat model explicitly treats TikTok page scripts and page-to-content bridge payloads as untrusted.
- **Exposure:** the content script is installed on every matching TikTok page; there is no independent network listener.
- **Identity:** no service account, account token, cookie permission, or backend identity is involved.
- **Cross-boundary behavior:** verified from `window.postMessage` through `chrome.runtime.sendMessage` to `chrome.storage.session`.
- **Vector:** remote page content / same-page script context.
- **Preconditions:** code execution in the TikTok MAIN world. This is plausible for first-party or included third-party page code, but not for an ordinary chat participant by itself.
- **Attacker input control:** yes for the envelope and nested object once the precondition is met.
- **Category:** CWE-20 / CWE-400, improper input validation and resource consumption.
- **Mitigations:** same-window and same-origin routing, fixed message types, sender-tab binding, collection-count caps, and safe `textContent` rendering.
- **Auth scope:** public page realm to local extension; no account authorization bypass.
- **Impact surface:** runtime availability and integrity of displayed/stored Companion state.
- **Target reach:** one browser profile and the affected tab state.
- **Secrets:** none required or exposed by this path.
- **Counterevidence:** a page script can already disrupt its own page and falsify visible TikTok content. This materially limits incremental impact, but does not defeat the separate extension storage/availability boundary.
- **Blindspots:** exact Chrome quota and UI-freeze thresholds vary by version and device.
- **Confidence:** medium-high.

## Severity and policy

Impact is medium and likelihood is medium because the source precondition is constrained to page-realm script execution. The mandatory matrix yields **Low (P3)**. The final policy decision is **report** because the extension boundary and availability impact are real, though narrow. It is not a High/Critical release blocker.
