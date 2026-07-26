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
const sherpaVoicesPath = path.join(defaultConfigDir, "sherpa-voices.json");
export const VERSION = "0.7.0";
export { defaultConfigPath };

let sherpaInstallPromise = null;
let sherpaInstallStatus = {
  running: false,
  startedAtUtc: null,
  finishedAtUtc: null,
  ok: false,
  error: ""
};

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
    let outputText = "";
    let errorText = "";
    child.stdout.on("data", (chunk) => { outputText += chunk.toString("utf8"); });
    child.stderr.on("data", (chunk) => { errorText += chunk.toString(); });
    child.on("error", reject);
    child.on("close", (code) => code === 0 ? resolve(outputText) : reject(new Error(errorText.trim() || `PowerShell endete mit ${code}`)));
    child.stdin.end(input || "", "utf8");
  });
}

async function runSherpaInstaller() {
  const script = path.join(root, "install-sherpa.ps1");
  try { await fs.access(script); }
  catch (_) { throw Object.assign(new Error("install-sherpa.ps1 fehlt."), { statusCode: 501 }); }
  sherpaInstallStatus = {
    running: true,
    startedAtUtc: new Date().toISOString(),
    finishedAtUtc: null,
    ok: false,
    error: ""
  };
  try {
    await runPowerShell(script, [], "");
    sherpaInstallStatus = {
      ...sherpaInstallStatus,
      running: false,
      finishedAtUtc: new Date().toISOString(),
      ok: true,
      error: ""
    };
  } catch (error) {
    sherpaInstallStatus = {
      ...sherpaInstallStatus,
      running: false,
      finishedAtUtc: new Date().toISOString(),
      ok: false,
      error: String(error?.message || error).slice(0, 500)
    };
    throw error;
  } finally {
    sherpaInstallPromise = null;
  }
}

async function ensureSherpaInstallStarted(installer = runSherpaInstaller, voices = listAvailableVoices) {
  const voiceList = await voices();
  if (voiceList.length) return false;
  if (!sherpaInstallPromise) {
    sherpaInstallPromise = Promise.resolve()
      .then(() => installer())
      .catch((error) => {
        console.error(`Sherpa-Installation fehlgeschlagen: ${String(error?.message || error)}`);
      });
  }
  return true;
}

function cleanVoiceName(value) {
  const voiceName = String(value || "").trim();
  return /^[\p{L}\p{N}\p{P}\p{Zs}]{1,160}$/u.test(voiceName) ? voiceName : "";
}

function cleanAuddToken(value) {
  const token = String(value || "").trim();
  return /^[A-Za-z0-9._~:/+=-]{0,512}$/.test(token) ? token : "";
}

function cleanTtsText(value) {
  return String(value || "")
    .normalize("NFC")
    .replace(/[\u0000-\u001f\u007f-\u009f]/g, " ")
    .replace(/[\u200b-\u200f\u202a-\u202e\u2060-\u206f\ufeff]/g, "")
    .replace(/[\ufe00-\ufe0f\u200d]/g, "")
    .replace(/[\u{1f000}-\u{1faff}\u{2600}-\u{27bf}]/gu, " ")
    .replace(/\p{M}+/gu, "")
    .replace(/\s+/g, " ")
    .trim();
}

function runProcess(command, args, input = "") {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { windowsHide: true, shell: false, stdio: ["pipe", "pipe", "pipe"] });
    const chunks = [];
    let errorText = "";
    child.stdout.on("data", (chunk) => chunks.push(chunk));
    child.stderr.on("data", (chunk) => { errorText += chunk.toString(); });
    child.on("error", reject);
    child.on("close", (code) => code === 0 ? resolve(Buffer.concat(chunks)) : reject(new Error(errorText.trim() || `${command} endete mit ${code}`)));
    child.stdin.end(input || "", "utf8");
  });
}

async function firstExistingFile(directory, predicate) {
  const entries = await fs.readdir(directory, { withFileTypes: true }).catch(() => []);
  for (const entry of entries) {
    const fullPath = path.join(directory, entry.name);
    if (entry.isFile() && predicate(entry.name)) return fullPath;
    if (entry.isDirectory()) {
      const nested = await firstExistingFile(fullPath, predicate);
      if (nested) return nested;
    }
  }
  return "";
}

export async function windowsTts(text, language, voiceName = "") {
  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "tlc-tts-"));
  const input = path.join(tempDir, "speech.txt");
  const output = path.join(tempDir, "speech.wav");
  try {
    await fs.writeFile(input, text, { encoding: "utf8", mode: 0o600 });
    await runPowerShell(path.join(root, "synthesize.ps1"), [language || "auto", output, input, cleanVoiceName(voiceName)], "");
    return await fs.readFile(output);
  } finally {
    await fs.rm(tempDir, { recursive: true, force: true });
  }
}

export async function listWindowsVoices() {
  if (process.platform !== "win32") return [];
  const output = await runPowerShell(path.join(root, "voices.ps1"), [], "");
  const voices = JSON.parse(output || "[]");
  return Array.isArray(voices) ? voices.filter((voice) => voice?.id && voice?.name) : [];
}

export async function listSherpaVoices(configPath = sherpaVoicesPath) {
  let payload;
  try { payload = JSON.parse(await fs.readFile(configPath, "utf8")); }
  catch (error) {
    if (error.code === "ENOENT") return [];
    throw error;
  }
  const voices = Array.isArray(payload?.voices) ? payload.voices : [];
  const result = [];
  for (const voice of voices) {
    const modelDir = String(voice?.modelDir || "");
    if (!modelDir) continue;
    try { await fs.access(modelDir); }
    catch (_) { continue; }
    result.push({
      id: String(voice.id || voice.name || "").trim(),
      name: String(voice.name || voice.id || "").trim(),
      culture: String(voice.culture || "").trim(),
      gender: String(voice.gender || "").trim(),
      engine: "sherpa-onnx"
    });
  }
  return result.filter((voice) => voice.id && voice.name);
}

export async function listAvailableVoices() {
  return listSherpaVoices();
}

async function sherpaTts(text, language, voiceName) {
  const voices = await listSherpaVoices();
  const voice = voices.find((entry) => entry.name === voiceName || entry.id === voiceName);
  if (!voice) throw Object.assign(new Error("Sherpa-Stimme nicht installiert."), { statusCode: 412 });
  const payload = JSON.parse(await fs.readFile(sherpaVoicesPath, "utf8"));
  const model = payload.voices.find((entry) => entry.name === voice.name || entry.id === voice.id);
  const modelDir = String(model?.modelDir || "");
  const executable = String(payload.sherpaExecutable || "sherpa-onnx-offline-tts");
  const onnx = await firstExistingFile(modelDir, (name) => /\.onnx$/i.test(name));
  const tokens = await firstExistingFile(modelDir, (name) => /^tokens\.txt$/i.test(name));
  const dataDir = path.join(modelDir, "espeak-ng-data");
  if (!onnx || !tokens) throw Object.assign(new Error("Sherpa-Modell unvollständig."), { statusCode: 412 });
  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "tlc-sherpa-tts-"));
  const output = path.join(tempDir, "speech.wav");
  try {
    const args = [`--vits-model=${onnx}`, `--vits-tokens=${tokens}`, `--output-filename=${output}`];
    if (await fs.access(dataDir).then(() => true).catch(() => false)) args.push(`--vits-data-dir=${dataDir}`);
    args.push(text);
    await runProcess(executable, args, "");
    return await fs.readFile(output);
  } finally {
    await fs.rm(tempDir, { recursive: true, force: true });
  }
}

export async function companionTts(text, language, voiceName = "") {
  if (voiceName) return sherpaTts(text, language, voiceName);
  return windowsTts(text, language, "");
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

export function createServer({ config, configProvider, configSaver = saveConfig, tts = companionTts, voices = listAvailableVoices, recognize = auddRecognize, sherpaInstaller = runSherpaInstaller } = {}) {
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
        const voiceList = await voices();
        return sendJson(response, 200, {
          ok: true,
          version: VERSION,
          tts: voiceList.length ? "Sherpa-ONNX" : "Standard",
          ttsAvailable: process.platform === "win32",
          sherpaConfigured: voiceList.length > 0,
          sherpaVoiceCount: voiceList.length,
          sherpaInstalling: sherpaInstallStatus.running,
          canInstallSherpa: true,
          auddConfigured: Boolean(currentConfig.auddApiToken),
          songProvider: currentConfig.auddApiToken ? "AudD" : null
        }, allowedOrigin);
      }
      if (request.method === "GET" && request.url === "/v1/voices") {
        return sendJson(response, 200, { voices: await voices() }, allowedOrigin);
      }
      if (request.method === "GET" && request.url === "/v1/sherpa/status") {
        const voiceList = await voices();
        return sendJson(response, 200, {
          ok: true,
          running: sherpaInstallStatus.running,
          configured: voiceList.length > 0,
          voiceCount: voiceList.length,
          startedAtUtc: sherpaInstallStatus.startedAtUtc,
          finishedAtUtc: sherpaInstallStatus.finishedAtUtc,
          error: sherpaInstallStatus.error
        }, allowedOrigin);
      }
      if (request.method === "POST" && request.url === "/v1/sherpa/install") {
        const started = await ensureSherpaInstallStarted(sherpaInstaller, voices);
        const voiceList = await voices();
        return sendJson(response, started ? 202 : 200, {
          ok: true,
          running: started || sherpaInstallStatus.running,
          configured: voiceList.length > 0,
          voiceCount: voiceList.length
        }, allowedOrigin);
      }
      if (request.method === "POST" && request.url === "/v1/config/audd-token") {
        const raw = await readBody(request, 8 * 1024);
        const body = JSON.parse(raw.toString("utf8"));
        const auddApiToken = cleanAuddToken(body.auddApiToken);
        const nextConfig = { ...currentConfig, auddApiToken };
        await configSaver(nextConfig);
        if (currentConfig && typeof currentConfig === "object") currentConfig.auddApiToken = auddApiToken;
        return sendJson(response, 200, { ok: true, auddConfigured: Boolean(auddApiToken) }, allowedOrigin);
      }
      if (request.method === "POST" && request.url === "/v1/tts") {
        const raw = await readBody(request, 64 * 1024);
        const body = JSON.parse(raw.toString("utf8"));
        const text = cleanTtsText(String(body.text || "").slice(0, 4000));
        const language = ["auto", "de-DE", "en-US"].includes(body.language) ? body.language : "auto";
        const voiceName = cleanVoiceName(body.voiceName);
        if (!text.trim()) throw Object.assign(new Error("Leerer TTS-Text."), { statusCode: 400 });
        const wav = await tts(text, language, voiceName);
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
    ensureSherpaInstallStarted().catch((error) => console.error(`Sherpa-Installation konnte nicht gestartet werden: ${String(error?.message || error)}`));
  });
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) main().catch((error) => { console.error(error); process.exitCode = 1; });
