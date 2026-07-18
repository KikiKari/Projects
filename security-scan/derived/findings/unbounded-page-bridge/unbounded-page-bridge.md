# Unbounded Page-Bridge Payloads Can Exhaust Companion Session State

## Executive Summary

TikTok LIVE Companion 0.5.0 accepts four kinds of page-originated messages at
its `window.postMessage` bridge and forwards their nested payloads into the
extension runtime without enforcing a schema, per-field length limit, or
aggregate byte budget. An attacker must already have JavaScript executing in
the MAIN world of a matching TikTok tab. From there, the attacker can forge the
public bridge marker and cause attacker-selected caption, chat, LIVE-event, or
hook-status data to be cloned and persisted in `chrome.storage.session`.

Collection-count limits reduce the number of retained records, but they do not
bound the size of any one retained object. The practical result is a narrow
integrity and availability issue: Companion state can be falsified, storage
writes can fail, or the side panel can become slow or unresponsive. This path
does not provide account takeover, cookie or secret access, cross-origin data
access, browser escape, or code execution in the extension context.

The confirmed affected release is 0.5.0. I reviewed the distributed 0.5.0
source directly and completed a static source-to-sink trace; I did not execute
an oversized trigger, measure a Chrome quota threshold, or test a public/live
TikTok environment. No fixed revision was available when this report was
prepared, and I did not establish when the issue was introduced.

The final severity is **Low (P3)**. The finding maps most closely to CWE-20
(Improper Input Validation) and CWE-400 (Uncontrolled Resource Consumption).

## Background

TikTok LIVE Companion is a Manifest V3 browser extension for
`https://www.tiktok.com/*`. Its content script runs in Chrome's isolated world,
while optional WebSocket observation code runs in the page's MAIN world. These
two contexts exchange decoded captions and LIVE metadata through
`window.postMessage`.

The content script registers the bridge listener in
`tiktok-live-companion-extension-0.5.0/content.js`:

```javascript
window.addEventListener("message", (event) => {
  if (event.source !== window || event.origin !== location.origin) return;
  const data = event.data;
  if (!data || data.source !== "tiktok-live-companion" || data.version !== 1) return;
  if (data.type === "caption") {
    chrome.runtime.sendMessage({ type: "TLC_CAPTION", caption: data.caption }).catch(() => {});
  } else if (data.type === "live-event") {
    chrome.runtime.sendMessage({ type: "TLC_LIVE_EVENT", liveEvent: data.liveEvent }).catch(() => {});
  } else if (data.type === "chat-message") {
    chrome.runtime.sendMessage({ type: "TLC_CHAT_MESSAGE", chatMessage: data.chatMessage }).catch(() => {});
  } else if (data.type === "hook-status") {
    chrome.runtime.sendMessage({ type: "TLC_HOOK_STATUS", hook: data.hook }).catch(() => {});
  }
});
```

The source-window and origin checks correctly reject other frames and origins.
They are routing checks, however, not authentication. A script already running
in the TikTok page realm has the same `window`, the same origin, and access to
the public source string and version number. The normal security invariant is
therefore that every object crossing this boundary is treated as untrusted,
validated into a fixed shape, and bounded before it reaches extension storage.

The service worker associates a content-script message with the sender's tab,
which limits the target to the affected tab state. State is stored under a
per-tab key in `chrome.storage.session`. This tab binding is a useful
countercontrol, but it does not constrain payload size.

## Vulnerability Details

We first reach the page bridge with an envelope containing the expected
`source`, `version`, and one of the four accepted `type` values. Once the
window/origin checks pass, the nested value is forwarded unchanged. There is
no test that the nested value is a plain object, no allowlist of fields, no
maximum string or array length, and no byte-size estimate.

For the caption path, the background worker appends a shallow copy and retains
at most 2,000 records:

```javascript
async function addCaption(tabId, caption) {
  const state = await getState(tabId);
  state.captions.push({ ...caption, receivedAtUtc: caption.receivedAtUtc || new Date().toISOString() });
  state.captions = state.captions.slice(-MAX_CAPTIONS);
  await setState(tabId, state);
}
```

The count limit is not a size limit. If we carry a caption containing a very
large `contents` array or string into this function, the object remains large
after the slice because it is still one retained record. The shallow spread
also preserves unexpected enumerable fields and nested values.

Chat handling is narrower because it selects known output fields, yet the
selected strings remain unbounded:

```javascript
const author = core.sanitizeChatText(rawMessage.nickname || rawMessage.displayId || rawMessage.author || "Chat");
const content = core.sanitizeChatText(rawMessage.content);
// ...
state.chatMessages = [...(state.chatMessages || []), {
  messageId: rawMessage.messageId || null,
  author: author || "Chat",
  content,
  contentLanguage: rawMessage.contentLanguage || "",
  source: rawMessage.source || "unbekannt",
  receivedAtUtc,
  dedupeKey
}].slice(-MAX_CHAT);
```

`sanitizeChatText` normalizes Unicode, removes emoji sequences, collapses
whitespace, and trims the result. It does not truncate it. We therefore retain
at most 50 chat objects, but a single `content`, `author`, `messageId`, language,
source, timestamp, or derived deduplication key can still be very large.

LIVE-event handling selects only statistics relevant to known methods, which
further reduces impact. Even so, `method`, `messageId`, timestamps, and numeric
strings are not length-bounded before they are composed into recent event IDs
or saved into the statistics object. The recent-ID list is capped at 500
entries, but each entry is byte-unbounded.

Finally, every update reaches the same storage sink in
`tiktok-live-companion-extension-0.5.0/background.js`:

```javascript
async function setState(tabId, state) {
  await chrome.storage.session.set({ [stateKey(tabId)]: state });
  chrome.runtime.sendMessage({ type: "TLC_STATE_UPDATED", tabId, state }).catch(() => {});
  return state;
}
```

From here, the complete attacker-influenced state is structured-cloned for the
storage write and again for the state-update message. The side panel later
renders only recent records and uses `textContent`, which mitigates extension
XSS and limits the number of visible nodes. It does not restore a bound on the
size of the stored or messaged object.

The missed invariant can be stated precisely: **every page-derived message
must be converted into a known plain-data schema, with bounded primitive
fields and a per-tab aggregate byte budget, before any extension message or
storage write occurs.** Release 0.5.0 enforces record counts but not this byte
invariant.

## Exploitability Analysis

The strongest realistic route begins with code already executing in the MAIN
world of a TikTok tab. That might be first-party page code, an included
third-party script, or another condition that has already provided page-realm
script execution. An ordinary chat participant cannot invoke this bridge
directly merely by sending a chat message.

From the page realm, we can construct a same-window message whose public
marker and version satisfy the bridge checks. If we select the caption route,
we retain broad control over the nested object because the background worker
shallow-copies it. The chat route offers less structural control but still
accepts unbounded strings. Repeating accepted updates can force repeated
structured cloning and storage serialization, while a single oversized
retained field defeats the collection-count caps.

The likely effects are extension-specific: rejected or delayed session-storage
writes, a service worker spending excess time cloning data, a side panel
receiving a large state update, or false statistics and content appearing in
the UI. Exact behavior depends on Chrome version, extension storage quota,
available memory, and device performance. I did not measure those thresholds,
so this report does not claim a deterministic crash or a particular payload
size.

Several constraints keep this at Low severity:

- The attacker already needs script execution in the TikTok page realm.
- Per-tab keys and sender-tab binding confine the affected Companion state.
- Record-count caps prevent unbounded list growth by count.
- Extension values are rendered through `textContent`, not interpreted as HTML
  or script.
- The extension has no cookie permission, externally connectable page API,
  native host, backend, or cross-origin authority exposed by this path.
- A page script can already disrupt or falsify its own page; the incremental
  security impact is the separate Companion state/storage boundary.

I considered whether forged events could be promoted into privileged player or
account actions. The reviewed path updates presentation and session state; it
does not turn the payload into a privileged command. I also found no source-to-
sink path from these values to cookies, secrets, cross-origin fetches, dynamic
code evaluation, or HTML execution. Those are important dead ends because they
bound both the impact and the remediation scope.

## Proof of Concept

The accompanying `poc/README.md` intentionally contains only a non-executable
conceptual validation plan. No live/public testing, stress test, oversized
payload generator, or automated trigger is distributed. That choice matches
the narrow release-gate goal and avoids turning an unmeasured availability
condition into a potentially disruptive test.

From the report directory, the artifact can be reviewed with:

```powershell
Get-Content -LiteralPath .\poc\README.md
```

The expected result is a static checklist that traces these facts:

```text
[confirmed] same-window and same-origin routing checks are satisfiable by page-realm code
[confirmed] the public source/version marker is not an authentication secret
[confirmed] nested bridge objects reach extension runtime messaging without size validation
[confirmed] record-count caps do not cap retained bytes
[confirmed] complete per-tab state reaches chrome.storage.session
[not measured] Chrome quota, latency, freeze, or crash threshold
```

There is no build step, no trigger command, and no cleanup requirement because
the artifact does not modify or execute against the extension. Do not convert
the conceptual plan into stress testing on a normal browser profile. Any future
dynamic validation should use a disposable local Chrome profile, synthetic
data, conservative limits, and a test-only instrumented build.

## Remediation

The primary fix is to restore the boundary invariant before invoking
`chrome.runtime.sendMessage`: accept only known plain-object shapes, coerce only
expected primitives, cap each string and array, reject unexpected nesting, and
apply a conservative total serialized-byte limit. The background worker should
repeat validation rather than trusting the content script and should enforce a
per-tab storage budget before calling `chrome.storage.session.set`.

An illustrative content-side pattern is:

```javascript
const MAX_BRIDGE_BYTES = 32 * 1024;

function boundedString(value, max) {
  return typeof value === "string" ? value.slice(0, max) : "";
}

function normalizeCaption(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) return null;
  const contents = Array.isArray(value.contents)
    ? value.contents.slice(0, 8).map((item) => ({
        lang: boundedString(item?.lang, 32),
        text: boundedString(item?.text, 2_000)
      }))
    : [];
  return {
    sentenceId: boundedString(value.sentenceId, 128),
    definite: Boolean(value.definite),
    contents,
    receivedAtUtc: boundedString(value.receivedAtUtc, 64)
  };
}

function withinBridgeBudget(value) {
  try {
    return new TextEncoder().encode(JSON.stringify(value)).byteLength <= MAX_BRIDGE_BYTES;
  } catch {
    return false;
  }
}

const caption = normalizeCaption(data.caption);
if (caption && withinBridgeBudget(caption)) {
  chrome.runtime.sendMessage({ type: "TLC_CAPTION", caption }).catch(() => {});
}
```

This is an example shape, not a drop-in patch: production limits should be
derived from legitimate observed data and documented. Equivalent normalizers
are needed for chat, LIVE-event, and hook-status messages. The background
worker should reject invalid calls safely, record only a bounded diagnostic,
and avoid broadcasting the unbounded state after a failed write.

Recommended regression coverage includes:

1. Reject non-object, array, accessor-bearing, cyclic, and deeply nested bridge
   payloads.
2. Truncate or reject every string just below, at, and above its field limit,
   including Unicode whose UTF-8 byte length exceeds its character count.
3. Cap caption contents and other arrays at their documented maxima.
4. Demonstrate that one record cannot exceed the per-message byte budget.
5. Demonstrate that many individually valid records cannot exceed the per-tab
   aggregate storage budget.
6. Verify all four bridge message types and ensure malformed input neither
   mutates state nor triggers an unhandled rejection.
7. Confirm valid hook-generated captions, chat, LIVE events, and status updates
   continue to work at boundary values.
8. Confirm the side panel remains responsive and receives a bounded state
   update when a storage write is rejected.

As defense in depth, use a dedicated `MessageChannel` or an unpredictable
per-injection capability to reduce accidental spoofing, but do not treat such a
marker as a replacement for validation. Page-realm producers remain untrusted.

## Summary

TikTok LIVE Companion 0.5.0 correctly constrains the page bridge to the same
window and origin, binds runtime data to the sender tab, caps record counts,
and renders remote data as text. The remaining gap is byte-level validation:
page-realm code can reproduce the public bridge envelope and carry oversized
or unexpected nested data into structured cloning, per-tab session storage,
and side-panel state updates.

I demonstrated the issue through a complete static source-to-sink trace and
did not execute an availability trigger or measure Chrome-specific thresholds.
The resulting Low/P3 risk is limited to Companion state integrity and
extension-specific availability. Enforcing fixed schemas, per-field limits,
per-message byte limits, and a per-tab aggregate budget at both sides of the
bridge addresses the root cause. Variant review should focus on every other
page-derived state update and on any future change that forwards whole objects
instead of selecting bounded primitive fields.
