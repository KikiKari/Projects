"use strict";

// Execute the real service worker with an in-memory Chrome API. Fixtures contain
// synthetic data only; no browser profile, credentials or live traffic is read.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const { webcrypto } = require("node:crypto");
const { test } = require("node:test");

const extension = path.resolve(__dirname, "../browser-extension");
const core = require(path.join(extension, "content-core.js"));
const exportPrivacy = require(path.join(extension, "export-privacy.js"));

test("0PE-170: startup retry backs off, caps at three attempts and ignores stale documents", () => {
  let state = core.newEmbedSession("test", "creator", 1000);
  const observe = (now, status, documentId = "a", documentStartedAtMs = 1000) => {
    const result = core.advanceEmbedSession(state, { status, documentId, documentStartedAtMs }, now);
    state = result.session;
    return result.action;
  };
  assert.equal(observe(2000, "server-error"), "none");
  assert.equal(state.nextAttemptAtMs, 4000);
  assert.equal(observe(3999, "server-error"), "none");
  assert.equal(observe(4000, "server-error"), "reload");
  assert.equal(state.attempt, 2);
  assert.equal(observe(5000, "playing"), "none");
  assert.equal(state.phase, "loading", "old document cannot complete a newer attempt");
  observe(6000, "unavailable", "b", 4500);
  assert.equal(state.nextAttemptAtMs, 10000);
  assert.equal(observe(10000, "unavailable", "b", 4500), "reload");
  observe(11000, "server-error", "c", 10500);
  assert.equal(state.phase, "failed");
  assert.equal(state.attempt, 3);
  assert.equal(observe(100000, "server-error", "c", 10500), "none");
});

test("0PE-170: playback before retry cancels it, while login/ended/gesture never reload", () => {
  const observation = (status) => ({ status, documentId: "a", documentStartedAtMs: 1000 });
  const initial = core.newEmbedSession("test", "creator", 1000);
  const waiting = core.advanceEmbedSession(initial, observation("server-error"), 2000).session;
  const recovered = core.advanceEmbedSession(waiting, observation("playing"), 3000);
  assert.equal(recovered.session.phase, "playing");
  assert.equal(recovered.session.nextAttemptAtMs, null);
  for (const status of ["login-required", "ended", "awaiting-gesture"]) {
    const result = core.advanceEmbedSession(waiting, observation(status), 6000);
    assert.equal(result.action, "none");
    assert.equal(result.session.nextAttemptAtMs, null);
  }
  assert.equal(core.advanceEmbedSession({ ...initial, phase: "cancelled" }, observation("server-error"), 100000).action, "none");
  assert.equal(core.classifyEmbedObservation({ text: "Server error" }), "server-error");
  assert.equal(core.classifyEmbedObservation({ text: "LIVE is unavailable" }), "unavailable");
  assert.equal(core.classifyEmbedObservation({ text: "Melde dich an für das vollständige Erlebnis" }), "login-required");
  assert.equal(core.classifyEmbedObservation({ playing: true, readyState: 4 }), "playing");
  assert.equal(core.classifyEmbedObservation({ paused: true, readyState: 4 }), "awaiting-gesture");
});

function worker(seed = {}) {
  const clock = { now: seed.now ?? Date.now() };
  class TestDate extends Date {
    constructor(...args) { super(...(args.length ? args : [clock.now])); }
    static now() { return clock.now; }
  }
  const session = structuredClone(seed.session || {});
  const local = structuredClone(seed.local || {});
  const sent = [];
  const broadcasts = [];
  const browserTabs = new Map((seed.tabs || []).map((tab) => [tab.id, structuredClone(tab)]));
  const tabActions = [];
  let nextTabId = 100;
  const listeners = {};
  const alarms = new Map();
  const event = (name) => ({ addListener: (fn) => { listeners[name] = fn; } });
  const storage = (data) => ({
    get: async (key) => structuredClone(key == null ? data : { [key]: data[key] }),
    set: async (patch) => Object.assign(data, structuredClone(patch)),
    remove: async (key) => { delete data[key]; }
  });
  const chrome = {
    alarms: { onAlarm: event("alarm"), create: async (name, info) => alarms.set(name, structuredClone(info)),
      clear: async (name) => alarms.delete(name) },
    storage: { session: storage(session), local: storage(local) },
    sidePanel: { setPanelBehavior: async () => {}, setOptions: async () => {} },
    runtime: {
      onInstalled: event("installed"), onStartup: event("startup"), onMessage: event("message"),
      getManifest: () => ({ version: "0.8.2" }), getURL: (name) => `chrome-extension://test/${name}`,
      sendMessage: async (message) => { broadcasts.push(structuredClone(message)); }
    },
    tabs: {
      onUpdated: event("updated"), onRemoved: event("removed"),
      get: async (id) => {
        if (!browserTabs.has(id)) throw new Error("Tab not found");
        return structuredClone(browserTabs.get(id));
      },
      create: async (options) => {
        const tab = { id: nextTabId++, ...structuredClone(options) };
        browserTabs.set(tab.id, tab);
        tabActions.push({ action: "create", ...tab });
        return structuredClone(tab);
      },
      update: async (id, options) => {
        if (!browserTabs.has(id)) throw new Error("Tab not found");
        if (seed.failNavigation?.(id, options)) throw new Error("Navigation failed");
        Object.assign(browserTabs.get(id), structuredClone(options));
        tabActions.push({ action: "update", id, ...structuredClone(options) });
        return structuredClone(browserTabs.get(id));
      },
      remove: async (id) => { browserTabs.delete(id); tabActions.push({ action: "remove", id }); },
      reload: async (id) => { if (!browserTabs.has(id)) throw new Error("Tab not found"); tabActions.push({ action: "reload", id }); },
      sendMessage: async (id, message) => {
        sent.push({ id, ...structuredClone(message) });
        return seed.tabReply ? seed.tabReply(id, message) : message.type === "TLC_RECOVERY_PREFLIGHT" ? { shouldReload: true } : {};
      }
    },
    scripting: { executeScript: async () => [] },
    webRequest: { onBeforeRequest: event("request") }
  };
  const context = vm.createContext({ chrome, TLC_CONTENT_CORE: core, TLC_EXPORT_PRIVACY: exportPrivacy, TLCPipelines: { publish: async () => {}, message: async () => {} }, importScripts() {},
    structuredClone, URL, Date: seed.now == null ? Date : TestDate, console, crypto: webcrypto, setTimeout, clearTimeout, fetch: async () => null });
  vm.runInContext(fs.readFileSync(path.join(extension, "background.js"), "utf8"), context);
  const send = (type, tabId, extra = {}) => new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error(`No response: ${type}`)), seed.responseTimeoutMs || 1000);
    listeners.message({ type, tabId, ...extra }, {}, (value) => {
      clearTimeout(timeout);
      if (!value.ok) reject(new Error(value.error || type));
      else resolve(structuredClone(value));
    });
  });
  return { context, send, session, local, sent, broadcasts, browserTabs, tabActions, clock, alarms,
    fireAlarm: (name) => listeners.alarm({ name }) };
}

test("0PE-177: percentage reaches content and persists only after successful activation", async () => {
  const w = worker({ tabReply: async () => ({ activated: true }) });
  await w.send("TLC_PLAYER_ACTION", 7, { action: "set-limiter", enabled: true, strength: 75 });
  assert.equal(w.sent.at(-1).strength, 75);
  assert.equal(w.local["tlc-settings"].limiterStrength, 75);
  const rejected = worker({ local: w.local, tabReply: async () => ({ activated: false, reason: "AudioWorklet unavailable" }) });
  await rejected.send("TLC_PLAYER_ACTION", 7, { action: "set-limiter", enabled: true, strength: 100 });
  assert.equal(rejected.local["tlc-settings"].limiterStrength, 75);
  await w.send("TLC_PLAYER_ACTION", 7, { action: "set-limiter", enabled: true, thresholdDbfs: -30 });
  assert.equal(w.local["tlc-settings"].limiterStrength, 100);
});

test("0PE-170: worker wake restores active Embed deadlines without another navigation", async () => {
  const w = worker({ now: 5000, session: {
    "tlc-embed-7": { phase: "loading", startedAtMs: 1000 },
    "tlc-embed-8": { phase: "playing", startedAtMs: 1000 },
    "tlc-embed-9": { phase: "retry-wait", startedAtMs: -100000 }
  }});
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(w.alarms.get("tlc-embed-deadline-7").when, 91000);
  assert.equal(w.alarms.has("tlc-embed-deadline-8"), false);
  assert.equal(w.alarms.get("tlc-embed-deadline-9").when, 5001);
  assert.equal(w.tabActions.length, 0);
});

test("0PE-170: restored expired session terminates, cancelled session stays cancelled", async () => {
  const initial = core.newEmbedSession("restart-test", "creator", 1000);
  const w = worker({ now: 95000,
    tabs: [{ id: 7, url: "https://www.tiktok.com/embed/live/@creator" }],
    session: { "tlc-embed-7": initial, "tlc-embed-8": { ...initial, phase: "cancelled" } }
  });
  await new Promise(resolve => setImmediate(resolve));
  await w.fireAlarm("tlc-embed-deadline-7");
  assert.equal(w.session["tlc-embed-7"].phase, "failed");
  assert.equal(w.session["tlc-embed-7"].reason, "timeout");
  assert.equal(w.alarms.has("tlc-embed-deadline-7"), false);
  assert.equal(w.alarms.has("tlc-embed-deadline-8"), false);
  await w.fireAlarm("tlc-embed-deadline-8");
  assert.equal(w.session["tlc-embed-8"].phase, "cancelled");
  assert.equal(w.tabActions.length, 0);
});

test("0PE-173: real hook separates socket creation, open, first frame and first decoded kinds", async () => {
  const posts = [];
  let tick = 100;
  class Socket {
    constructor() { this.listeners = {}; }
    addEventListener(name, listener) { (this.listeners[name] ||= []).push(listener); }
    emit(name, event = {}) { for (const listener of this.listeners[name] || []) listener(event); }
  }
  const window = { WebSocket: Socket, postMessage: (message) => posts.push(structuredClone(message)) };
  window[Symbol.for("tiktok-live-companion.proto")] = { decodeWebSocketPayload: async () => ({
    captions: [{ contents: [{ text: "PRIVATE-CAPTION" }] }], chatMessages: [{ content: "PRIVATE-CHAT" }], liveEvents: [], giftMessages: []
  }) };
  const context = vm.createContext({ window, location: { origin: "https://www.tiktok.com", href: "https://www.tiktok.com/@creator/live", pathname: "/@creator/live" },
    crypto: webcrypto, performance: { now: () => tick }, Date, URL, console });
  const source = fs.readFileSync(path.join(extension, "hook.js"), "utf8");
  vm.runInContext(source, context);
  const socket = new window.WebSocket("wss://example.com/PRIVATE-PATH?token=PRIVATE-TOKEN");
  tick = 120; socket.emit("open");
  tick = 130; socket.emit("message", { data: "PRIVATE-TEXT-FRAME" });
  tick = 140; socket.emit("message", { data: new Uint8Array([1]) });
  await new Promise((resolve) => setImmediate(resolve));
  socket.emit("message", { data: new Uint8Array([2]) });
  await new Promise((resolve) => setImmediate(resolve));
  tick = 160; socket.emit("close", { code: 1006, wasClean: false, reason: "PRIVATE-CLOSE" });
  const traces = posts.filter((message) => message.type === "socket-telemetry").map((message) => message.telemetry);
  assert.deepEqual(traces.map((entry) => entry.stage), ["socket-created", "socket-open", "first-frame", "first-decoded-message", "first-decoded-message", "socket-close"]);
  assert.deepEqual(traces.filter((entry) => entry.kind).map((entry) => entry.kind), ["caption", "chat"]);
  assert.equal(new Set(traces.map((entry) => entry.socketId)).size, 1);
  assert.equal(traces[2].elapsedMs, 30);
  assert.equal(traces.at(-1).closeCode, 1006);
  assert.ok(!JSON.stringify(traces).includes("PRIVATE-"));
  new window.WebSocket("wss://example.com/second");
  const second = posts.at(-1).telemetry;
  assert.notEqual(second.socketId, traces[0].socketId);
  assert.equal(second.documentId, traces[0].documentId);
  const wrapped = window.WebSocket;
  vm.runInContext(source, context);
  assert.equal(window.WebSocket, wrapped, "reinjection must not wrap twice");
});

test("0PE-168: only decoded live connections affect status; closing old socket preserves its replacement", async () => {
  const posts = [];
  class Socket {
    constructor() { this.listeners = {}; }
    addEventListener(name, listener) { this.listeners[name] = listener; }
    emit(name, event = {}) { this.listeners[name]?.(event); }
  }
  const window = { WebSocket: Socket, postMessage: (message) => posts.push(structuredClone(message)) };
  window[Symbol.for("tiktok-live-companion.proto")] = { decodeWebSocketPayload: async (data) => ({
    captions: [], chatMessages: [], giftMessages: [], liveEvents: data[0] === 1 ? [{ type: "test" }] : []
  }) };
  const context = vm.createContext({ window, location: { origin: "https://www.tiktok.com", href: "https://www.tiktok.com/@creator/live", pathname: "/@creator/live" },
    crypto: webcrypto, performance: { now: () => 100 }, Date, URL, console });
  vm.runInContext(fs.readFileSync(path.join(extension, "hook.js"), "utf8"), context);
  const status = () => posts.filter((entry) => entry.type === "hook-status").at(-1).hook;
  const old = new window.WebSocket("wss://example.com/old");
  old.emit("open");
  assert.equal(status().connected, false, "socket-open alone does not prove LIVE data");
  old.emit("message", { data: new Uint8Array([1]) });
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(status().connected, true);
  const replacement = new window.WebSocket("wss://example.com/replacement");
  replacement.emit("open");
  replacement.emit("message", { data: new Uint8Array([1]) });
  await new Promise((resolve) => setImmediate(resolve));
  old.emit("close", { code: 1000, wasClean: true });
  assert.equal(status().connected, true);
  assert.equal(status().endpoint, "wss://example.com/replacement");
  const failed = new window.WebSocket("wss://example.com/failed");
  failed.emit("open");
  failed.emit("message", { data: new Uint8Array([0]) });
  await new Promise((resolve) => setImmediate(resolve));
  failed.emit("close", { code: 1006, wasClean: false });
  assert.equal(status().connected, true, "a never-opened socket cannot disconnect a live one");
  replacement.emit("close", { code: 1006, wasClean: false });
  assert.equal(status().connected, false);
  assert.equal(posts.filter((entry) => entry.telemetry?.stage === "socket-close").length, 3);
  const delayed = new window.WebSocket("wss://example.com/delayed");
  delayed.emit("open");
  delayed.emit("message", { data: new Uint8Array([1]) });
  delayed.emit("close", { code: 1000, wasClean: true });
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(status().connected, false, "late decode cannot revive a closed socket");
});

test("0PE-173: socket telemetry survives the real worker privacy boundary without content or URLs", async () => {
  const w = worker({ session: { "tlc-tab-7": { recoveryConfigVersion: 1, debug: { enabled: true, entries: [] } } } });
  const socket = { documentId: webcrypto.randomUUID(), socketId: webcrypto.randomUUID(), stage: "first-frame", mode: "normal",
    atUtc: new Date().toISOString(), elapsedMs: 123, payload: "PRIVATE-FRAME", url: "wss://example.com/PRIVATE-URL" };
  await w.send("TLC_DEBUG_EVENT", 7, { event: "socket-telemetry", detail: { socket } });
  const { report } = await w.send("TLC_GET_DEBUG_REPORT", 7);
  const entry = report.debug.entries.find((item) => item.event === "socket-telemetry");
  assert.equal(entry.detail.socket.socketId, socket.socketId);
  assert.equal(entry.detail.socket.elapsedMs, 123);
  assert.ok(!JSON.stringify(entry).includes("PRIVATE-"));
  assert.deepEqual(exportPrivacy.debugEntry(entry), entry);
});

test("0PE-173: recovery records actual wait separately from configured delay and ignores duplicate or older requests", async () => {
  const w = worker({ now: 5000, tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }], session: {
    "tlc-tab-7": { recoveryConfigVersion: 1, quickRecoverEnabled: true, quickRecoverSeconds: 1, debug: { enabled: true, entries: [] } }
  } });
  const recoveryAttempt = { id: webcrypto.randomUUID(), documentId: webcrypto.randomUUID(), detectedAtMs: 3000,
    scheduledAtMs: 4000, requestedAtMs: 4500, configuredDelayMs: 1000, payload: "PRIVATE-DATA" };
  assert.equal((await w.send("TLC_QUICK_RECOVER", 7, { reason: "video-not-ready", recoveryAttempt })).reloading, true);
  const { report } = await w.send("TLC_GET_DEBUG_REPORT", 7);
  const records = report.debug.entries.filter((entry) => entry.detail.recoveryAttempt);
  assert.equal(records.length, 2);
  assert.equal(records[0].detail.recoveryAttempt.actualWaitMs, 2000);
  assert.ok(records.every((entry) => entry.detail.controller === "player-quick-recovery"));
  assert.equal(records[0].detail.recoveryAttempt.scheduleOverrunMs, 1000);
  assert.equal(records[1].detail.recoveryAttempt.outcome, "reload-requested");
  assert.ok(!JSON.stringify(records).includes("PRIVATE-"));
  assert.equal((await w.send("TLC_QUICK_RECOVER", 7, { recoveryAttempt })).reason, "stale-attempt");
  assert.equal((await w.send("TLC_QUICK_RECOVER", 7, { recoveryAttempt: { ...recoveryAttempt, id: webcrypto.randomUUID() } })).reason, "stale-attempt");
  assert.equal(w.tabActions.filter((action) => action.action === "reload").length, 1);
});

test("0PE-173: mode switches cancel pending recovery and late playback cannot complete it", async () => {
  for (const mode of ["TLC_OPEN_EMBED_LIVE", "TLC_OPEN_NORMAL_LIVE"]) {
    const w = worker({ now: 5000, tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }], session: {
      "tlc-tab-7": { recoveryConfigVersion: 1, quickRecoverEnabled: true, debug: { enabled: true, entries: [] } }
    } });
    await w.send("TLC_QUICK_RECOVER", 7, { reason: "video-error" });
    w.clock.now = 6000;
    await w.send(mode, 7);
    const attempt = w.session["tlc-tab-7"].recovery.attempt;
    assert.equal(attempt.outcome, "cancelled");
    assert.equal(attempt.endedAtMs, 6000);
    w.browserTabs.get(7).url = "https://www.tiktok.com/@creator/live";
    w.clock.now = 8000;
    await w.send("TLC_RECOVERY_MEDIA_OBSERVATION", 7, { observation: {
      documentId: webcrypto.randomUUID(), documentStartedAtMs: 7000, playing: true
    } });
    assert.equal(w.session["tlc-tab-7"].recovery.attempt.completedAtMs, undefined);
    const { report } = await w.send("TLC_GET_DEBUG_REPORT", 7);
    const records = report.debug.entries.filter((entry) => entry.event === "reconnect-cancelled");
    assert.equal(records.length, 1);
    assert.equal(records[0].detail.recoveryAttempt.endedAtMs, 6000);
    assert.equal(records[0].detail.recoveryAttempt.outcome, "cancelled");
  }
});

test("0PE-173: a newer recovery exports the old attempt as superseded", async () => {
  const w = worker({ now: 5000, tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }], session: {
    "tlc-tab-7": { recoveryConfigVersion: 1, quickRecoverEnabled: true, debug: { enabled: true, entries: [] } }
  } });
  await w.send("TLC_QUICK_RECOVER", 7, { reason: "video-error" });
  const oldId = w.session["tlc-tab-7"].recovery.attempt.id;
  w.clock.now = 15000;
  await w.send("TLC_QUICK_RECOVER", 7, { reason: "video-not-ready" });
  assert.notEqual(w.session["tlc-tab-7"].recovery.attempt.id, oldId);
  const { report } = await w.send("TLC_GET_DEBUG_REPORT", 7);
  const records = report.debug.entries.filter((entry) => entry.event === "reconnect-superseded");
  assert.equal(records.length, 1);
  assert.equal(records[0].detail.recoveryAttempt.id, oldId);
  assert.equal(records[0].detail.recoveryAttempt.outcome, "superseded");
  assert.equal(records[0].detail.recoveryAttempt.endedAtMs, 15000);
});

test("0PE-173: legacy recovery never fabricates detection or interruption duration", async () => {
  const w = worker({ now: 5000, tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }], session: {
    "tlc-tab-7": { recoveryConfigVersion: 1, quickRecoverEnabled: true, quickRecoverSeconds: 3, debug: { enabled: true, entries: [] } }
  } });
  await w.send("TLC_QUICK_RECOVER", 7, { reason: "video-error" });
  const attempt = w.session["tlc-tab-7"].recovery.attempt;
  assert.equal(attempt.detectedAtMs, null);
  assert.equal(attempt.actualWaitMs, null);
  assert.equal(attempt.configuredDelayMs, 3000);
});

test("0PE-167: mode request received during pending preflight prevents an obsolete reload", async () => {
  for (const mode of ["TLC_OPEN_EMBED_LIVE", "TLC_OPEN_NORMAL_LIVE"]) {
    let release, started;
    const entered = new Promise((resolve) => { started = resolve; });
    const preflight = new Promise((resolve) => { release = resolve; });
    const w = worker({ tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }],
      tabReply: (_id, message) => {
        if (message.type !== "TLC_RECOVERY_PREFLIGHT") return {};
        started(); return preflight;
      }, session: { "tlc-tab-7": { recoveryConfigVersion: 1, quickRecoverEnabled: true } }
    });
    const recovery = w.send("TLC_QUICK_RECOVER", 7, { reason: "video-paused" });
    await entered;
    const switchMode = w.send(mode, 7);
    release({ shouldReload: true, softRecovery: "play-unconfirmed" });
    assert.equal((await recovery).reason, "stale-attempt");
    await switchMode;
    assert.equal(w.tabActions.filter((action) => action.action === "reload").length, 0);
  }
});

test("0PE-167: recovery received after a queued mode switch cannot reload the source page", async () => {
  for (const mode of ["TLC_OPEN_EMBED_LIVE", "TLC_OPEN_NORMAL_LIVE"]) {
    const w = worker({ tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }],
      tabReply: () => ({ shouldReload: true }), session: {
        "tlc-tab-7": { recoveryConfigVersion: 1, quickRecoverEnabled: true }
      } });
    const switchMode = w.send(mode, 7);
    const recovery = w.send("TLC_QUICK_RECOVER", 7, { reason: "video-paused" });
    await Promise.all([switchMode, recovery]);
    assert.equal(w.tabActions.filter((action) => action.action === "reload").length, 0);
  }
});

test("0PE-167: completed and failed mode requests release their recovery guard", async () => {
  for (const fail of [false, true]) {
    const w = worker({ tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }],
      failNavigation: () => fail,
      tabReply: () => ({ shouldReload: true }), session: {
        "tlc-tab-7": { recoveryConfigVersion: 1, quickRecoverEnabled: true }
      } });
    if (fail) await assert.rejects(w.send("TLC_OPEN_EMBED_LIVE", 7));
    else await w.send("TLC_OPEN_NORMAL_LIVE", 7);
    const result = await w.send("TLC_QUICK_RECOVER", 7, { reason: "video-error" });
    assert.equal(result.reloading, true, "a finished mode request must not leave recovery permanently blocked");
  }
});

test("0PE-167: soft recovery outcome survives worker state writes and sanitized export", async () => {
  for (const softRecovery of ["play-resumed", "play-unconfirmed"]) {
    const w = worker({ tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }],
      tabReply: () => ({ softRecovery, shouldReload: softRecovery !== "play-resumed" }), session: {
        "tlc-tab-7": { recoveryConfigVersion: 1, quickRecoverEnabled: true, debug: { enabled: true, entries: [] } }
      } });
    await w.send("TLC_QUICK_RECOVER", 7, { reason: "video-paused" });
    const { report } = await w.send("TLC_GET_DEBUG_REPORT", 7);
    assert.equal(report.debug.entries.find((entry) => entry.event === "reconnect-soft-recovery").detail.reason, softRecovery);
    assert.equal(w.tabActions.filter((action) => action.action === "reload").length, softRecovery === "play-resumed" ? 0 : 1);
  }
});

test("0PE-167: missing or stalled preflight never blindly reloads and releases the event queue", async () => {
  for (const reply of [() => ({}), () => Promise.reject(new Error("No receiver")), () => new Promise(() => {})]) {
    const w = worker({ responseTimeoutMs: 4000, tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }],
      tabReply: reply, session: { "tlc-tab-7": { recoveryConfigVersion: 1, quickRecoverEnabled: true, debug: { enabled: true, entries: [] } } }
    });
    const result = await w.send("TLC_QUICK_RECOVER", 7, { reason: "video-error" });
    assert.equal(result.reason, "preflight-unavailable");
    assert.equal(w.tabActions.filter((action) => action.action === "reload").length, 0);
    await w.send("TLC_DEBUG_EVENT", 7, { event: "reconnect-skipped", detail: { reason: "stale-attempt" } });
    const { report } = await w.send("TLC_GET_DEBUG_REPORT", 7);
    assert.ok(report.debug.entries.some((entry) => entry.detail.reason === "preflight-unavailable"));
  }
});

test("0PE-167: fresh preflight cancels obsolete recovery instead of reloading recovered playback", async () => {
  const documentId = webcrypto.randomUUID();
  for (const reply of [{ documentId, shouldReload: false }, { documentId: webcrypto.randomUUID(), shouldReload: true }]) {
    const w = worker({ tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }],
      tabReply: (_id, message) => message.type === "TLC_RECOVERY_PREFLIGHT" ? reply : {}, session: {
        "tlc-tab-7": { recoveryConfigVersion: 1, quickRecoverEnabled: true, quickRecoverSeconds: 1, debug: { enabled: true, entries: [] } }
      } });
    const result = await w.send("TLC_QUICK_RECOVER", 7, { reason: "video-not-ready", recoveryAttempt: { documentId, id: webcrypto.randomUUID() } });
    assert.equal(result.skipped, true);
    assert.equal(w.tabActions.filter((action) => action.action === "reload").length, 0);
    assert.equal(w.session["tlc-tab-7"].debug.entries.at(-1).event, "reconnect-skipped");
  }
});

test("0PE-167: explicit user pause suppresses media recovery without hiding genuine failures after resume", () => {
  const video = { paused: true, readyState: 4, error: null, ended: false };
  assert.equal(core.mediaRecoveryReason(video, { userPaused: true }), "");
  assert.equal(core.mediaRecoveryReason(video), "video-paused");
  assert.equal(core.mediaRecoveryReason({ ...video, paused: false }), "");
  assert.equal(core.mediaRecoveryReason({ ...video, error: {} }), "video-error");
  assert.equal(core.mediaRecoveryReason({ ...video, ended: true }), "video-ended");
  assert.equal(core.mediaRecoveryReason({ ...video, paused: false, readyState: 1 }), "video-not-ready");
  assert.equal(core.mediaRecoveryReason(video, { graceElapsed: false }), "");
  assert.equal(core.mediaRecoveryReason(null), "");
});

test("0PE-167: actual content message handlers preserve Sidepanel pause and re-enable recovery after resume", async () => {
  class FakeElement {
    isConnected = true;
    getBoundingClientRect() { return { width: 640, height: 360 }; }
    matches() { return true; }
    closest(selector) { return selector === "#tlc-media-fallback" ? null : this; }
    getAttribute() { return null; }
    dispatchEvent() {}
    contains(target) { return target === this; }
  }
  const video = Object.assign(new FakeElement(), { paused: false, ended: false, error: null, readyState: 4, volume: 1,
    muted: false, pause() { this.paused = true; }, async play() { this.paused = false; } });
  const control = new FakeElement();
  const dialog = Object.assign(new FakeElement(), { innerText: "Log in to TikTok", textContent: "Log in to TikTok" });
  let showDialog = false;
  let listener;
  const domListeners = {};
  let now = 1000;
  class ContentDate extends Date { static now() { return now; } }
  const document = { documentElement: null, title: "LIVE", addEventListener: (name, fn) => { (domListeners[name] ||= []).push(fn); }, getElementById: () => null,
    querySelector: () => null, querySelectorAll: (selector) => selector === "video" ? [video] : selector.includes('[data-e2e="play-icon"]') ? [control] : showDialog && selector.includes('[role="dialog"]') ? [dialog] : [] };
  const controlPosts=[], runtimePosts=[], windowListeners={};
  const contentWindow={postMessage:m=>controlPosts.push(m),addEventListener:(k,f)=>{windowListeners[k]=f;}};
  const chrome = { runtime: { onMessage: { addListener: (fn) => { listener = fn; } }, sendMessage: async m => {runtimePosts.push(m);return { enabled: false };} } };
  const context = vm.createContext({ TLC_CONTENT_CORE: core, chrome, document, window: contentWindow,
    location: { pathname: "/@creator/live", href: "https://www.tiktok.com/@creator/live" }, crypto: webcrypto,
    Element: FakeElement, HTMLMediaElement: { HAVE_CURRENT_DATA: 2 },
    getComputedStyle: () => ({ display: "block", visibility: "visible", opacity: "1" }),
    Date: ContentDate, URL, console, setTimeout: (fn) => setImmediate(fn), clearTimeout: clearImmediate });
  vm.runInContext(fs.readFileSync(path.join(extension, "content.js"), "utf8"), context);
  await new Promise((resolve) => setImmediate(resolve));
  const send = (message) => new Promise((resolve) => listener(message, {}, resolve));
  await send({ type: "TLC_SET_TAB_ACTIVE", enabled: true, quickRecoverEnabled: true, quickRecoverSeconds: 1 });
  await send({type:"TLC_HOOK_RECONNECT_CONFIG",enabled:true,armed:true,seconds:2});
  assert.equal(controlPosts.at(-1).enabled,true);
  assert.equal(controlPosts.at(-1).seconds,2);
  windowListeners.message({source:contentWindow,origin:undefined,data:{source:"tiktok-live-companion",version:1,type:"hook-recovery",recovery:{phase:"connecting"}}});
  const forwarded=runtimePosts.find(m=>m.type==="TLC_HOOK_RECOVERY");
  assert.equal(forwarded.recovery.phase,"connecting");
  assert.ok(forwarded.recovery.contentDocumentId);
  now = 2000;
  const paused = await send({ type: "TLC_PLAYER_ACTION", action: "toggle-play" });
  assert.equal(paused.activated, true, paused.reason);
  assert.equal(video.paused, true);
  assert.equal((await send({ type: "TLC_RECOVERY_PREFLIGHT", reason: "video-paused" })).shouldReload, false);
  const resumed = await send({ type: "TLC_PLAYER_ACTION", action: "toggle-play" });
  assert.equal(resumed.activated, true, resumed.reason);
  assert.equal(video.paused, false);
  // Arm against the now healthy player, then simulate a real media error.
  await send({ type: "TLC_RECOVERY_PREFLIGHT", reason: "video-error" });
  video.error = { code: 2 };
  assert.equal((await send({ type: "TLC_RECOVERY_PREFLIGHT", reason: "video-error" })).shouldReload, true);
  video.error = null;
  const emit = (name, event) => domListeners[name]?.forEach((fn) => fn(event));
  emit("click", { target: control, isTrusted: true });
  video.pause();
  emit("pause", { target: video });
  assert.equal((await send({ type: "TLC_RECOVERY_PREFLIGHT", reason: "video-paused" })).shouldReload, false, "native trusted pause is respected");
  await video.play(); emit("play", { target: video });
  emit("click", { target: control, isTrusted: false });
  video.pause(); emit("pause", { target: video });
  assert.equal((await send({ type: "TLC_RECOVERY_PREFLIGHT", reason: "video-paused" })).shouldReload, true, "script click must not assert user intent");
  await video.play(); emit("play", { target: video });
  emit("click", { target: control, isTrusted: true });
  now += 501;
  video.pause(); emit("pause", { target: video });
  assert.equal((await send({ type: "TLC_RECOVERY_PREFLIGHT", reason: "video-paused" })).shouldReload, true, "expired intent must not hide later failures");
  await video.play(); emit("play", { target: video });
  now = 60000;
  showDialog = true;
  video.currentTime = 10;
  await send({ type: "TLC_RECOVERY_PREFLIGHT", reason: "login-dialog" });
  now += 40;
  video.currentTime = 10.04;
  assert.equal((await send({ type: "TLC_RECOVERY_PREFLIGHT", reason: "login-dialog" })).shouldReload, false, "advancing media must survive an overlay");
  now += 251;
  assert.equal((await send({ type: "TLC_RECOVERY_PREFLIGHT", reason: "login-dialog" })).shouldReload, true, "stale progress cannot mask a later interruption");
  showDialog = false;
  let playCalls = 0;
  video.play = async () => { playCalls++; video.paused = false; video.currentTime += 0.5; };
  video.paused = true;
  const soft = await send({ type: "TLC_RECOVERY_PREFLIGHT", reason: "video-paused" });
  assert.equal(soft.shouldReload, false);
  assert.equal(soft.softRecovery, "play-resumed");
  assert.equal(playCalls, 1);
  video.paused = true;
  now += 1000;
  video.play = () => { playCalls++; return Promise.reject(new Error("NotAllowedError")); };
  const rejected = await send({ type: "TLC_RECOVERY_PREFLIGHT", reason: "video-paused" });
  assert.equal(rejected.shouldReload, true);
  assert.equal(rejected.softRecovery, "play-unconfirmed");
  video.paused = false;
  emit("click", { target: control, isTrusted: true });
  video.pause(); emit("pause", { target: video });
  assert.equal((await send({ type: "TLC_RECOVERY_PREFLIGHT", reason: "video-paused" })).shouldReload, false);
  assert.equal(playCalls, 2, "user pause must never invoke play()");
});

test("0PE-173: worker correlates only same-stream new-document sockets, never page-supplied attempt IDs", async () => {
  const attemptId = webcrypto.randomUUID(), oldDocument = webcrypto.randomUUID(), newDocument = webcrypto.randomUUID();
  const w = worker({ now: 9000, tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }], session: {
    "tlc-tab-7": { recoveryConfigVersion: 1, debug: { enabled: true, entries: [] }, recovery: { attempt: {
      id: attemptId, documentId: oldDocument, handle: "creator", startedAtMs: 5000, outcome: "started"
    } } }
  } });
  const base = { documentId: webcrypto.randomUUID(), socketId: webcrypto.randomUUID(), stage: "socket-open", mode: "normal",
    contentDocumentId: newDocument, contentDocumentStartedAtMs: 6000, recoveryAttemptId: webcrypto.randomUUID() };
  const record = async (overrides = {}) => {
    await w.send("TLC_DEBUG_EVENT", 7, { event: "socket-telemetry", detail: { socket: { ...base, ...overrides } } });
    return w.session["tlc-tab-7"].debug.entries.at(-1).detail.socket;
  };
  assert.equal((await record()).recoveryAttemptId, attemptId);
  assert.equal((await record({ contentDocumentId: oldDocument })).recoveryAttemptId, null);
  assert.equal((await record({ contentDocumentStartedAtMs: 4000 })).recoveryAttemptId, null);
  assert.equal((await record({ contentDocumentStartedAtMs: 10000 })).recoveryAttemptId, null);
  assert.equal((await record({ mode: "embed" })).recoveryAttemptId, null);
  w.browserTabs.get(7).url = "https://www.tiktok.com/@other/live";
  assert.equal((await record()).recoveryAttemptId, null);
  w.browserTabs.get(7).url = "https://www.tiktok.com/@creator/live";
  w.session["tlc-tab-7"].recovery.attempt.playbackDocumentId = webcrypto.randomUUID();
  assert.equal((await record()).recoveryAttemptId, null);
  delete w.session["tlc-tab-7"].recovery.attempt.playbackDocumentId;
  w.clock.now = 130001;
  assert.equal((await record()).recoveryAttemptId, null);
});

test("0PE-173: only progressing playback in a newer document of the same stream ends the video measurement", async () => {
  const id = webcrypto.randomUUID(), oldDocument = webcrypto.randomUUID(), newDocument = webcrypto.randomUUID();
  const w = worker({ now: 5000, tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }], session: {
    "tlc-tab-7": { recoveryConfigVersion: 1, quickRecoverEnabled: true, quickRecoverSeconds: 1, debug: { enabled: true, entries: [] } }
  } });
  await w.send("TLC_QUICK_RECOVER", 7, { reason: "video-not-ready", recoveryAttempt: {
    id, documentId: oldDocument, detectedAtMs: 3000, scheduledAtMs: 4000, requestedAtMs: 4500, configuredDelayMs: 1000
  } });
  w.clock.now = 9000;
  for (const observation of [
    { documentId: oldDocument, documentStartedAtMs: 1000, playing: true },
    { documentId: newDocument, documentStartedAtMs: 6000, playing: false },
    { documentId: newDocument, documentStartedAtMs: 4000, playing: true }
  ]) await w.send("TLC_RECOVERY_MEDIA_OBSERVATION", 7, { observation });
  assert.equal(w.session["tlc-tab-7"].recovery.attempt.completedAtMs, undefined);
  const observation = { documentId: newDocument, documentStartedAtMs: 6000, playing: true };
  w.browserTabs.get(7).url = "https://www.tiktok.com/@other/live";
  await w.send("TLC_RECOVERY_MEDIA_OBSERVATION", 7, { observation });
  assert.equal(w.session["tlc-tab-7"].recovery.attempt.completedAtMs, undefined);
  w.browserTabs.get(7).url = "https://www.tiktok.com/@creator/live";
  await w.send("TLC_RECOVERY_MEDIA_OBSERVATION", 7, { observation });
  await w.send("TLC_RECOVERY_MEDIA_OBSERVATION", 7, { observation });
  const { report } = await w.send("TLC_GET_DEBUG_REPORT", 7);
  const events = report.debug.entries.filter((entry) => entry.event === "reconnect-video-progress");
  assert.equal(events.length, 1);
  assert.equal(events[0].detail.recoveryAttempt.reloadToVideoMs, 4000);
  assert.equal(events[0].detail.recoveryAttempt.interruptionToVideoMs, 6000);
  assert.equal(events[0].detail.recoveryAttempt.id, id);
  assert.equal(events[0].detail.recoveryAttempt.handle, undefined);
});

test("0PE-170: deadline terminates silent startup without reload and ignores obsolete alarms", async () => {
  const w = worker({ now: 1000, tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }] });
  await w.send("TLC_OPEN_EMBED_LIVE", 7);
  const name = "tlc-embed-deadline-7";
  assert.equal(w.alarms.get(name).when, 91000);
  w.clock.now = 50000;
  await w.fireAlarm(name);
  assert.equal(w.session["tlc-embed-7"].phase, "loading");
  w.clock.now = 92000;
  await w.fireAlarm(name);
  assert.equal(w.session["tlc-embed-7"].phase, "failed");
  assert.equal(w.session["tlc-embed-7"].reason, "timeout");
  assert.equal(w.alarms.has(name), false);
  assert.equal(w.tabActions.filter((action) => action.action === "reload").length, 0);
  await w.send("TLC_OPEN_EMBED_LIVE", 7);
  await w.fireAlarm(name);
  assert.equal(w.session["tlc-embed-7"].phase, "loading", "old alarm cannot expire a new session");
  await w.send("TLC_CANCEL_EMBED_STARTUP", 7);
  assert.equal(w.alarms.has(name), false);
  w.clock.now = 300000;
  await w.fireAlarm(name);
  assert.equal(w.session["tlc-embed-7"].phase, "cancelled");
});

test("0PE-170: state broadcasts preserve the startup status and publish cancellation immediately", async () => {
  const w = worker({ tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }] });
  await w.send("TLC_OPEN_EMBED_LIVE", 7);
  await w.send("TLC_PAGE_STATE", 7, { page: { url: "https://www.tiktok.com/embed/live/@creator" } });
  const updates = w.broadcasts.filter((message) => message.type === "TLC_STATE_UPDATED" && message.tabId === 7);
  assert.equal(updates.at(-1).state.embedStartup.phase, "loading");
  await w.send("TLC_CANCEL_EMBED_STARTUP", 7);
  assert.equal(w.broadcasts.at(-1).state.embedStartup.phase, "cancelled");
});

test("0PE-170: missing playback times out on observations and stale or invalid observations do nothing", () => {
  const state = core.newEmbedSession("test", "creator", 1000);
  const observation = { status: "waiting", documentId: "a", documentStartedAtMs: 1000 };
  assert.equal(core.advanceEmbedSession(state, observation, 15999).session.phase, "loading");
  assert.equal(core.advanceEmbedSession(state, observation, 16000).session.phase, "retry-wait");
  assert.equal(core.advanceEmbedSession(state, observation, 91000).session.phase, "failed");
  for (const invalid of [{ ...observation, status: "unknown" }, { ...observation, documentStartedAtMs: 999 }]) {
    assert.deepEqual(core.advanceEmbedSession(state, invalid, 16000), { session: state, action: "none" });
  }
});

test("0PE-170: concurrent Embed clicks create one chat source and navigate once", async () => {
  const w = worker({ tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }],
    tabReply: () => ({ playerState: { videoAvailable: true, playing: true } }) });
  const responses = await Promise.all(Array.from({ length: 8 }, () => w.send("TLC_OPEN_EMBED_LIVE", 7)));
  assert.ok(responses.every((r) => r.response.phase === "loading" && !r.response.activated), "navigation is not playback confirmation");
  assert.equal(w.tabActions.filter((a) => a.action === "create").length, 1);
  assert.equal(w.tabActions.filter((a) => a.action === "update").length, 1);
  const sourceId = w.session["tlc-tab-7"].chatSourceTabId;
  assert.equal(w.session[`tlc-tab-${sourceId}`].chatTargetTabId, 7);
  const repeated = await w.send("TLC_OPEN_EMBED_LIVE", 7);
  assert.equal(repeated.reloading, false);
  assert.equal(w.tabActions.filter((a) => a.action === "update").length, 1);
});

test("0PE-170: Embed followed immediately by Normal serializes mode changes", async () => {
  const w = worker({ tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }] });
  await Promise.all([w.send("TLC_OPEN_EMBED_LIVE", 7), w.send("TLC_OPEN_NORMAL_LIVE", 7)]);
  assert.equal(w.browserTabs.get(7).url, "https://www.tiktok.com/@creator/live");
  assert.equal(w.browserTabs.size, 1);
  assert.equal(w.session["tlc-tab-7"].chatSourceTabId, null);
});

test("0PE-170: stale source pointer cannot commandeer another tab or treat null as tab zero", async () => {
  for (const sourceId of [null, 9]) {
    const w = worker({
      tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" },
        { id: sourceId ?? 0, url: "https://www.tiktok.com/@creator/live" }],
      session: { "tlc-tab-7": { chatSourceTabId: sourceId } }
    });
    await w.send("TLC_OPEN_EMBED_LIVE", 7);
    assert.equal(w.tabActions.filter((a) => a.action === "create").length, 1);
    assert.equal(w.session[`tlc-tab-${sourceId ?? 0}`], undefined);
    await w.send("TLC_OPEN_NORMAL_LIVE", 7);
    assert.ok(w.browserTabs.has(sourceId ?? 0), "unowned tab must remain");
  }
});

test("0PE-170: navigation failure removes only the newly-created chat source and permits retry", async () => {
  let fail = true;
  const w = worker({ tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }],
    failNavigation: () => { const result = fail; fail = false; return result; } });
  await assert.rejects(w.send("TLC_OPEN_EMBED_LIVE", 7), /Navigation failed/);
  assert.equal(w.browserTabs.size, 1);
  assert.equal(w.session["tlc-tab-7"].chatSourceTabId, null);
  await w.send("TLC_OPEN_EMBED_LIVE", 7);
  assert.equal(w.browserTabs.size, 2);
});

test("0PE-170: pending Embed coalesces clicks and exhausted startup permits a new manual run", async () => {
  const w = worker({ tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }],
    tabReply: () => ({ playerState: { videoAvailable: false, playing: false } }) });
  await w.send("TLC_OPEN_EMBED_LIVE", 7);
  await w.send("TLC_OPEN_EMBED_LIVE", 7);
  assert.equal(w.tabActions.filter((a) => a.action === "create").length, 1);
  assert.equal(w.tabActions.filter((a) => a.action === "update").length, 1);
  w.session["tlc-embed-7"].phase = "failed";
  await w.send("TLC_OPEN_EMBED_LIVE", 7);
  assert.equal(w.tabActions.filter((a) => a.action === "update").length, 2);
});

test("0PE-170: real worker retries server error in same tab, survives restart, and confirms a new document", async () => {
  const seed = { now: 1000, tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }] };
  const w = worker(seed);
  await w.send("TLC_SET_DEBUG", 7, { enabled: true });
  await w.send("TLC_OPEN_EMBED_LIVE", 7);
  const observation = { documentId: "11111111-1111-4111-8111-111111111111", documentStartedAtMs: 1001, status: "server-error" };
  w.clock.now = 2000;
  await w.send("TLC_EMBED_OBSERVATION", 7, { observation });
  assert.equal(w.session["tlc-embed-7"].nextAttemptAtMs, 4000);
  const resumed = worker({ now: 4000, session: w.session, tabs: [...w.browserTabs.values()] });
  await resumed.send("TLC_EMBED_OBSERVATION", 7, { observation });
  assert.equal(resumed.tabActions.filter((a) => a.action === "reload").length, 1);
  assert.equal(resumed.tabActions.filter((a) => a.action === "create").length, 0);
  resumed.clock.now = 5000;
  await resumed.send("TLC_EMBED_OBSERVATION", 7, { observation: { ...observation, status: "playing" } });
  assert.equal(resumed.session["tlc-embed-7"].phase, "loading");
  await resumed.send("TLC_EMBED_OBSERVATION", 7, { observation: { ...observation,
    documentId: "22222222-2222-4222-8222-222222222222", documentStartedAtMs: 4500, status: "playing" } });
  assert.equal(resumed.session["tlc-embed-7"].phase, "playing");
  const { report } = await resumed.send("TLC_GET_DEBUG_REPORT", 7);
  assert.equal(report.embedStartup.attempt, 2);
  assert.equal(report.embedStartup.phase, "playing");
  assert.equal(report.embedStartup.handle, undefined);
  assert.equal(report.embedStartup.documentId, undefined);
  assert.ok(report.debug.entries.some((e) => e.event === "embed-startup" && e.detail.embedStartup.phase === "playing"));
});

test("0PE-170: explicit cancellation, Normal, or navigation away blocks a scheduled Embed retry", async () => {
  for (const cancel of ["TLC_CANCEL_EMBED_STARTUP", "TLC_OPEN_NORMAL_LIVE", "navigate-away"]) {
    const w = worker({ now: 1000, tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }] });
    await w.send("TLC_OPEN_EMBED_LIVE", 7);
    const observation = { documentId: "11111111-1111-4111-8111-111111111111", documentStartedAtMs: 1001, status: "server-error" };
    w.clock.now = 2000;
    await w.send("TLC_EMBED_OBSERVATION", 7, { observation });
    if (cancel === "navigate-away") w.browserTabs.get(7).url = "https://example.com/";
    else await w.send(cancel, 7);
    w.clock.now = 5000;
    await w.send("TLC_EMBED_OBSERVATION", 7, { observation });
    assert.equal(w.tabActions.filter((a) => a.action === "reload").length, 0);
    assert.equal(w.session["tlc-embed-7"].phase, "cancelled");
  }
});

test("0PE-170: mode queues stay tab-local and survive a service-worker restart through stored ownership", async () => {
  const w = worker({ tabs: [7, 8].map((id) => ({ id, url: "https://www.tiktok.com/@creator/live" })) });
  await Promise.all([7, 8].map((id) => w.send("TLC_OPEN_EMBED_LIVE", id)));
  assert.notEqual(w.session["tlc-tab-7"].chatSourceTabId, w.session["tlc-tab-8"].chatSourceTabId);
  const restarted = worker({ session: w.session, tabs: [...w.browserTabs.values()] });
  await restarted.send("TLC_OPEN_EMBED_LIVE", 7);
  assert.equal(restarted.tabActions.filter((a) => a.action === "create").length, 0);
  await restarted.send("TLC_OPEN_NORMAL_LIVE", 7);
  assert.ok(restarted.browserTabs.has(w.session["tlc-tab-8"].chatSourceTabId));
  assert.equal(restarted.browserTabs.get(8).url, "https://www.tiktok.com/embed/live/@creator");
});

test("0PE-170: Normal never closes an owned source that the user navigated elsewhere", async () => {
  const w = worker({ tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }] });
  await w.send("TLC_OPEN_EMBED_LIVE", 7);
  const sourceId = w.session["tlc-tab-7"].chatSourceTabId;
  w.browserTabs.get(sourceId).url = "https://example.com/";
  await w.send("TLC_OPEN_NORMAL_LIVE", 7);
  assert.ok(w.browserTabs.has(sourceId));
  assert.equal(w.browserTabs.get(sourceId).url, "https://example.com/");
});

test("0PE-170: rapid Embed-Normal-Embed ends in the last requested mode with one source", async () => {
  const w = worker({ tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }] });
  await Promise.all(["TLC_OPEN_EMBED_LIVE", "TLC_OPEN_NORMAL_LIVE", "TLC_OPEN_EMBED_LIVE"].map((type) => w.send(type, 7)));
  assert.equal(w.browserTabs.get(7).url, "https://www.tiktok.com/embed/live/@creator");
  assert.equal(w.browserTabs.size, 2);
  assert.ok(w.browserTabs.has(w.session["tlc-tab-7"].chatSourceTabId));
});

test("0PE-170: chat relay requires reciprocal ownership and the same live handle", async () => {
  const message = { userId: "fixture-user", author: "Test", content: "Synthetic chat", messageId: "fixture-1", source: "dom" };
  const w = worker({ tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" },
    { id: 0, url: "https://www.tiktok.com/@other/live" }] });
  await w.send("TLC_OPEN_EMBED_LIVE", 7);
  const sourceId = w.session["tlc-tab-7"].chatSourceTabId;
  await w.send("TLC_CHAT_MESSAGE", sourceId, { chatMessage: message });
  assert.equal(w.session["tlc-tab-7"].chatMessages.length, 1, "owned Embed pair receives chat");
  assert.equal(w.session["tlc-tab-0"], undefined, "null target is never tab zero");
  await w.send("TLC_OPEN_NORMAL_LIVE", 7);
  await w.send("TLC_CHAT_MESSAGE", sourceId, { chatMessage: { ...message, messageId: "late", content: "Late observation" } });
  assert.equal(w.session["tlc-tab-7"].chatMessages.length, 1, "late detached source does not relay");
  const fresh = worker({ tabs: [{ id: 7, url: "https://www.tiktok.com/@creator/live" }] });
  await fresh.send("TLC_OPEN_EMBED_LIVE", 7);
  const freshSourceId = fresh.session["tlc-tab-7"].chatSourceTabId;
  fresh.browserTabs.get(freshSourceId).url = "https://www.tiktok.com/@other/live";
  await fresh.send("TLC_CHAT_MESSAGE", freshSourceId, { chatMessage: message });
  assert.equal(fresh.session["tlc-tab-7"].chatMessages.length, 0, "user navigation detaches routing");
});

test("0PE-169: configured delay agrees across tab state, settings, runtime and debug export", async () => {
  const w = worker();
  const result = await w.send("TLC_SET_QUICK_RECOVER", 7, { enabled: true, seconds: 1 });
  assert.equal(result.state.quickRecoverSeconds, 1);
  assert.equal(w.session["tlc-tab-7"].quickRecoverSeconds, 1);
  assert.equal(w.sent.at(-1).seconds, 1);
  const settings = await w.send("TLC_GET_SETTINGS", 7);
  assert.equal(settings.settings.quickRecoverSeconds, 1);
  const debug = await w.send("TLC_GET_DEBUG_REPORT", 7);
  assert.equal(debug.report.components.playerQuickRecovery.delaySeconds, 1);
  assert.equal(debug.report.components.playerQuickRecovery.controller, "player-quick-recovery");
  assert.equal(debug.report.components.autoReconnect, undefined, "Player recovery must not be reported as hook reconnect");
  await w.send("TLC_ACTIVATE_TAB", 7);
  assert.equal(w.sent.at(-1).quickRecoverSeconds, 1);
});

test("0PE-169: changing one tab never changes another tab or the global preference", async () => {
  const w = worker({ local: { "tlc-settings": { quickRecoverSeconds: 3 } } });
  await w.send("TLC_SET_QUICK_RECOVER", 8, { enabled: true, seconds: 9 });
  await w.send("TLC_SET_QUICK_RECOVER", 7, { enabled: true, seconds: 1 });
  assert.equal((await w.send("TLC_GET_SETTINGS", 8)).settings.quickRecoverSeconds, 9);
  assert.equal(w.local["tlc-settings"].quickRecoverSeconds, 3);
  await w.send("TLC_SET_QUICK_RECOVER", 7, { enabled: false, seconds: 1 });
  assert.equal((await w.send("TLC_GET_SETTINGS", 7)).settings.quickRecoverEnabled, false);
  assert.equal((await w.send("TLC_GET_SETTINGS", 8)).settings.quickRecoverEnabled, true);
});

test("0PE-169: legacy stale tab delay migrates from the actual old runtime preference once", async () => {
  const w = worker({
    local: { "tlc-settings": { quickRecoverSeconds: 1 } },
    session: { "tlc-tab-7": { quickRecoverEnabled: true, quickRecoverSeconds: 3, hook: { armed: true } } }
  });
  const migrated = await w.send("TLC_GET_STATE", 7);
  assert.equal(migrated.state.quickRecoverSeconds, 1);
  assert.equal(migrated.state.hook.armed, true);
  assert.equal(migrated.state.hook.connected, false);
  w.local["tlc-settings"].quickRecoverSeconds = 12;
  assert.equal((await w.send("TLC_GET_SETTINGS", 7)).settings.quickRecoverSeconds, 1);
  const restarted = worker({ session: w.session, local: w.local });
  assert.equal((await restarted.send("TLC_GET_SETTINGS", 7)).settings.quickRecoverSeconds, 1);
});

test("0PE-169: delays normalize to finite whole seconds in the supported range", async () => {
  const w = worker();
  for (const [input, expected] of [[0, 3], [-5, 3], [null, 3], ["bad", 3], [Infinity, 3], [0.5, 1], [1.7, 2], [120, 59]]) {
    const result = await w.send("TLC_SET_QUICK_RECOVER", 7, { enabled: true, seconds: input });
    assert.equal(result.seconds, expected);
    assert.equal(result.state.quickRecoverSeconds, expected);
  }
});

function privateFixture() {
  return {
    enabled: true, recoveryConfigVersion: 1, quickRecoverSeconds: 1,
    browserSessionId: "9f9c80f3-12dd-48aa-adba-8b38569d1ab1",
    page: { url: "https://user:password@www.tiktok.com/@creator/live?sign=query-secret#fragment-secret", title: "PRIVATE-TITLE" },
    profileInfo: { present: true, nickname: "PRIVATE-NAME", signature: "PRIVATE-BIO" },
    aiSummaryInfo: { text: "PRIVATE-SUMMARY" },
    hook: { connected: true, endpoint: "wss://example.com/SECRET-PATH?token=query-secret", lastError: "PRIVATE-ERROR" },
    playerState: { playing: true, currentSrc: "https://example.com/SECRET-PATH?sign=query-secret", elapsedText: "1:23:45", privateText: "PRIVATE-PLAYER" },
    media: [{ url: "https://user:password@cdn.example.com/SECRET-PATH.flv?sign=query-secret#fragment-secret", protocol: "FLV", bitrate: 120000, raw: { cookie: "PRIVATE-COOKIE" } }],
    chatMessages: [{ content: "PRIVATE-CHAT", author: "PRIVATE-AUTHOR" }],
    participants: { "PRIVATE-ID": { name: "PRIVATE-NAME" } }, recentGiftIds: ["PRIVATE-GIFT"],
    captions: [{ method: "WebcastCaptionMessage", source: "websocket", sentenceId: "123", definite: true,
      receivedAtUtc: "2026-08-16T13:53:00.000Z", endpoint: "wss://example.com/SECRET-PATH?token=query-secret",
      contents: [{ lang: "de", text: "Erlaubter Untertitel" }], unrecognized: { token: "PRIVATE-TOKEN" } }],
    debug: { enabled: true, entries: [{ atUtc: "2026-08-16T13:53:00.000Z", event: "hook-status",
      detail: { connected: true, lastError: "PRIVATE-ERROR", cookie: "PRIVATE-COOKIE", state: { chatMessages: [{ content: "PRIVATE-CHAT" }] } } },
      { atUtc: "2026-08-16T13:53:00.001Z", event: "PRIVATE-EVENT", detail: { reason: "PRIVATE-REASON" } }] }
  };
}

test("0PE-171: absent metadata cannot erase recent WebSocket or DOM observations", async () => {
  const w = worker();
  const caption = { method: "WebcastCaptionMessage", sentenceId: "123", definite: true,
    contents: [{ lang: "de", text: "Ein synthetischer Untertitel" }] };
  await w.send("TLC_CAPTION", 7, { caption });
  await w.send("TLC_PAGE_STATE", 7, { captionInfo: { present: false }, menuCaptionAvailable: false });
  let state = (await w.send("TLC_GET_STATE", 7)).state;
  assert.equal(state.captionInfo.present, true);
  assert.equal(state.captionSources.metadata.present, false);
  assert.equal(state.captionSources.websocket.active, true);
  assert.equal(state.captionInfo.open, null, "receiving WS does not prove the visible menu is on");
  await w.send("TLC_CAPTION", 7, { caption: { ...caption, method: "DomCaption", source: "dom" } });
  state = (await w.send("TLC_GET_STATE", 7)).state;
  assert.equal(state.captions.length, 2, "overlapping DOM and WS text must both remain");
  assert.deepEqual(state.captionInfo.activeSources, ["websocket", "dom"]);
  const { report } = await w.send("TLC_GET_DEBUG_REPORT", 7);
  assert.equal(report.captionSources.websocket.active, true);
  assert.equal(report.captionSources.dom.active, true);
  assert.equal(report.counts.captions, 2);
  assert.equal(report.captionSnapshot.protocolCount, report.counts.captions);
  assert.ok(report.captionSnapshot.capturedAtUtc);
  const raw = await w.send("TLC_GET_CAPTION_RAW_EXPORT", 7);
  assert.equal(raw.report.messages.length, 2);
  assert.equal(raw.report.captionSnapshot.protocolCount, raw.report.messages.length);
  assert.notEqual(raw.report.captionSnapshot.id, report.captionSnapshot.id);
  assert.equal(raw.report.data.captionSources.metadata.present, false);
});

test("0PE-171: exact same-source repeats deduplicate, revisions and final markers survive", async () => {
  const w = worker();
  const caption = { method: "WebcastCaptionMessage", sentenceId: "123", definite: false,
    contents: [{ lang: "de", text: "Test" }] };
  await w.send("TLC_CAPTION", 7, { caption });
  await w.send("TLC_CAPTION", 7, { caption });
  await w.send("TLC_CAPTION", 7, { caption: { ...caption, definite: true } });
  await w.send("TLC_CAPTION", 7, { caption: { ...caption, contents: [{ lang: "de", text: "Test erweitert" }] } });
  assert.equal((await w.send("TLC_GET_STATE", 7)).state.captions.length, 3);
});

test("0PE-171: activity expires without deleting history; metadata and menu stay independent", async () => {
  const now = Date.parse("2026-09-30T10:00:00.000Z");
  const sources = core.observeCaptionSource(null, { method: "WebcastCaptionMessage", contents: [{ lang: "de", text: "Test" }] }, now);
  assert.equal(core.summarizeCaptionSources(sources, now + 15_000).observed, true);
  assert.equal(core.summarizeCaptionSources(sources, now + 15_001).observed, false);
  assert.equal(core.summarizeCaptionSources(sources, now - 1).observed, false);
  const w = worker({ session: { "tlc-tab-7": { recoveryConfigVersion: 1, captionSources: sources,
    captions: [{ method: "WebcastCaptionMessage", receivedAtUtc: new Date(now).toISOString() }] } } });
  await w.send("TLC_PAGE_STATE", 7, { captionInfo: { present: true, open: false }, menuCaptionAvailable: true, menuCaptionActive: true });
  await w.send("TLC_PAGE_STATE", 7, { captionInfo: { present: true, open: false }, menuCaptionAvailable: true, menuCaptionActive: false });
  const state = (await w.send("TLC_GET_STATE", 7)).state;
  assert.equal(state.menuCaptionActive, false, "menu toggle-off must not be sticky true");
  assert.equal(state.captionSources.menu.active, false);
  assert.ok(state.captionSources.menu.lastObservedAtUtc);
  assert.equal(state.captionSources.metadata.open, false);
  assert.equal(state.captions.length, 1);
});

test("0PE-171: concurrent caption and page events retain every distinct observation", async () => {
  const w = worker();
  await w.send("TLC_GET_STATE", 7);
  const events = Array.from({ length: 12 }, (_, index) => w.send("TLC_CAPTION", 7, { caption: {
    method: index % 2 ? "WebcastCaptionMessage" : "DomCaption", sentenceId: String(index + 1),
    contents: [{ lang: "de", text: `Test ${index}` }]
  } }));
  events.push(w.send("TLC_PAGE_STATE", 7, { captionInfo: { present: false } }));
  await Promise.all(events);
  const state = (await w.send("TLC_GET_STATE", 7)).state;
  assert.equal(state.captions.length, 12);
  assert.equal(state.captionSources.websocket.active, true);
  assert.equal(state.captionSources.dom.active, true);
});

test("0PE-171: legacy history retains its old observation time and never becomes fresh on upgrade", async () => {
  const old = new Date(Date.now() - 60_000).toISOString();
  const w = worker({ session: { "tlc-tab-7": { recoveryConfigVersion: 1,
    captionInfo: { present: true, observed: true, source: "websocket" },
    captions: [{ method: "WebcastCaptionMessage", receivedAtUtc: old, contents: [{ lang: "de", text: "Historisch" }] }] } } });
  const state = (await w.send("TLC_GET_STATE", 7)).state;
  assert.equal(state.captionSources.websocket.lastObservedAtUtc, old);
  assert.equal(state.captionSources.websocket.active, false);
  assert.equal(state.captionInfo.present, false);
  assert.equal(state.captions.length, 1);
});

test("0PE-171: stream change clears old source status; captionless stream stays unknown", async () => {
  const w = worker();
  await w.send("TLC_PAGE_STATE", 7, { page: { url: "https://www.tiktok.com/@one/live" }, captionInfo: { present: false } });
  await w.send("TLC_CAPTION", 7, { caption: { method: "WebcastCaptionMessage", contents: [{ lang: "de", text: "Test" }] } });
  await w.send("TLC_PAGE_STATE", 7, { page: { url: "https://www.tiktok.com/@two/live" }, captionInfo: { present: false } });
  const state = (await w.send("TLC_GET_STATE", 7)).state;
  assert.equal(state.captionInfo.present, false);
  assert.equal(state.captionInfo.open, null);
  assert.equal(state.captionSources.websocket.active, false);
  assert.equal(state.captions.length, 0);
});

test("0PE-172: diagnostic export allowlists metadata and excludes old raw state and free-form strings", async () => {
  const w = worker({ session: { "tlc-tab-7": privateFixture() } });
  const before = structuredClone(w.session["tlc-tab-7"]);
  const { report } = await w.send("TLC_GET_DEBUG_REPORT", 7);
  const serialized = JSON.stringify(report);
  for (const forbidden of ["PRIVATE-", "SECRET-PATH", "query-secret", "fragment-secret", "password", "Erlaubter Untertitel"]) {
    assert.ok(!serialized.includes(forbidden), `Diagnostic contains ${forbidden}`);
  }
  assert.equal(report.schema, "tiktok-live-companion-diagnostic-v3");
  assert.equal(report.raw, undefined);
  assert.equal(report.counts.chat, 1);
  assert.equal(report.hook.connected, true);
  assert.equal(report.hook.hasError, true);
  assert.equal(report.playerState.playing, true);
  assert.equal(report.media[0].url, "https://cdn.example.com");
  assert.equal(report.debug.entries[0].detail.hasError, true);
  assert.deepEqual(w.session["tlc-tab-7"], before, "Export must not change playable URLs or runtime data");
});

test("0PE-172: caption RAW and JSONL preserve caption content, redact credentials, and omit unrelated data", async () => {
  const fixture = privateFixture();
  fixture.captions[0].contents[0].text += " PAIRING-SENTINEL API-SENTINEL UNIVERSAL-SENTINEL https://user:password@example.com/SECRET-PATH?sign=query-secret#fragment-secret Bearer hidden.token";
  const w = worker({ session: { "tlc-tab-7": fixture }, local: { "tlc-settings": {
    pairingCode: "PAIRING-SENTINEL", auddApiToken: "API-SENTINEL", universalCaptionApiKey: "UNIVERSAL-SENTINEL"
  } } });
  const { report } = await w.send("TLC_GET_CAPTION_RAW_EXPORT", 7);
  const { records } = await w.send("TLC_GET_CAPTION_JSONL_EXPORT", 7);
  for (const payload of [report, records]) {
    const text = JSON.stringify(payload);
    assert.ok(text.includes("Erlaubter Untertitel"));
    for (const forbidden of ["PRIVATE-", "SECRET-PATH", "query-secret", "fragment-secret", "password", "PAIRING-SENTINEL", "API-SENTINEL", "UNIVERSAL-SENTINEL", "hidden.token"]) {
      assert.ok(!text.includes(forbidden), `Caption export contains ${forbidden}`);
    }
  }
  assert.equal(report.schema, "tiktok-live-companion-caption-raw-v2");
  assert.deepEqual(report.messages, records);
  assert.deepEqual(report.captionProtocol, records);
  assert.deepEqual(report.languages, ["de"]);
  assert.equal(report.dataStreams[0].protocol, "FLV");
  assert.ok(w.session["tlc-tab-7"].media[0].url.includes("query-secret"));
});

test("0PE-172: newly captured debug metadata is safe and redaction is idempotent", async () => {
  const w = worker({ session: { "tlc-tab-7": privateFixture() } });
  await w.send("TLC_DEBUG_EVENT", 7, { event: "hook-status", detail: { connected: false, lastError: "PRIVATE-ERROR", payload: "PRIVATE-FRAME" } });
  const entry = w.session["tlc-tab-7"].debug.entries.at(-1);
  assert.ok(!JSON.stringify(entry).includes("PRIVATE-"));
  assert.equal(entry.detail.hasError, true);
  assert.deepEqual(exportPrivacy.debugEntry(entry), entry);
});

test("0PE-170: legacy quick recovery cannot reload Embed outside the bounded startup controller", async () => {
  const w = worker({ tabs: [{ id: 7, url: "https://www.tiktok.com/embed/live/@creator" }],
    session: { "tlc-tab-7": { recoveryConfigVersion: 1, quickRecoverEnabled: true, quickRecoverSeconds: 1 } } });
  const result = await w.send("TLC_QUICK_RECOVER", 7, { reason: "interruption" });
  assert.equal(result.skipped, true);
  assert.equal(result.reason, "embed-startup-controlled");
  assert.equal(w.tabActions.filter((item) => item.action === "reload").length, 0);
});

test("0PE-172: unknown report keys, malformed URL protocols and unknown metadata values fail closed", () => {
  const input = { raw: { password: "PRIVATE-KEY" }, cookie: "PRIVATE-COOKIE", media: [{ url: "data:PRIVATE-PAYLOAD", source: "PRIVATE-SOURCE" }],
    components: { captions: { sources: ["PRIVATE-SOURCE"], languages: ["PRIVATE-LANGUAGE"], unknown: "PRIVATE-CONTENT" } } };
  assert.ok(!JSON.stringify(exportPrivacy.diagnosticReport(input)).includes("PRIVATE-"));
  assert.equal(exportPrivacy.url("not a url"), null);
  assert.equal(exportPrivacy.url("blob:https://example.com/private"), null);
});

test('0PE-169: hook configuration is tab-local and never changes legacy player settings', async()=>{
 const w=worker({session:{'tlc-tab-7':{quickRecoverEnabled:true,quickRecoverSeconds:9,recoveryConfigVersion:1,hook:{armed:true}}}});
 const initial=(await w.send('TLC_GET_STATE',7)).state;
 assert.deepEqual(initial.hookReconnect,{enabled:false,seconds:3});
 const {state}=await w.send('TLC_SET_HOOK_RECONNECT',7,{enabled:true,seconds:2});
 assert.equal(state.quickRecoverEnabled,true);assert.equal(state.quickRecoverSeconds,9);
 assert.deepEqual(state.hookReconnect,{enabled:true,seconds:2});
 assert.equal((await w.send('TLC_GET_STATE',8)).state.hookReconnect.enabled,false);
 assert.ok(w.sent.some(m=>m.type==='TLC_HOOK_RECONNECT_CONFIG'&&m.id===7&&m.seconds===2));
 assert.equal(w.tabActions.length,0);
});
test('0PE-172/173: hook attempt is exported with correlation and without payload; stale documents ignored',async()=>{
 const w=worker();const id=webcrypto.randomUUID();const documentId=webcrypto.randomUUID();
 await w.send('TLC_HOOK_RECOVERY',7,{recovery:{controller:'hook-reconnect',id,documentId,contentDocumentStartedAtMs:2000,phase:'connecting',startedAtMs:5000,payload:'PRIVATE-CAPTION',url:'wss://host/?token=SECRET'}});
 const result=await w.send('TLC_HOOK_RECOVERY',7,{recovery:{contentDocumentStartedAtMs:1000,phase:'connected'}});
 assert.equal(result.ignored,'stale-document');
 const {report}=await w.send('TLC_GET_DEBUG_REPORT',7);
 assert.equal(report.hookRecovery.id,id);assert.equal(report.hookRecovery.documentId,documentId);
 assert.equal(report.hookRecovery.phase,'connecting');
 assert.ok(!JSON.stringify(report).includes('PRIVATE-CAPTION'));assert.ok(!JSON.stringify(report).includes('SECRET'));
 assert.equal(report.hookRecovery.completedAtMs,null);
});


test("0PE-175: saved filter survives worker restart and is independent of Game-Mode", async () => {
  const first = worker();
  assert.equal((await first.send("TLC_GET_SETTINGS", 7)).settings.filterExternalSpeechTriggers, false);
  for (const filter of [false, true]) for (const game of [false, true]) {
    await first.send("TLC_SET_SPEECH_PREFERENCE", 7, { filterExternalSpeechTriggers: filter, gameModeEnabled: game });
    const restored = worker({local: first.local});
    const settings = (await restored.send("TLC_GET_SETTINGS", 7)).settings;
    assert.equal(settings.filterExternalSpeechTriggers, filter);
    assert.equal(settings.gameModeEnabled, game);
    const spoken = [];
    restored.context.sendOffscreen = async message => spoken.push(message);
    for (const content of [".Text", ". Text", "  .Text", "Normal", "Ein Satz. Noch einer"]) {
      const state = {speech: {enabled:true}, participants:{}, chatMessages:[]};
      await restored.context.queueSpeechForTab(7, state, {author:"Autor",content});
    }
    assert.equal(spoken.length, filter ? 2 : 5);
  }
});
test("0PE-176: failed Connection reload preserves the previous state", async () => {
  const w = worker({tabs:[{id:7,url:"https://www.tiktok.com/@creator/live"}]});
  await w.send("TLC_ENABLE_HOOK",7);
  assert.equal((await w.context.getState(7)).hook.armed,true);
  vm.runInContext('chrome.tabs.reload = async () => { throw new Error("reload failed"); }', w.context);
  await assert.rejects(w.send("TLC_DISABLE_HOOK",7), /reload failed/);
  assert.equal((await w.context.getState(7)).hook.armed,true);
});
