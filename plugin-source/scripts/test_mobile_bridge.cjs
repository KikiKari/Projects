"use strict";

const assert = require("assert");
const fs = require("fs");
const path = require("path");
const vm = require("vm");

const root = path.resolve(__dirname, "..");
const bridgePath = path.join(root, "mobile-shared", "webview-bridge.js");
const source = fs.readFileSync(bridgePath, "utf8");
new vm.Script(source, { filename: bridgePath });

assert.ok(source.includes('location.hostname !== "www.tiktok.com"'));
assert.ok(source.includes('frameKind: isTop ? "top" : "sub"'));
assert.ok(source.includes("documentStart: true"));
assert.ok(source.includes("MAX_MESSAGE_BYTES = 64 * 1024"));
assert.ok(source.includes("MAX_AUDIO_SECONDS = 12"));
assert.ok(!source.includes('"picture-in-picture"'));
assert.ok(!source.includes('"fullscreen"'));
assert.ok(source.includes("silentSink.gain.value = 0"));
assert.ok(source.includes("audioCapture.processor.connect(silentSink)"));
assert.ok(!source.includes("audioCapture.processor.connect(context.destination)"));
assert.ok(source.includes("ALLOWED_COMMANDS"));
assert.ok(source.includes("addEventListener(\"message\""));
assert.ok(!source.includes(".send ="));
assert.ok(!source.includes("document.cookie"));
assert.ok(!source.includes("localStorage"));
assert.ok(source.includes("MAX_CHAT = 50"));
assert.ok(source.includes("FORCE_RETURN_DELAY_MS = 8_000"));
assert.ok(source.includes("FORCE_RETURN_MAX_ATTEMPTS = 2"));
assert.ok(source.includes('emit("force-start"'));
assert.ok(source.includes("dismissOverlays"));
assert.ok(source.includes("validatedLiveUrl"));
assert.ok(source.includes("seenLiveEventIds.size > 5_000"));
for (const field of ["canonicalUrl", "description", "creatorName", "creatorHandle", "followerText", "followingText", "profileLikesText", "signature", "verified", "livePage"]) assert.ok(source.includes(field));
assert.ok(source.includes('data-tlc-mobile-player'));
assert.ok(source.includes('object-fit:contain'));
assert.ok(source.includes('feature: "player-focus"'));
assert.ok(!source.includes('document.body.innerHTML'));
assert.ok(!source.includes("innerHTML"));

for (const copy of [
  path.join(root, "..", "mobile", "ios", "Resources", "webview-bridge.js"),
  path.join(root, "..", "mobile", "android", "app", "src", "main", "res", "raw", "webview_bridge.js")
]) {
  if (!fs.existsSync(copy)) continue; // platform branches intentionally contain one native tree
  assert.strictEqual(fs.readFileSync(copy, "utf8"), source, `Bridge copy drifted: ${copy}`);
}

console.log("PASS: mobile bridge origin, main-frame, size, command, audio-duration and storage guards");
