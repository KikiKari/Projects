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
assert.ok(source.includes("root.top !== root"));
assert.ok(source.includes("MAX_MESSAGE_BYTES = 64 * 1024"));
assert.ok(source.includes("MAX_AUDIO_SECONDS = 12"));
assert.ok(source.includes("ALLOWED_COMMANDS"));
assert.ok(source.includes("addEventListener(\"message\""));
assert.ok(!source.includes(".send ="));
assert.ok(!source.includes("document.cookie"));
assert.ok(!source.includes("localStorage"));
assert.ok(!source.includes("sessionStorage"));
assert.ok(!source.includes("innerHTML"));

for (const copy of [
  path.join(root, "..", "mobile", "ios", "Resources", "webview-bridge.js"),
  path.join(root, "..", "mobile", "android", "app", "src", "main", "res", "raw", "webview_bridge.js")
]) {
  assert.strictEqual(fs.readFileSync(copy, "utf8"), source, `Bridge copy drifted: ${copy}`);
}

console.log("PASS: mobile bridge origin, main-frame, size, command, audio-duration and storage guards");
