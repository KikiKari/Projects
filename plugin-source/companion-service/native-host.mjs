import fs from "node:fs/promises";
import http from "node:http";
import path from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";
import { VERSION, defaultConfigPath, ensureConfig, saveConfig } from "./server.mjs";

const root = path.dirname(fileURLToPath(import.meta.url));
const MAX_MESSAGE_SIZE = 1024 * 1024;

export function encodeNativeMessage(value) {
  const body = Buffer.from(JSON.stringify(value), "utf8");
  const header = Buffer.alloc(4);
  header.writeUInt32LE(body.length, 0);
  return Buffer.concat([header, body]);
}

export function decodeNativeMessages(input) {
  const messages = [];
  let offset = 0;
  while (input.length - offset >= 4) {
    const length = input.readUInt32LE(offset);
    if (length > MAX_MESSAGE_SIZE) throw new Error("Native-Messaging-Nachricht ist zu groß.");
    if (input.length - offset - 4 < length) break;
    messages.push(JSON.parse(input.subarray(offset + 4, offset + 4 + length).toString("utf8")));
    offset += 4 + length;
  }
  return { messages, remainder: input.subarray(offset) };
}

function serviceHealth(config, timeoutMs = 700) {
  return new Promise((resolve) => {
    const request = http.request({
      hostname: "127.0.0.1",
      port: Number(config.port) || 43117,
      path: "/v1/health",
      method: "GET",
      headers: {
        Authorization: `Bearer ${config.pairingCode}`,
        "X-TLC-Client": `native-host-${VERSION}`
      },
      timeout: timeoutMs
    }, (response) => {
      const chunks = [];
      response.on("data", (chunk) => chunks.push(chunk));
      response.on("end", () => {
        try {
          const body = JSON.parse(Buffer.concat(chunks).toString("utf8"));
          resolve(response.statusCode === 200 ? body : null);
        } catch (_) {
          resolve(null);
        }
      });
    });
    request.on("timeout", () => request.destroy());
    request.on("error", () => resolve(null));
    request.end();
  });
}

async function waitForService(config, timeoutMs = 5_000) {
  const deadline = Date.now() + timeoutMs;
  do {
    const health = await serviceHealth(config);
    if (health) return health;
    await new Promise((resolve) => setTimeout(resolve, 150));
  } while (Date.now() < deadline);
  return null;
}

export async function ensureService(config, options = {}) {
  const initial = await serviceHealth(config, options.healthTimeoutMs);
  if (initial) return initial;
  const nodeExecutable = options.nodeExecutable || process.execPath;
  const serverScript = options.serverScript || path.join(root, "server.mjs");
  const child = spawn(nodeExecutable, [serverScript], {
    cwd: root,
    detached: true,
    windowsHide: true,
    shell: false,
    stdio: "ignore"
  });
  child.unref();
  return waitForService(config, options.startTimeoutMs);
}

function publicResponse(config, health, includePairing = false, extra = {}) {
  return {
    ok: true,
    hostVersion: VERSION,
    serviceVersion: health?.version || null,
    serviceRunning: Boolean(health),
    versionMatch: !health || health.version === VERSION,
    ttsAvailable: Boolean(health?.ttsAvailable),
    auddConfigured: Boolean(config.auddApiToken),
    ...(includePairing ? { pairingCode: config.pairingCode } : {}),
    ...extra
  };
}

export async function handleNativeRequest(request, options = {}) {
  const configPath = options.configPath || defaultConfigPath;
  let config = await ensureConfig(configPath);
  const action = String(request?.action || "");
  if (action === "configureAudd") {
    const token = String(request?.token || "").trim();
    if (!token) return { ok: false, code: "AUDD_NOT_CONFIGURED", error: "Kein AudD API-Token übergeben." };
    config = await saveConfig({ ...config, auddApiToken: token }, configPath);
    const health = await serviceHealth(config);
    return publicResponse(config, health);
  }
  if (action === "health") {
    return publicResponse(config, await serviceHealth(config));
  }
  if (action === "bootstrap" || action === "ensureService") {
    const health = await ensureService(config, options);
    return publicResponse(config, health, true);
  }
  return { ok: false, code: "UNKNOWN_ACTION", error: "Unbekannte Native-Host-Aktion." };
}

export async function runNativeHost(input = process.stdin, output = process.stdout) {
  let buffered = Buffer.alloc(0);
  input.on("data", async (chunk) => {
    input.pause();
    try {
      buffered = Buffer.concat([buffered, chunk]);
      const decoded = decodeNativeMessages(buffered);
      buffered = decoded.remainder;
      for (const message of decoded.messages) {
        const response = await handleNativeRequest(message);
        output.write(encodeNativeMessage(response));
      }
    } catch (error) {
      output.write(encodeNativeMessage({ ok: false, code: "HOST_ERROR", error: String(error?.message || error) }));
      buffered = Buffer.alloc(0);
    } finally {
      input.resume();
    }
  });
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) {
  fs.access(root).then(() => runNativeHost()).catch(() => process.exit(1));
}
