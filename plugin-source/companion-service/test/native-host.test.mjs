import test from "node:test";
import assert from "node:assert/strict";
import os from "node:os";
import path from "node:path";
import fs from "node:fs/promises";
import {
  decodeNativeMessages,
  encodeNativeMessage,
  handleNativeRequest
} from "../native-host.mjs";

test("native messages use a four-byte little-endian length prefix", () => {
  const first = encodeNativeMessage({ action: "health" });
  const second = encodeNativeMessage({ action: "bootstrap", clientVersion: "0.7.2" });
  assert.equal(first.readUInt32LE(0), first.length - 4);
  const decoded = decodeNativeMessages(Buffer.concat([first, second]));
  assert.deepEqual(decoded.messages, [
    { action: "health" },
    { action: "bootstrap", clientVersion: "0.7.2" }
  ]);
  assert.equal(decoded.remainder.length, 0);
});

test("native decoder preserves incomplete messages", () => {
  const encoded = encodeNativeMessage({ action: "health" });
  const decoded = decodeNativeMessages(encoded.subarray(0, encoded.length - 2));
  assert.equal(decoded.messages.length, 0);
  assert.equal(decoded.remainder.length, encoded.length - 2);
});

test("configureAudd persists the token but never returns it", async (t) => {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), "tlc-native-test-"));
  const configPath = path.join(directory, "service.json");
  t.after(() => fs.rm(directory, { recursive: true, force: true }));
  const response = await handleNativeRequest(
    { action: "configureAudd", token: "top-secret-audd-token" },
    { configPath }
  );
  assert.equal(response.ok, true);
  assert.equal(response.hostVersion, "0.7.2");
  assert.equal(response.auddConfigured, true);
  assert.equal(JSON.stringify(response).includes("top-secret-audd-token"), false);
  const stored = JSON.parse(await fs.readFile(configPath, "utf8"));
  assert.equal(stored.auddApiToken, "top-secret-audd-token");
  assert.ok(stored.pairingCode);
});

test("health reports host version without exposing internal pairing", async (t) => {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), "tlc-native-health-"));
  const configPath = path.join(directory, "service.json");
  t.after(() => fs.rm(directory, { recursive: true, force: true }));
  const response = await handleNativeRequest({ action: "health" }, { configPath });
  assert.equal(response.ok, true);
  assert.equal(response.hostVersion, "0.7.2");
  assert.equal(response.serviceRunning, false);
  assert.equal(Object.hasOwn(response, "pairingCode"), false);
  const bootstrap = await handleNativeRequest({ action: "bootstrap" }, {
    configPath,
    nodeExecutable: process.execPath,
    serverScript: path.join(directory, "missing-server.mjs"),
    startTimeoutMs: 20
  });
  assert.ok(bootstrap.pairingCode.length >= 24);
});
