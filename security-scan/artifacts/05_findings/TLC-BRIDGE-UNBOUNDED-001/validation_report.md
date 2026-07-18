# TLC-BRIDGE-UNBOUNDED-001 validation

**Disposition:** reportable  
**Confidence:** medium-high (0.72)  
**Method:** complete static source-to-sink trace with boundary and countercontrol analysis

## Rubric

- [x] A hostile MAIN-world script can satisfy every message-routing check.
- [x] Untrusted nested objects and strings cross into extension runtime messaging.
- [x] Captions, chat, events and hook state lack per-object and aggregate byte limits.
- [x] The whole attacker-influenced state is written to `chrome.storage.session`.
- [ ] The precise Chrome quota/freeze threshold was not measured in a live extension tab.

## Evidence

`content.js:696-708` accepts same-window, same-origin events with a public source/version marker and forwards the selected object without schema or size enforcement. Any script already executing in that page realm satisfies the routing checks. `background.js:190-255` caps collection counts but not item sizes, and `background.js:118-120` structured-clones and persists the complete state. `sidepanel.js` later renders only recent entries, which limits visual count but not persisted object size.

The route crosses the hostile-page to isolated-extension boundary, but it does not grant account or cross-origin authority. The reportable impact is state integrity and extension-specific availability, not browser compromise.

## Remaining uncertainty

Chrome version, storage quota and the user's device determine the payload size or message rate needed to cause a visible write failure or unresponsive panel.

## Minimal next step

Validate fixed schemas, primitive types and maximum string/array sizes at the page bridge; reject oversized messages and apply a per-tab byte budget before persistence.
