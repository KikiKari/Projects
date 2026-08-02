import test from "node:test";
import assert from "node:assert/strict";
import { once } from "node:events";
import fs from "node:fs/promises";
import { auddRecognize, auddValidateToken, createServer } from "../server.mjs";

async function fixture(options = {}) {
  const calls = [];
  const savedConfigs = [];
  const config = { pairingCode: "pair-test", auddApiToken: "audd-test", extensionId: "a".repeat(32), ...(options.config || {}) };
  const voiceProvider = options.voices || (async () => [{ id: "sherpa-de-eva-k", name: "Sherpa Eva", culture: "de-DE", gender: "Female", engine: "sherpa-onnx" }]);
  const catalogProvider = options.catalog || (async () => [{ id: "sherpa-de-eva-k", name: "Sherpa Eva", culture: "de-DE", gender: "Female", engine: "sherpa-onnx", family: "vits", installed: true }]);
  const server = createServer({
    config,
    configSaver: async (nextConfig) => { savedConfigs.push({ ...nextConfig }); Object.assign(config, nextConfig); return nextConfig; },
    tts: async (text, language, voiceName) => { calls.push(["tts", text, language, voiceName]); return Buffer.from("RIFFtest"); },
    voices: voiceProvider,
    catalog: catalogProvider,
    recognize: async (audio, type, token) => { calls.push(["recognize", audio.length, type, token]); return { match: true, title: "Test", artist: "Artist" }; },
    validateAuddToken: options.validateAuddToken || (async () => ({ valid: true })),
    sherpaInstaller: async (voiceId) => { calls.push(["sherpa-install", voiceId || ""]); },
    vlcStatus: options.vlcStatus || (async () => ({ available: true, canInstall: false, platform: "win32" })),
    vlcInstaller: options.vlcInstaller || (async () => { calls.push(["vlc-install"]); })
  });
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  const base = `http://127.0.0.1:${server.address().port}`;
  return { server, base, calls, savedConfigs };
}

const headers = { Authorization: "Bearer pair-test", Origin: `chrome-extension://${"a".repeat(32)}`, "X-TLC-Client": "test" };

test("health requires pairing and reports providers", async (t) => {
  const { server, base } = await fixture();
  t.after(() => server.close());
  assert.equal((await fetch(`${base}/v1/health`)).status, 401);
  const response = await fetch(`${base}/v1/health`, { headers });
  assert.equal(response.status, 200);
  const health = await response.json();
  assert.equal(health.version, "0.7.1");
  assert.equal(health.bootstrapPairing, true);
  assert.equal(health.auddConfigured, true);
  assert.equal(health.bootstrapPending, false);
  assert.equal(health.extensionConfigured, true);
  assert.equal(health.sherpaConfigured, true);
  assert.equal(health.sherpaVoiceCount, 1);
});

test("rejects web origins", async (t) => {
  const { server, base } = await fixture();
  t.after(() => server.close());
  const response = await fetch(`${base}/v1/health`, { headers: { ...headers, Origin: "https://evil.example" } });
  assert.equal(response.status, 403);
});

test("tts passes text via the fixed adapter", async (t) => {
  const { server, base, calls } = await fixture();
  t.after(() => server.close());
  const response = await fetch(`${base}/v1/tts`, { method: "POST", headers: { ...headers, "Content-Type": "application/json" }, body: JSON.stringify({ text: "👑 Mädchen mögen süße Grüße: ä ö ü Ä Ö Ü ß; Remove-Item", language: "de-DE", voiceName: "Sherpa Eva" }) });
  assert.equal(response.status, 200);
  assert.equal(response.headers.get("content-type"), "audio/wav");
  assert.deepEqual(calls[0], ["tts", "Mädchen mögen süße Grüße: ä ö ü Ä Ö Ü ß; Remove-Item", "de-DE", "Sherpa Eva"]);
});

test("lists available local voices", async (t) => {
  const { server, base } = await fixture();
  t.after(() => server.close());
  const response = await fetch(`${base}/v1/voices`, { headers });
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {
    voices: [{ id: "sherpa-de-eva-k", name: "Sherpa Eva", culture: "de-DE", gender: "Female", engine: "sherpa-onnx" }],
    catalog: [{ id: "sherpa-de-eva-k", name: "Sherpa Eva", culture: "de-DE", gender: "Female", engine: "sherpa-onnx", family: "vits", installed: true }]
  });
});

test("starts Sherpa installation through paired local endpoint", async (t) => {
  const { server, base, calls } = await fixture({ voices: async () => [] });
  t.after(() => server.close());
  const response = await fetch(`${base}/v1/sherpa/install`, { method: "POST", headers });
  assert.equal(response.status, 202);
  assert.deepEqual(await response.json(), { ok: true, running: true, configured: false, voiceCount: 0 });
  await new Promise((resolve) => setTimeout(resolve, 10));
  assert.deepEqual(calls[0], ["sherpa-install", ""]);
});

test("reports VLC status and starts only one paired installation", async (t) => {
  const { server, base, calls } = await fixture({
    vlcStatus: async () => ({ available: false, canInstall: true, platform: "win32" }),
    vlcInstaller: async () => { calls.push(["vlc-install"]); await new Promise((resolve) => setTimeout(resolve, 20)); }
  });
  t.after(() => server.close());
  assert.equal((await fetch(`${base}/v1/vlc/status`)).status, 401);
  const status = await fetch(`${base}/v1/vlc/status`, { headers });
  assert.equal(status.status, 200);
  assert.equal((await status.json()).available, false);
  const [first, second] = await Promise.all([
    fetch(`${base}/v1/vlc/install`, { method: "POST", headers }),
    fetch(`${base}/v1/vlc/install`, { method: "POST", headers })
  ]);
  assert.equal(first.status, 202);
  assert.equal(second.status, 202);
  await new Promise((resolve) => setTimeout(resolve, 35));
  assert.equal(calls.filter(([name]) => name === "vlc-install").length, 1);
});

test("VLC installer pins official stable downloads, SHA-256 and VideoLAN signature", async () => {
  const installer = await fs.readFile(new URL("../install-vlc.ps1", import.meta.url), "utf8");
  assert.match(installer, /https:\/\/get\.videolan\.org\/vlc\/last\/win64\//);
  assert.match(installer, /Get-FileHash[^\r\n]+SHA256/);
  assert.match(installer, /Get-AuthenticodeSignature/);
  assert.match(installer, /VideoLAN/);
  assert.match(installer, /Start-Process[^\r\n]+-Verb RunAs/);
  assert.doesNotMatch(installer, /beta|nightly|unstable/i);
});

test("installs only a verified catalog voice", async (t) => {
  const { server, base, calls } = await fixture({
    voices: async () => [],
    catalog: async () => [{ id: "sherpa-ru-irina", name: "Irina", culture: "ru-RU", installed: false }]
  });
  t.after(() => server.close());
  const response = await fetch(`${base}/v1/voices/install`, {
    method: "POST",
    headers: { ...headers, "Content-Type": "application/json" },
    body: JSON.stringify({ voiceId: "sherpa-ru-irina" })
  });
  assert.equal(response.status, 202);
  assert.equal((await response.json()).voiceId, "sherpa-ru-irina");
  await new Promise((resolve) => setTimeout(resolve, 10));
  assert.deepEqual(calls[0], ["sherpa-install", "sherpa-ru-irina"]);
});

test("pairing bootstrap nonce is one-time and short-lived", async (t) => {
  const nonce = "a".repeat(48);
  const { server, base, savedConfigs } = await fixture({ config: { bootstrapNonce: nonce, bootstrapExpiresAtUtc: new Date(Date.now() + 60_000).toISOString() } });
  t.after(() => server.close());
  const first = await fetch(`${base}/v1/pair?nonce=${nonce}`, { headers: { Origin: headers.Origin } });
  assert.equal(first.status, 200);
  assert.equal((await first.json()).pairingCode, "pair-test");
  assert.equal(savedConfigs.length, 1);
  assert.equal("bootstrapNonce" in savedConfigs[0], false);
  assert.equal((await fetch(`${base}/v1/pair?nonce=${nonce}`, { headers: { Origin: headers.Origin } })).status, 401);
});

test("pairing bootstrap rejects a different extension id", async (t) => {
  const nonce = "a".repeat(48);
  const { server, base } = await fixture({ config: { bootstrapNonce: nonce, bootstrapExpiresAtUtc: new Date(Date.now() + 60_000).toISOString() } });
  t.after(() => server.close());
  const response = await fetch(`${base}/v1/pair?nonce=${nonce}`, { headers: { Origin: `chrome-extension://${"b".repeat(32)}` } });
  assert.equal(response.status, 403);
});

test("approved voice catalog pins size and SHA-256 for every model", async () => {
  const catalog = JSON.parse(await fs.readFile(new URL("../voice-catalog.json", import.meta.url), "utf8"));
  assert.ok(catalog.voices.length >= 12);
  for (const voice of catalog.voices) {
    assert.ok(Number.isSafeInteger(voice.bytes) && voice.bytes > 0, `missing approved size for ${voice.id}`);
    assert.match(voice.sha256, /^[a-f0-9]{64}$/, `missing approved SHA-256 for ${voice.id}`);
  }
  assert.equal(catalog.voices.some((voice) => /mk|macedon/i.test(`${voice.id} ${voice.culture} ${voice.name}`)), false);
});

test("Sherpa installer validates and stages archives before promotion", async () => {
  const installer = await fs.readFile(new URL("../install-sherpa.ps1", import.meta.url), "utf8");
  assert.match(installer, /Get-FileHash[^\r\n]+SHA256/);
  assert.match(installer, /Assert-SafeArchiveEntries/);
  assert.match(installer, /symbolischen oder harten Links/);
  assert.match(installer, /\.extract-/);
  assert.ok(installer.indexOf("Assert-ApprovedArchive") < installer.indexOf("& tar -xf"));
  assert.ok(installer.indexOf("Assert-SafeArchiveEntries $Archive") < installer.indexOf("& tar -xf"));
});

test("stores AudD token through the paired local config endpoint", async (t) => {
  const { server, base, savedConfigs } = await fixture();
  t.after(() => server.close());
  const response = await fetch(`${base}/v1/config/audd-token`, {
    method: "POST",
    headers: { ...headers, "Content-Type": "application/json" },
    body: JSON.stringify({ auddApiToken: "new-audd-token" })
  });
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { ok: true, auddConfigured: true });
  assert.equal(savedConfigs.length, 1);
  assert.equal(savedConfigs[0].auddApiToken, "new-audd-token");
});

test("does not store an invalid AudD token", async (t) => {
  const { server, base, savedConfigs } = await fixture({ validateAuddToken: async () => ({ valid: false, code: 900 }) });
  t.after(() => server.close());
  const response = await fetch(`${base}/v1/config/audd-token`, {
    method: "POST",
    headers: { ...headers, "Content-Type": "application/json" },
    body: JSON.stringify({ auddApiToken: "invalid-token" })
  });
  assert.equal(response.status, 422);
  assert.equal(savedConfigs.length, 0);
});

test("does not store an AudD token when validation is unavailable", async (t) => {
  const { server, base, savedConfigs } = await fixture({ validateAuddToken: async () => { throw new Error("offline"); } });
  t.after(() => server.close());
  const response = await fetch(`${base}/v1/config/audd-token`, {
    method: "POST",
    headers: { ...headers, "Content-Type": "application/json" },
    body: JSON.stringify({ auddApiToken: "unverified-token" })
  });
  assert.equal(response.status, 502);
  assert.equal(savedConfigs.length, 0);
});

test("recognition accepts a bounded audio body", async (t) => {
  const { server, base, calls } = await fixture();
  t.after(() => server.close());
  const response = await fetch(`${base}/v1/recognize`, { method: "POST", headers: { ...headers, "Content-Type": "audio/webm" }, body: Buffer.from("audio") });
  assert.equal(response.status, 200);
  assert.equal((await response.json()).title, "Test");
  assert.deepEqual(calls[0], ["recognize", 5, "audio/webm", "audd-test"]);
});

test("rejects oversized TTS requests with 413", async (t) => {
  const { server, base } = await fixture();
  t.after(() => server.close());
  const response = await fetch(`${base}/v1/tts`, {
    method: "POST",
    headers: { ...headers, "Content-Type": "application/json" },
    body: JSON.stringify({ text: "x".repeat(70 * 1024), language: "de-DE" })
  });
  assert.equal(response.status, 413);
});

test("reports a missing AudD token without making a request", async () => {
  await assert.rejects(() => auddRecognize(Buffer.from("audio"), "audio/webm", ""), /AudD-Token fehlt/);
});

test("surfaces AudD provider errors", async () => {
  const fakeFetch = async () => ({
    ok: true,
    status: 200,
    json: async () => ({ status: "error", error: { error_message: "quota exceeded" } })
  });
  await assert.rejects(() => auddRecognize(Buffer.from("audio"), "audio/webm", "token", fakeFetch), /quota exceeded/);
});

test("validates AudD credentials without audio and rejects provider code 900", async () => {
  const accepted = await auddValidateToken("token", async () => ({
    ok: true,
    status: 200,
    json: async () => ({ status: "error", error: { error_code: 700, error_message: "missing file" } })
  }));
  assert.equal(accepted.valid, true);
  const rejected = await auddValidateToken("token", async () => ({
    ok: true,
    status: 200,
    json: async () => ({ status: "error", error: { error_code: 900, error_message: "invalid token" } })
  }));
  assert.deepEqual(rejected, { valid: false, code: 900 });
});
