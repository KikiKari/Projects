(function (root) {
  "use strict";
  // Owns only extension-created sockets. Native sockets, media and navigation
  // are deliberately outside this controller's capabilities.
  function create({ connect, identity, emit, now = Date.now, uuid = () => crypto.randomUUID(),
    later = setTimeout, cancel = clearTimeout }) {
    let enabled = false, seconds = 3, template = null, nativeReady = false;
    let generation = 0, timer = null, deadline = null, owned = null, attempt = null;
    let failures = 0, disconnectedAtMs = null, disposed = false;
    let currentIdentity = identity();
    function publish(phase, reason, extra = {}) {
      emit({ controller: "hook-reconnect", phase, reason, enabled, configuredDelayMs: seconds * 1000,
        atUtc: new Date(now()).toISOString(), ...(attempt || {}), ...extra });
    }
    function clearTimers() {
      if (timer != null) cancel(timer);
      if (deadline != null) cancel(deadline);
      timer = deadline = null;
    }
    function release(reason) {
      generation++;
      clearTimers();
      const previous = owned;
      owned = null;
      if (attempt) publish("cancelled", reason, { endedAtMs: now() });
      attempt = null;
      previous?.close();
    }
    function validStream() {
      if (identity() === currentIdentity) return Boolean(currentIdentity);
      release("stream-changed");
      currentIdentity = identity();
      template = null; nativeReady = false; failures = 0; disconnectedAtMs = null;
      publish("waiting", "stream-changed");
      return false;
    }
    function schedule(reason = "socket-close") {
      if (disposed || !enabled || !validStream() || nativeReady || owned || timer != null) return;
      if (!template?.supported) { publish("unavailable", "protocol-unverified"); return; }
      const detected = disconnectedAtMs ?? now();
      const effectiveDelayMs = failures ? Math.min(30000, seconds * 1000 * 2 ** Math.min(failures, 10)) : seconds * 1000;
      attempt = { id: uuid(), attempt: failures + 1, detectedAtMs: detected,
        scheduledAtMs: now() + effectiveDelayMs, configuredDelayMs: seconds * 1000, effectiveDelayMs };
      publish("scheduled", reason);
      const expected = generation;
      timer = later(() => {
        timer = null;
        if (expected !== generation || !enabled || !validStream() || nativeReady) return;
        attempt.startedAtMs = now();
        attempt.actualWaitMs = now() - detected;
        attempt.scheduleOverrunMs = Math.max(0, now() - attempt.scheduledAtMs);
        publish("connecting", reason);
        deadline = later(() => fail("timeout", expected), 10000);
        try { owned = connect(template, { id: attempt.id, generation: expected }); }
        catch (_) { fail("connect-error", expected); }
      }, effectiveDelayMs);
    }
    function fail(reason, expected) {
      if (expected !== generation || !attempt) return;
      publish("failed", reason, { endedAtMs: now() });
      const previous = owned;
      owned = null; attempt = null; generation++; clearTimers(); failures++;
      previous?.close();
      // A policy rejection needs new native parameters, not an endless retry.
      if (reason === "policy-rejected" || reason === "protocol-unverified") {
        template = null; publish("unavailable", reason); return;
      }
      schedule(reason);
    }
    return {
      configure(config) {
        const value = Number(config.seconds);
        const delay = Number.isFinite(value) ? Math.max(1, Math.min(59, Math.round(value))) : 3;
        if (enabled === Boolean(config.enabled) && seconds === delay) return;
        release(config.enabled ? "configuration-changed" : "disabled");
        enabled = Boolean(config.enabled); seconds = delay; failures = 0;
        if (!enabled) publish("disabled", "disabled");
        else if (nativeReady) publish("native", "native-connected");
        else schedule("configuration-changed");
      },
      nativeConnected(value) {
        if (!validStream()) return;
        template = value; nativeReady = true; failures = 0; disconnectedAtMs = null;
        release("native-takeover"); publish("native", "native-connected");
      },
      nativeDisconnected() {
        nativeReady = false; disconnectedAtMs ??= now(); schedule();
      },
      stage(token, stage) {
        if (token.generation !== generation || !attempt || !validStream()) return false;
        const field = { "socket-open": "socketOpenAtMs", "first-frame": "firstFrameAtMs",
          "first-decoded-message": "firstDecodedAtMs" }[stage];
        if (field && attempt[field] == null) attempt[field] = now();
        publish(stage, "socket-close");
        return true;
      },
      connected(token) {
        if (token.generation !== generation || !attempt || !validStream()) return false;
        if (deadline != null) cancel(deadline);
        deadline = null; failures = 0;
        attempt.completedAtMs = now();
        attempt.disconnectToDecodedMs = now() - attempt.detectedAtMs;
        attempt.connectToDecodedMs = now() - attempt.startedAtMs;
        publish("connected", "qualified-data"); return true;
      },
      failed: (token, reason) => fail(reason, token.generation),
      isCurrent: (token) => token.generation === generation && !disposed && validStream(),
      checkStream: validStream,
      stop(reason = "document-ended") { release(reason); enabled = false; publish("disabled", reason); },
      dispose() { this.stop(); disposed = true; template = null; }
    };
  }
  const api = { create };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  root[Symbol.for("tiktok-live-companion.hook-recovery")] = api;
})(globalThis);
