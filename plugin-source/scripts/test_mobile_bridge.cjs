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
assert.ok(source.includes("root.top === root"));
assert.ok(source.includes("if (!isTop) return"));
assert.ok(source.includes("MAX_MESSAGE_BYTES = 64 * 1024"));
assert.ok(source.includes("MAX_AUDIO_SECONDS = 12"));
assert.ok(source.includes("QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400"));
assert.ok(source.includes("ALLOWED_COMMANDS"));
assert.ok(source.includes('"set-auto-reconnect"'));
assert.ok(source.includes('"set-limiter"'));
assert.ok(source.includes('"scan-recommendations"'));
assert.ok(source.includes('"cancel-recommendation-scan"'));
assert.ok(source.includes("MAX_MEDIA_URLS = 12"));
assert.ok(source.includes("const mediaUrls = new Map()"));
assert.ok(source.includes('emit("media-url"'));
assert.ok(source.includes("addEventListener(\"message\""));
assert.ok(!source.includes(".send ="));
assert.ok(!source.includes("document.cookie"));
assert.ok(!source.includes("localStorage"));
assert.ok(source.includes('FORCE_RETURN_KEY = "tlc-force-return"'));
assert.ok(source.includes("sessionStorage.getItem(FORCE_RETURN_KEY)"));
assert.ok(!source.includes("sessionStorage.clear"));
assert.ok(!source.includes("innerHTML"));

for (const copy of [
  path.join(root, "..", "mobile", "ios", "Resources", "webview-bridge.js"),
  path.join(root, "..", "mobile", "android", "app", "src", "main", "res", "raw", "webview_bridge.js")
]) {
  assert.strictEqual(fs.readFileSync(copy, "utf8"), source, `Bridge copy drifted: ${copy}`);
}

console.log("PASS: mobile bridge origin, main-frame, size, command, audio-duration and storage guards");
