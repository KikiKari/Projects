import { createHash, createPrivateKey, sign } from "node:crypto";

const WINDOW_MS = 60_000;
const MAX_REQUESTS_PER_WINDOW = 30;
const TOKEN_LIFETIME_SECONDS = 5 * 60;
const rateWindows = new Map();
let cachedToken = null;

function base64url(value) {
  return Buffer.from(value).toString("base64url");
}

export function clientAddress(request) {
  const forwarded = String(request.headers?.["x-forwarded-for"] || "").split(",")[0].trim();
  return forwarded || request.socket?.remoteAddress || "unknown";
}

export function consumeRateLimit(key, now = Date.now()) {
  const current = rateWindows.get(key);
  if (!current || current.resetAt <= now) {
    rateWindows.set(key, { count: 1, resetAt: now + WINDOW_MS });
    return { allowed: true, retryAfterSeconds: 0 };
  }
  current.count += 1;
  if (current.count <= MAX_REQUESTS_PER_WINDOW) return { allowed: true, retryAfterSeconds: 0 };
  return { allowed: false, retryAfterSeconds: Math.max(1, Math.ceil((current.resetAt - now) / 1000)) };
}

export function createDeveloperToken(config, nowSeconds = Math.floor(Date.now() / 1000)) {
  const { teamId, keyId, mediaId, privateKey } = config;
  if (![teamId, keyId, mediaId, privateKey].every((value) => typeof value === "string" && value.trim())) {
    const error = new Error("ShazamKit token signing is not configured");
    error.code = "not_configured";
    throw error;
  }
  const expiresAtSeconds = nowSeconds + TOKEN_LIFETIME_SECONDS;
  const header = base64url(JSON.stringify({ alg: "ES256", kid: keyId, typ: "JWT" }));
  const payload = base64url(JSON.stringify({ iss: teamId, iat: nowSeconds, exp: expiresAtSeconds }));
  const signingInput = `${header}.${payload}`;
  const key = createPrivateKey(privateKey.replace(/\\n/g, "\n"));
  const signature = sign("sha256", Buffer.from(signingInput), { key, dsaEncoding: "ieee-p1363" }).toString("base64url");
  return {
    token: `${signingInput}.${signature}`,
    expiresAt: new Date(expiresAtSeconds * 1000).toISOString(),
    mediaId
  };
}

export function getCachedDeveloperToken(config, nowSeconds = Math.floor(Date.now() / 1000)) {
  const cacheKey = createHash("sha256").update([config.teamId, config.keyId, config.mediaId, config.privateKey].join("\0")).digest("hex");
  if (cachedToken?.cacheKey === cacheKey && cachedToken.expiresAtSeconds > nowSeconds + 60) return cachedToken.value;
  const value = createDeveloperToken(config, nowSeconds);
  cachedToken = { cacheKey, expiresAtSeconds: Math.floor(Date.parse(value.expiresAt) / 1000), value };
  return value;
}

function json(response, status, body, headers = {}) {
  response.statusCode = status;
  response.setHeader("Content-Type", "application/json; charset=utf-8");
  response.setHeader("Cache-Control", "no-store");
  response.setHeader("X-Content-Type-Options", "nosniff");
  for (const [name, value] of Object.entries(headers)) response.setHeader(name, value);
  response.end(JSON.stringify(body));
}

export default function handler(request, response) {
  if (request.method !== "POST") {
    response.setHeader("Allow", "POST");
    return json(response, 405, { error: "method_not_allowed" });
  }
  const platform = String(request.headers?.["x-tlc-platform"] || "").toLowerCase();
  if (platform !== "android") return json(response, 400, { error: "invalid_platform" });
  const rate = consumeRateLimit(clientAddress(request));
  if (!rate.allowed) return json(response, 429, { error: "rate_limited" }, { "Retry-After": String(rate.retryAfterSeconds) });
  try {
    const signed = getCachedDeveloperToken({
      teamId: process.env.SHAZAM_TEAM_ID || "",
      keyId: process.env.SHAZAM_KEY_ID || "",
      mediaId: process.env.SHAZAM_MEDIA_ID || "",
      privateKey: process.env.SHAZAM_PRIVATE_KEY || ""
    });
    return json(response, 200, { token: signed.token, expiresAt: signed.expiresAt });
  } catch (error) {
    const code = error?.code === "not_configured" ? "not_configured" : "signing_failed";
    return json(response, code === "not_configured" ? 503 : 500, { error: code });
  }
}
