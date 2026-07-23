import http from "node:http";
import os from "node:os";
import path from "node:path";
import fs from "node:fs/promises";
import crypto from "node:crypto";
import { spawn } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = path.dirname(fileURLToPath(import.meta.url));
const defaultConfigDir = path.join(process.env.LOCALAPPDATA || os.homedir(), "TikTokLiveCompanion");
const defaultConfigPath = path.join(defaultConfigDir, "service.json");
export const VERSION = "0.7.2";
export { defaultConfigPath };

export async function ensureConfig(configPath = defaultConfigPath) {
  try { return JSON.parse(await fs.readFile(configPath, "utf8")); }
  catch (error) {
    if (error.code !== "ENOENT") throw error;
    const config = { pairingCode: crypto.randomBytes(24).toString("base64url"), auddApiToken: "", port: 43117 };
    await fs.mkdir(path.dirname(configPath), { recursive: true });
    await fs.writeFile(configPath, JSON.stringify(config, null, 2), { encoding: "utf8", mode: 0o600 });
    return config;
  }
}

export async function saveConfig(config, configPath = defaultConfigPath) {
  await fs.mkdir(path.dirname(configPath), { recursive: true });
  await fs.writeFile(configPath, JSON.stringify(config, null, 2), { encoding: "utf8", mode: 0o600 });
  return config;
}

function readBody(request, limit) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    let exceeded = Number(request.headers["content-length"] || 0) > limit;
    request.on("data", (chunk) => {
      size += chunk.length;
      if (size > limit) {
        exceeded = true;
        return;
      }
      if (!exceeded) chunks.push(chunk);
    });
    request.on("end", () => exceeded
      ? reject(Object.assign(new Error("Anfrage ist zu groß."), { statusCode: 413 }))
      : resolve(Buffer.concat(chunks))
    );
    request.on("error", reject);
  });
}

function runPowerShell(script, args, input) {
  return new Promise((resolve, reject) => {
    const child = spawn("powershell.exe", ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", script, ...args], {
      windowsHide: true,
      shell: false,
      stdio: ["pipe", "pipe", "pipe"]
    });
    let errorText = "";
    child.stderr.on("data", (chunk) => { errorText += chunk.toString(); });
    child.on("error", reject);
    child.on("close", (code) => code === 0 ? resolve() : reject(new Error(errorText.trim() || `PowerShell endete mit ${code}`)));
    child.stdin.end(input, "utf8");
  });
}

export async function windowsTts(text, language) {
  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "tlc-tts-"));
  const output = path.join(tempDir, "speech.wav");
  try {
    await runPowerShell(path.join(root, "synthesize.ps1"), [language || "auto", output], text);
    return await fs.readFile(output);
  } finally {
    await fs.rm(tempDir, { recursive: true, force: true });
  }
}

export async function auddRecognize(audio, contentType, apiToken, fetchImpl = fetch) {
  if (!apiToken) throw Object.assign(new Error("AudD-Token fehlt. Bitte zuerst den lokalen Dienst einrichten."), { statusCode: 412 });
  const form = new FormData();
  form.append("api_token", apiToken);
  form.append("return", "apple_music");
  form.append("file", new Blob([audio], { type: contentType || "audio/webm" }), "tiktok-live-sample.webm");
  const response = await fetchImpl("https://api.audd.io/", { method: "POST", body: form });
  const payload = await response.json();
  if (!response.ok || payload.status !== "success") throw new Error(payload.error?.error_message || `AudD HTTP ${response.status}`);
  const match = payload.result;
  return match ? {
    match: true,
    title: match.title || "",
    artist: match.artist || "",
    album: match.album || "",
    link: match.song_link || match.apple_music?.url || "",
    timecode: match.timecode || ""
  } : { match: false };
}

function sendJson(response, status, payload, origin = "") {
  response.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    ...(origin ? { "Access-Control-Allow-Origin": origin, "Vary": "Origin" } : {})
  });
  response.end(JSON.stringify(payload));
}

export function createServer({ config, configProvider, tts = windowsTts, recognize = auddRecognize } = {}) {
  if (!config?.pairingCode) throw new Error("Pairing-Code fehlt.");
  return http.createServer(async (request, response) => {
    const currentConfig = configProvider ? await configProvider() : config;
    const origin = String(request.headers.origin || "");
    const allowedOrigin = /^chrome-extension:\/\/[a-p]{32}$/.test(origin) ? origin : "";
    if (origin && !allowedOrigin) return sendJson(response, 403, { error: "Origin nicht erlaubt." });
    if (request.method === "OPTIONS") {
      response.writeHead(204, {
        "Access-Control-Allow-Origin": allowedOrigin,
        "Access-Control-Allow-Headers": "Authorization, Content-Type, X-TLC-Client",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        "Access-Control-Max-Age": "600"
      });
      return response.end();
    }
    const authorization = String(request.headers.authorization || "");
    if (authorization !== `Bearer ${currentConfig.pairingCode}`) return sendJson(response, 401, { error: "Pairing fehlgeschlagen." }, allowedOrigin);
    try {
      if (request.method === "GET" && request.url === "/v1/health") {
        return sendJson(response, 200, {
          ok: true,
          version: VERSION,
          tts: "Windows-Stimmen",
          ttsAvailable: process.platform === "win32",
          auddConfigured: Boolean(currentConfig.auddApiToken),
          songProvider: currentConfig.auddApiToken ? "AudD" : null
        }, allowedOrigin);
      }
      if (request.method === "POST" && request.url === "/v1/tts") {
        const raw = await readBody(request, 64 * 1024);
        const body = JSON.parse(raw.toString("utf8"));
        const text = String(body.text || "").slice(0, 4000);
        const language = ["auto", "de-DE", "en-US"].includes(body.language) ? body.language : "auto";
        if (!text.trim()) throw Object.assign(new Error("Leerer TTS-Text."), { statusCode: 400 });
        const wav = await tts(text, language);
        response.writeHead(200, { "Content-Type": "audio/wav", "Content-Length": wav.length, "Cache-Control": "no-store", "Access-Control-Allow-Origin": allowedOrigin, "Vary": "Origin" });
        return response.end(wav);
      }
      if (request.method === "POST" && request.url === "/v1/recognize") {
        const audio = await readBody(request, 10 * 1024 * 1024);
        const result = await recognize(audio, request.headers["content-type"], currentConfig.auddApiToken);
        return sendJson(response, 200, result, allowedOrigin);
      }
      return sendJson(response, 404, { error: "Unbekannter Endpunkt." }, allowedOrigin);
    } catch (error) {
      return sendJson(response, error.statusCode || 500, { error: String(error.message || error) }, allowedOrigin);
    }
  });
}

async function main() {
  const config = await ensureConfig();
  const server = createServer({ config, configProvider: () => ensureConfig() });
  server.listen(Number(config.port) || 43117, "127.0.0.1", () => {
    console.log(`TikTok LIVE Companion Dienst ${VERSION}: http://127.0.0.1:${Number(config.port) || 43117}`);
    console.log(config.auddApiToken ? "AudD ist eingerichtet." : "AudD-Token fehlt; npm run setup ausführen.");
  });
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) main().catch((error) => { console.error(error); process.exitCode = 1; });
