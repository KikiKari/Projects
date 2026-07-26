import test from "node:test";
import assert from "node:assert/strict";
import { once } from "node:events";
import { auddRecognize, createServer } from "../server.mjs";

async function fixture() {
  const calls = [];
  const server = createServer({
    config: { pairingCode: "pair-test", auddApiToken: "audd-test" },
    tts: async (text, language, voiceName) => { calls.push(["tts", text, language, voiceName]); return Buffer.from("RIFFtest"); },
    voices: async () => [{ id: "Microsoft Hedda Desktop", name: "Microsoft Hedda Desktop", culture: "de-DE", gender: "Female" }],
    recognize: async (audio, type, token) => { calls.push(["recognize", audio.length, type, token]); return { match: true, title: "Test", artist: "Artist" }; }
  });
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  const base = `http://127.0.0.1:${server.address().port}`;
  return { server, base, calls };
}

const headers = { Authorization: "Bearer pair-test", Origin: `chrome-extension://${"a".repeat(32)}`, "X-TLC-Client": "test" };

test("health requires pairing and reports providers", async (t) => {
  const { server, base } = await fixture();
  t.after(() => server.close());
  assert.equal((await fetch(`${base}/v1/health`)).status, 401);
  const response = await fetch(`${base}/v1/health`, { headers });
  assert.equal(response.status, 200);
  const health = await response.json();
  assert.equal(health.version, "0.7.0");
  assert.equal(health.auddConfigured, true);
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
  const response = await fetch(`${base}/v1/tts`, { method: "POST", headers: { ...headers, "Content-Type": "application/json" }, body: JSON.stringify({ text: "Mädchen mögen süße Grüße: ä ö ü Ä Ö Ü ß; Remove-Item", language: "de-DE", voiceName: "Microsoft Hedda Desktop" }) });
  assert.equal(response.status, 200);
  assert.equal(response.headers.get("content-type"), "audio/wav");
  assert.deepEqual(calls[0], ["tts", "Mädchen mögen süße Grüße: ä ö ü Ä Ö Ü ß; Remove-Item", "de-DE", "Microsoft Hedda Desktop"]);
});

test("lists available local voices", async (t) => {
  const { server, base } = await fixture();
  t.after(() => server.close());
  const response = await fetch(`${base}/v1/voices`, { headers });
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {
    voices: [{ id: "Microsoft Hedda Desktop", name: "Microsoft Hedda Desktop", culture: "de-DE", gender: "Female" }]
  });
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
