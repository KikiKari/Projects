# Safe conceptual validation notes

This directory intentionally contains no executable proof of concept. The
finding was validated by static source-to-sink review for the TikTok LIVE
Companion 0.5.0 release gate. No live/public target, normal browser profile,
stress test, storage-quota probe, or oversized payload generator was used.

## Preconditions

- JavaScript is already executing in the MAIN world of a matching TikTok tab.
- The Companion content script is present in that same tab.
- The page-originated payload is treated as untrusted; the public bridge marker
  is a routing label, not authentication.

An ordinary TikTok chat participant does not satisfy the first precondition by
sending a chat message alone.

## Conceptual trace

1. Review `tiktok-live-companion-extension-0.5.0/content.js:696-708`.
2. Observe that same-page code shares `window` and `location.origin`, and can
   know the literal source marker and version.
3. Observe that the nested caption, LIVE-event, chat, or hook object is passed
   to `chrome.runtime.sendMessage` without a schema or size bound.
4. Review `tiktok-live-companion-extension-0.5.0/background.js:190-255`.
5. Confirm that list counts are capped while retained field and object byte
   sizes are not.
6. Review `tiktok-live-companion-extension-0.5.0/background.js:118-120`.
7. Confirm that the complete per-tab state reaches
   `chrome.storage.session.set` and a runtime state-update message.

## Expected static result

```text
[confirmed] page-realm code can satisfy the routing checks
[confirmed] the nested object crosses into extension messaging
[confirmed] collection counts do not bound retained bytes
[confirmed] attacker-influenced state reaches session storage
[not measured] exact Chrome quota or responsiveness threshold
```

## Safety boundary

Do not turn this checklist into a stress test against a live TikTok page or a
normal browser profile. Dynamic confirmation, if the maintainers decide it is
necessary, should be performed only with a disposable local Chrome profile, a
synthetic local harness, conservative payload limits, and instrumentation that
stops before storage or responsiveness degradation.

This conceptual review does not claim account takeover, cookie or secret
access, cross-origin access, browser compromise, or extension-context code
execution.
