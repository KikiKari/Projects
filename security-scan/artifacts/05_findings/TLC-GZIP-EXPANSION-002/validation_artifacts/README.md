# Reproduction note

The original `proto-main.js` module was loaded directly. A valid outer protobuf push frame carried 32 MiB of zero bytes compressed to 32,635 bytes and marked as gzip. This is well below the hook's 16 MiB compressed-input cap. The unchanged decoder expanded the body before protobuf parsing; process RSS increased by roughly 120 MiB. The subsequent parser error is expected for the zero-filled inner body and proves that decompression completed first.

No target source file was modified.
