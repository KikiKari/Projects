# TLC-GZIP-EXPANSION-002 validation

**Disposition:** reportable  
**Confidence:** high (0.88)  
**Method:** targeted package-API reproduction plus static source-to-sink trace

## Rubric

- [x] Remote binary input reaches the decoder through the installed WebSocket hook.
- [x] The existing 16 MiB control applies only to compressed input.
- [x] Decompressed output is materialized without an output byte limit.
- [x] A small input produces materially larger memory work in the unchanged decoder.
- [x] Exceptions are contained, but resource allocation occurs before containment.

## Evidence

`hook.js:28-33` admits every binary frame at or below 16 MiB and starts an asynchronous decode. `proto-main.js:208-211` pipes gzip bytes into `DecompressionStream` and consumes the complete result through `Response.arrayBuffer()`. There is no decompressed-size, aggregate-byte, in-flight-work, or cancellation bound.

The focused reproduction compressed a 32 MiB inner payload to 32,635 bytes, passed it through the unchanged `decodeWebSocketPayload`, and measured an RSS increase of 120,217,600 bytes before an expected inner-parser rejection. The compressed input was about 0.2% of the hook cap.

## Remaining uncertainty

Exact browser tab termination thresholds vary by Chrome version and available memory. This affects impact magnitude, not the proven missing output bound.

## Minimal next step

Enforce a decompressed-byte limit with streaming cancellation and add a small in-flight decode/aggregate-byte budget. The supplied 0.5.0 artifact remains unchanged for this release record.
