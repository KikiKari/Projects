(function (root) {
  "use strict";
  if (location.origin !== "https://www.tiktok.com" || root.TLC_MOBILE_RECOVERY) return;
  const documentId = crypto.randomUUID();
  let connectionEnabled = true;
  let sequence = 0, path = location.pathname, timer = null, video = null;
  let enabled = false, seconds = 3, pausedByUser = false, vlc = false;
  let awaitingGesture = false, pauseIntentUntil = 0;
  let reloadRequestedAt = 0;
  let lastTime = null, progressAt = Date.now(), attempt = null;
  const stamps = { websocket: 0, dom: 0, playerText: 0 };
  let sawProgress = false;
  let metadataPresent = false, menuAvailable = false, lastCaption = "";
  const topFrame = root.top === root;
  function emit(type, payload) {
    if (!connectionEnabled && ["chat", "caption", "live-stats", "gift", "socket-open"].includes(type)) return;
    const message = { version: 1, type, streamId: location.pathname, sequence: ++sequence,
      timestamp: new Date().toISOString(), payload: { ...payload, documentId,
        frameKind: topFrame ? "top" : "sub", frameOrigin: location.origin } };
    if (root.webkit?.messageHandlers?.tlcBridge?.postMessage) root.webkit.messageHandlers.tlcBridge.postMessage(message);
    else root.tlcBridge?.postMessage(JSON.stringify(message));
  }
  function primary() { return [...document.querySelectorAll("video")].sort((a,b) => b.clientWidth*b.clientHeight-a.clientWidth*a.clientHeight)[0] || null; }
  function cancel(reason) {
    if (timer !== null) clearTimeout(timer);
    timer = null;
    if (attempt) emit("player-recovery", { ...attempt, phase: "cancelled", reason, endedAtMs: Date.now() });
    attempt = null;
  }
  function mediaState() {
    const v = primary();
    if (v !== video) { cancel("player-changed"); video = v; pausedByUser = false; awaitingGesture = false; pauseIntentUntil = 0; sawProgress = false; lastTime = v?.currentTime; progressAt = Date.now(); }
    if (v && Number.isFinite(v.currentTime) && v.currentTime !== lastTime) {
      sawProgress = true; lastTime = v.currentTime; progressAt = Date.now();
      if (attempt) { emit("player-recovery", { ...attempt, phase: "playing", completedAtMs: Date.now() }); if (timer !== null) clearTimeout(timer); timer = null; attempt = null; }
    }
    return v;
  }
  function recover(reason) {
    const v = mediaState();
    if (!enabled || !v || pausedByUser || awaitingGesture || vlc || v.ended || timer !== null) return;
    if (reloadRequestedAt && Date.now()-reloadRequestedAt < 30000) return;
    if (attempt?.startedAtMs) {
      if (Date.now()-attempt.startedAtMs < 10000) return;
      emit("player-recovery", { ...attempt, phase: "failed", reason: "timeout", endedAtMs: Date.now() });
      emit("quick-recover", { ...attempt, reason: "player-stall", stage: "page-reload" });
      attempt = null;
      reloadRequestedAt = Date.now();
      // Escalate only after play() failed to restore progress; hook-only recovery never navigates.
      location.reload();
      return;
    }
    const remainingMs = Math.max(0, seconds*1000-(Date.now()-progressAt));
    attempt = { id: crypto.randomUUID(), detectedAtMs: progressAt, scheduledAtMs: Date.now()+remainingMs,
      configuredDelayMs: seconds*1000, phase: "scheduled", reason };
    emit("player-recovery", attempt);
    const expected = attempt.id;
    timer = setTimeout(async () => {
      timer = null;
      const current = mediaState();
      if (!attempt || attempt.id !== expected || !enabled || pausedByUser || vlc || current !== v || v.ended || Date.now()-progressAt < seconds*1000) return cancel("media-progress");
      attempt.startedAtMs = Date.now();
      emit("player-recovery", { ...attempt, phase: "connecting", actualWaitMs: Date.now()-attempt.detectedAtMs });
      try { await v.play(); }
      catch (error) {
        if (!attempt || attempt.id !== expected || !enabled || current !== video) return;
        awaitingGesture = error?.name === "NotAllowedError";
        emit("player-recovery", { ...attempt, phase: awaitingGesture ? "awaiting-gesture" : "failed", reason: awaitingGesture ? "awaiting-gesture" : "error" });
        if (awaitingGesture) attempt = null;
      }
    }, remainingMs);
  }
  function captionState() {
    const now = Date.now();
    const active = Object.fromEntries(Object.entries(stamps).map(([key,value]) => [key, value > 0 && now-value < 15000]));
    emit("caption-state", { metadataPresent, menuAvailable, ...active, activityTtlMs: 15000 });
  }
  root.addEventListener("message", (event) => {
    if (event.source !== root || event.origin !== location.origin || event.data?.source !== "tiktok-live-companion") return;
    const d = event.data;
    if (d.type === "hook-status") emit("hook-status", { armed: d.hook?.armed === true, installed: d.hook?.installed === true, connected: d.hook?.connected === true });
    else if (d.type === "hook-recovery") emit("hook-recovery", { ...root.TLC_EXPORT_PRIVACY.hookRecovery(d.recovery), hookDocumentId: d.recovery?.documentId });
    else if (d.type === "socket-telemetry") emit("socket-telemetry", d.telemetry || {});
    else if (d.type === "chat-message") emit("chat", { ...d.chatMessage, language: d.chatMessage?.contentLanguage || "" });
    else if (d.type === "caption") { stamps.websocket = Date.now(); emit("caption", { ...d.caption, source: "websocket" }); captionState(); }
    else if (d.type === "live-event") emit("live-stats", d.liveEvent || {});
    else if (d.type === "gift-message") emit("gift", d.giftMessage || {});
    else if (d.type === "hook-recovery-ready") emit("recovery-ready", {});
  });
  function command(name, payload = {}) {
    if (name === "set-connection") {
      connectionEnabled = payload.enabled === true;
      root.postMessage({source: "tiktok-live-companion-control", type: "hook-connection-config", enabled: connectionEnabled}, location.origin);
    }
    if (name === "set-hook-reconnect") root.postMessage({source: "tiktok-live-companion-control", type: "hook-reconnect-config", enabled: payload.enabled === true, seconds: payload.delaySeconds}, location.origin);
    if (name === "set-auto-reconnect") {
      const nextEnabled = payload.enabled === true;
      const nextSeconds = Math.max(1,Math.min(59,Number(payload.delaySeconds)||3));
      if (enabled !== nextEnabled || seconds !== nextSeconds) cancel("configuration-changed");
      enabled = nextEnabled; seconds = nextSeconds;
      emit("capability", {feature: "player-recovery", available: true, enabled, delaySeconds: seconds});
    }
    if (name === "pause") { pausedByUser = true; cancel("user-paused"); }
    if (name === "play" || name === "start-audible") { pausedByUser = false; awaitingGesture = false; }
    if (name === "set-vlc-active") { const next = payload.active === true; if (vlc !== next) cancel("vlc-changed"); vlc = next; }
  }
  root.TLC_MOBILE_RECOVERY = Object.freeze({documentId, recover, command, handles: name => ["set-hook-reconnect","set-vlc-active"].includes(name)});
  if (topFrame) {
    function notePauseIntent(event) {
      if (!event.isTrusted) return;
      const v = primary();
      const target = event.target;
      if (!v || v.paused || !(target instanceof Element)) return;
      const control = target.closest('button,[role="button"]');
      const label = control?.getAttribute("aria-label") || control?.getAttribute("title") || control?.textContent || "";
      const player = v.closest('[data-e2e="live-room-content"]') || v.parentElement;
      const keyboard = event.type === "keydown" && [" ", "k", "K"].includes(event.key) && !target.matches('input,textarea,[contenteditable="true"]');
      if ((event.type === "pointerup" && (target === v || (control && player?.contains(control) && /pause|pausieren|anhalten/i.test(label)))) || (keyboard && player?.contains(target))) pauseIntentUntil = Date.now() + 800;
    }
    root.addEventListener("pointerup", notePauseIntent, true);
    root.addEventListener("keydown", notePauseIntent, true);
    const observe = () => {
      if (path !== location.pathname) { path = location.pathname; cancel("stream-changed"); pausedByUser=false; awaitingGesture=false; pauseIntentUntil=0; for (const k of Object.keys(stamps)) stamps[k]=0; metadataPresent=false; lastCaption=""; }
      const v = mediaState();
      if (v) {
        if (!v.dataset.tlcRecoveryObserved) {
          v.dataset.tlcRecoveryObserved="true";
          v.addEventListener("pause", () => { if (Date.now() <= pauseIntentUntil && v.readyState >= 3 && !v.ended) { pauseIntentUntil=0; pausedByUser=true; cancel("user-paused"); } });
          v.addEventListener("playing", () => { pausedByUser=false; awaitingGesture=false; pauseIntentUntil=0; progressAt=Date.now(); });
        }
        emit("player-observation", { playing: sawProgress && !v.paused && !v.ended && Date.now()-progressAt < 2000,
          paused: v.paused, ended: v.ended, currentTime: Number.isFinite(v.currentTime)?v.currentTime:null,
          userPaused: pausedByUser, vlcActive: vlc, mediaProgressAtMs: progressAt });
        if (Date.now()-progressAt >= seconds*1000) recover("player-stall");
      }
      const body = document.body?.innerText || "";
      if (/\/embed\/live\//.test(location.pathname)) {
        if (/LIVE (?:has )?ended|Livestream (?:ist )?beendet/i.test(body)) emit("embed-blocked", { reason:"ended" });
        else if (!v && document.querySelector('input[type="password"]')) emit("embed-blocked", { reason:"login-required" });
      }
      menuAvailable = [...document.querySelectorAll("button,[role=menuitem]")].some(n=>/caption|untertitel/i.test(n.textContent||""));
      const node = document.querySelector('[data-e2e="live-caption"], [data-e2e="caption-text"]');
      const text = node?.textContent?.trim() || "";
      if (text && text !== lastCaption) { stamps.dom=Date.now(); lastCaption=text; emit("caption",{source:"dom",text:text.slice(0,2000),contents:[{lang:"und",text:text.slice(0,2000)}]}); }
      const tracks = v?.textTracks;
      for (let i=0; tracks && i<tracks.length; i++) if (tracks[i].activeCues?.length) stamps.playerText=Date.now();
      if (!metadataPresent) for (const script of [...document.scripts].slice(-40)) {
        const data = script.textContent || "";
        if (data.length < 200000 && /caption_info/.test(data)) {
          metadataPresent = root.TLC_CONTENT_CORE?.inspectMetadata(data, {maxNodes: 2000})?.captionInfo?.present === true;
          if (metadataPresent) break;
        }
      }
      captionState();
    };
    const interval = setInterval(observe, 1000);
    root.addEventListener("pageshow", observe);
    root.addEventListener("online", observe);
    document.addEventListener("visibilitychange", () => { if (!document.hidden) observe(); });
    root.addEventListener("pagehide", event => { if (!event.persisted) { clearInterval(interval); cancel("document-ended"); } });
  }
})(globalThis);
