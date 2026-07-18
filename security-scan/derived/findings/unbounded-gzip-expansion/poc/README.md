# Bounded validation record

This directory documents the bounded defensive validation previously performed
against TikTok LIVE Companion 0.5.0. It intentionally contains no executable
payload or stress-test harness.

## Scope

- The unchanged `proto-main.js` module was loaded directly through its package
  API.
- A valid outer protobuf push frame carried a zero-filled inner body and marked
  it as gzip.
- The input was processed locally. No live or public service was contacted.
- The check was stopped at a 32 MiB decompressed body and was not repeated.

## Recorded result

```text
compressedBytes: 32635
decompressedBytes: 33554432
underHookInputCap: true
decodeMs: 286
rssDeltaBytes: 120217600
postDecompressionParserError: Invalid protobuf field number
runtime: Node.js against the unchanged proto-main.js module
```

The parser rejection was expected because the decompressed inner body was not a
valid fetch-result protobuf. Its value as evidence is ordering: the decoder had
already completed gzip expansion and materialized the full output before the
parser rejected the body.

## Safety note

No execution command is provided. Increasing the output size or running several
decodes concurrently can cause local memory pressure, make a process or browser
profile unresponsive, or trigger process termination. Regression testing for a
fix should instead use a deliberately small configured output ceiling and assert
that streaming cancellation occurs immediately after that ceiling is crossed.
