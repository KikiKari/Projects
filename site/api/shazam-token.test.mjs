import { generateKeyPairSync, verify } from "node:crypto";
import { describe, expect, it } from "vitest";
import handler, { consumeRateLimit, createDeveloperToken, getCachedDeveloperToken } from "./shazam-token.mjs";

describe("ShazamKit developer token", () => {
  it("creates a short-lived ES256 token without embedding the private key", () => {
    const { privateKey, publicKey } = generateKeyPairSync("ec", { namedCurve: "P-256" });
    const result = createDeveloperToken({
      teamId: "TEAM123456",
      keyId: "KEY1234567",
      mediaId: "app.tiktok-live-companion",
      privateKey: privateKey.export({ type: "pkcs8", format: "pem" })
    }, 1_700_000_000);
    const [header, payload, signature] = result.token.split(".");
    expect(JSON.parse(Buffer.from(header, "base64url").toString())).toEqual({ alg: "ES256", kid: "KEY1234567", typ: "JWT" });
    expect(JSON.parse(Buffer.from(payload, "base64url").toString())).toEqual({ iss: "TEAM123456", iat: 1_700_000_000, exp: 1_700_000_300 });
    expect(verify("sha256", Buffer.from(`${header}.${payload}`), { key: publicKey, dsaEncoding: "ieee-p1363" }, Buffer.from(signature, "base64url"))).toBe(true);
    expect(result.token).not.toContain("PRIVATE KEY");
  });

  it("reports missing configuration with a stable code", () => {
    expect(() => createDeveloperToken({ teamId: "", keyId: "", mediaId: "", privateKey: "" })).toThrowError(/not configured/);
    try { createDeveloperToken({ teamId: "", keyId: "", mediaId: "", privateKey: "" }); } catch (error) { expect(error.code).toBe("not_configured"); }
  });

  it("caches a still-valid token without extending its expiry", () => {
    const { privateKey } = generateKeyPairSync("ec", { namedCurve: "P-256" });
    const config = { teamId: "TEAMCACHE1", keyId: "KEYCACHE01", mediaId: "app.cache", privateKey: privateKey.export({ type: "pkcs8", format: "pem" }) };
    const first = getCachedDeveloperToken(config, 1_700_000_000);
    const second = getCachedDeveloperToken(config, 1_700_000_100);
    expect(second).toEqual(first);
  });

  it("bounds requests per address", () => {
    const start = 42_000;
    for (let index = 0; index < 30; index += 1) expect(consumeRateLimit("198.51.100.8", start).allowed).toBe(true);
    expect(consumeRateLimit("198.51.100.8", start).allowed).toBe(false);
    expect(consumeRateLimit("198.51.100.8", start + 60_001).allowed).toBe(true);
  });

  it("returns stable configuration and signing errors without secret material", () => {
    const call = (env) => {
      const original = { ...process.env };
      Object.assign(process.env, env);
      let body = "";
      const response = { headers: {}, setHeader(name, value) { this.headers[name] = value; }, end(value) { body = value; } };
      handler({ method: "POST", headers: { "x-tlc-platform": "android", "x-forwarded-for": `203.0.113.${Math.floor(Math.random() * 100)}` }, socket: {} }, response);
      process.env = original;
      return { status: response.statusCode, body };
    };
    const missing = call({ SHAZAM_TEAM_ID: "", SHAZAM_KEY_ID: "", SHAZAM_MEDIA_ID: "", SHAZAM_PRIVATE_KEY: "" });
    expect(missing).toEqual({ status: 503, body: '{"error":"not_configured"}' });
    const failed = call({ SHAZAM_TEAM_ID: "TEAMFAIL01", SHAZAM_KEY_ID: "KEYFAIL001", SHAZAM_MEDIA_ID: "app.fail", SHAZAM_PRIVATE_KEY: "PRIVATE SECRET" });
    expect(failed.status).toBe(500);
    expect(failed.body).toBe('{"error":"signing_failed"}');
    expect(failed.body).not.toContain("PRIVATE SECRET");
  });
});
