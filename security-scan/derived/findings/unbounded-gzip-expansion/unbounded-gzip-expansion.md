# Unbounded gzip expansion can exhaust a TikTok tab

## Executive Summary

TikTok LIVE Companion 0.5.0 accepts binary WebSocket messages up to 16 MiB
before decoding them, but does not place a corresponding limit on gzip output.
The decoder materializes the entire decompressed body in an `ArrayBuffer` before
protobuf parsing begins. A sufficiently compressible frame can therefore turn a
small network input into disproportionate memory and CPU work in the page
process.

Release 0.5.0 is affected. No fixed release was available for comparison during
this review. I reviewed the unchanged 0.5.0 source directly and checked the
bounded validation record. I did not repeat the resource-consumption test or
exercise the condition against a live service.
That record used a 32,635-byte compressed input which expanded to 32 MiB,
observed an approximately 120 MiB process-RSS increase, and then reached the
expected protobuf parser rejection.

The practical impact is a local availability loss in the affected TikTok tab
or browser profile. The condition does not cross the browser sandbox, disclose
secrets, bypass authentication, or grant extension privileges. I therefore
classify it as **Low / P3** (CWE-409 and CWE-400).

## Background

TikTok LIVE Companion is a Manifest V3 browser extension. Its optional LIVE
decoder is installed into TikTok's MAIN JavaScript world at `document_start`.
`background.js` registers `proto-main.js` followed by `hook.js`, so the decoder
is available when the hook wraps the page's `WebSocket` constructor:

```javascript
// background.js, hook registration
await chrome.scripting.registerContentScripts([{
  id: HOOK_SCRIPT_ID,
  matches: ["https://www.tiktok.com/*"],
  js: ["proto-main.js", "hook.js"],
  runAt: "document_start",
  world: "MAIN",
  persistAcrossSessions
}]);
```

Because these two scripts share the page realm, WebSocket data and objects in
that realm must be treated as untrusted. The hook is passive: it attaches a
`message` listener to each subsequently constructed socket and sends decoded
captions, chat messages, and LIVE events to the isolated content script.

The normal invariant should be straightforward: resource limits must apply to
the data after every size-increasing transformation, and the decoder must not
allow multiple untrusted messages to accumulate unbounded work. The 0.5.0
implementation enforces the first half only on the compressed representation.

## Vulnerability Details

We first reach the vulnerable path in `hook.js`. Strings are ignored and the
hook calculates the size of a `Blob`, `ArrayBuffer`, or similar binary value.
The message is rejected only when that input representation exceeds 16 MiB:

```javascript
// hook.js:28-33, inspectMessage
async function inspectMessage(event, endpoint) {
  try {
    if (typeof event.data === "string") return;
    const size = event.data?.size ?? event.data?.byteLength ?? 0;
    if (size > 16 * 1024 * 1024) return;
    const decoded = await proto.decodeWebSocketPayload(event.data);
```

Each wrapped socket invokes this asynchronous function for every binary
message. The listener does not await it, limit concurrent invocations, or
maintain an aggregate byte budget:

```javascript
// hook.js:70-80, WrappedWebSocket
const WrappedWebSocket = new Proxy(NativeWebSocket, {
  construct(target, args, newTarget) {
    const socket = Reflect.construct(target, args, newTarget);
    const endpoint = safeEndpoint(args[0]);
    // open and close handlers omitted
    socket.addEventListener("message", (event) => {
      inspectMessage(event, endpoint);
    });
    return socket;
  }
});
```

If we carry an admitted frame into `decodeWebSocketPayload`, its protobuf
envelope selects field 8 as the payload and field 6 as the encoding. A gzip
label or gzip magic bytes route that payload into `gunzip`:

```javascript
// proto-main.js:208-225, gunzip and decodeWebSocketPayload
async function gunzip(bytes) {
  if (typeof DecompressionStream !== "function") {
    throw new Error("gzip is not supported by this browser");
  }
  const stream = new Blob([bytes]).stream()
    .pipeThrough(new DecompressionStream("gzip"));
  return new Uint8Array(await new Response(stream).arrayBuffer());
}

async function decodeWebSocketPayload(data) {
  let bytes;
  if (data instanceof Blob) bytes = new Uint8Array(await data.arrayBuffer());
  else bytes = toBytes(data);

  const pushFields = parseFields(bytes);
  let payload = first(pushFields, 8, 2);
  const encoding = text(first(pushFields, 6, 2)).toLowerCase();
  if (!payload) {
    payload = bytes;
  } else if (encoding.includes("gzip") ||
             (payload[0] === 0x1f && payload[1] === 0x8b)) {
    payload = await gunzip(payload);
  }
```

`Response.arrayBuffer()` consumes the stream to completion. There is no point
in this path where we compare the growing decompressed byte count with a safe
maximum or cancel the reader. The full output allocation therefore occurs
before `decodeFetchResult()` can reject an invalid inner protobuf message.

The surrounding `try`/`catch` in `inspectMessage` contains parser exceptions,
which is useful for correctness, but it cannot reclaim time and peak memory
already consumed during decompression. The validation record illustrates the
gap with concrete values:

| Stage | Observed value |
|---|---:|
| Compressed input | 32,635 bytes |
| Hook input ceiling | 16,777,216 bytes |
| Decompressed output | 33,554,432 bytes |
| Process RSS delta | 120,217,600 bytes |
| Final parser result | `Invalid protobuf field number` |

The compressed frame was about 0.2% of the existing input ceiling. The later
parser error is counterevidence against code execution or persistent parser
state corruption, but it is not a mitigation for the allocation that has
already completed.

## Exploitability Analysis

The strongest realistic route begins with a binary message delivered by a
TikTok WebSocket observed by the installed MAIN-world hook. The producer must
control the frame body or compromise a component able to influence that
WebSocket stream; an ordinary viewer or chat participant cannot directly
choose raw protocol frames. Once that precondition holds, we can place a highly
compressible body inside the accepted outer protobuf envelope and mark it as
gzip. The browser then performs the expansion locally without a post-transform
limit.

A single frame supplies a memory-amplification primitive. Repeated frames make
the availability effect more reliable because the message handler starts a new
asynchronous decode for each event without backpressure. Several inflations can
therefore overlap, increasing transient memory and CPU pressure before earlier
messages fail parsing or finish processing. Exact tab-discard or process-
termination thresholds depend on Chrome version, available memory, and profile
state, so we should not claim a deterministic crash from the bounded evidence.

A same-page script can also reach the listener by dispatching a synthetic
binary `MessageEvent` on a wrapped socket. That route is useful for local
diagnosis, but it is a weaker security story: script already executing in the
TikTok MAIN world has substantial control over the page and can cause other
forms of tab-local resource exhaustion. It does, however, confirm that the hook
does not establish an authenticity boundary around message events.

Several apparent escalation routes stop at meaningful constraints:

- Inputs larger than 16 MiB are discarded before decoding, so raw-frame growth
  alone does not bypass the existing check.
- Strict protobuf field, wire-type, length, and truncation checks make malformed
  inner data fail closed after inflation. We do not obtain a memory-corruption
  or script-execution primitive from this path.
- Exceptions are caught and no decompressed body is persisted after rejection,
  which limits the effect to transient resource consumption.
- The extension has no backend, cookie permission, native messaging bridge, or
  all-sites host access. The observed primitive does not expose account tokens
  or affect other users.

These constraints support the Low/P3 rating. The finding is still worth fixing
because a resource ceiling expressed only in compressed bytes is not a valid
ceiling for the work the browser ultimately performs.

## Proof of Concept

The accompanying `poc/README.md` preserves the bounded validation procedure and
representative result. It intentionally contains no executable expansion
payload. No public or live endpoint was used.

The recorded check loaded the original `proto-main.js` module through its
package API and passed it a valid outer protobuf envelope. The envelope held a
32 MiB zero-filled body compressed to 32,635 bytes and identified as gzip. The
test measured process memory around `decodeWebSocketPayload()` and retained the
expected inner-parser failure as evidence that decompression completed before
parsing.

Representative recorded output is:

```text
compressedBytes: 32635
decompressedBytes: 33554432
underHookInputCap: true
decodeMs: 286
rssDeltaBytes: 120217600
postDecompressionParserError: Invalid protobuf field number
```

This is a defensive validation record, not a stress-test recipe. Running larger
or repeated payloads could make a tab, browser profile, or test process
unresponsive. I did not rerun the check because the existing bounded result was
sufficient to validate the missing invariant.

## Remediation

The primary invariant to restore is: **decompressed bytes must remain below a
small, protocol-appropriate ceiling before the decoder materializes the full
body**. We should read the decompression stream incrementally, count each
chunk, cancel as soon as the ceiling is crossed, and concatenate only an
accepted result.

A minimal defensive shape for `proto-main.js` is:

```javascript
const MAX_DECOMPRESSED_BYTES = 8 * 1024 * 1024;

async function gunzip(bytes) {
  if (typeof DecompressionStream !== "function") {
    throw new Error("gzip is not supported by this browser");
  }

  const stream = new Blob([bytes]).stream()
    .pipeThrough(new DecompressionStream("gzip"));
  const reader = stream.getReader();
  const chunks = [];
  let total = 0;

  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      total += value.byteLength;
      if (total > MAX_DECOMPRESSED_BYTES) {
        await reader.cancel("decompressed payload exceeds limit");
        throw new Error("Decompressed payload exceeds limit");
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }

  const output = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    output.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return output;
}
```

The exact ceiling should be derived from the largest legitimate LIVE payload,
with measured headroom, rather than copied blindly from the example. The hook
should additionally impose a small per-socket in-flight decode limit and an
aggregate admitted-byte budget. Dropping or coalescing observational messages
under pressure is safer than allowing passive telemetry to affect page
availability.

Regression coverage should include:

1. a valid gzip payload just below the decompressed ceiling;
2. a payload that crosses the ceiling by one chunk and confirms reader
   cancellation before full materialization;
3. a small, high-ratio payload that is rejected even though its compressed
   representation is far below 16 MiB;
4. truncated and invalid gzip inputs with stable error handling;
5. several simultaneous accepted messages proving the concurrency budget;
6. normal caption, chat, and LIVE-event fixtures proving compatibility.

Tests should assert bounded bytes and in-flight jobs directly. Peak-RSS checks
can supplement them in an isolated CI job, but should not be the only guard
because process-memory measurements vary across runtimes.

## Summary

TikTok LIVE Companion 0.5.0 validates compressed WebSocket input size but not
the expanded representation. We followed an admitted binary message from the
MAIN-world WebSocket listener through `DecompressionStream` to the unbounded
`Response.arrayBuffer()` sink, where allocation completes before inner
protobuf checks can reject the body. The bounded validation record demonstrates
material amplification from 32,635 compressed bytes to 32 MiB of output and an
approximately 120 MiB RSS increase.

The realistic consequence is local tab or browser-profile availability loss,
not code execution, credential theft, or authorization bypass. Streaming output
accounting, prompt cancellation, and decode backpressure restore the missing
resource invariants. Future variant analysis should examine every other
size-increasing transformation and asynchronous page-event handler for the same
combination of representation-only limits and missing aggregate budgets.
