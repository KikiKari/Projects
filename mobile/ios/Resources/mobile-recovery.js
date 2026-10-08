(function (root) {
  "use strict";
  if (location.origin !== "https://www.tiktok.com" || root.TLC_MOBILE_RECOVERY) return;
  const documentId = crypto.randomUUID();
  let connectionEnabled = true;
  let sequence = 0, path = location.pathname, timer = null, video = null;
  let enabled = false, seconds = 3, pausedByUser = false, vlc = false;
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
    if (v !== video) { cancel("player-changed"); video = v; sawProgress = false; lastTime = v?.currentTime; progressAt = Date.now(); }
    if (v && Number.isFinite(v.currentTime) && v.currentTime !== lastTime) {
      sawProgress = true; lastTime = v.currentTime; progressAt = Date.now();
      if (attempt) { emit("player-recovery", { ...attempt, phase: "playing", completedAtMs: Date.now() }); if (timer !== null) clearTimeout(timer); timer = null; attempt = null; }
    }
    return v;
  }
  function recover(reason) {
    const v = mediaState();
    if (!enabled || !v || pausedByUser || vlc || v.ended || timer !== null || (attempt?.startedAtMs && Date.now()-attempt.startedAtMs < 10000)) return;
    attempt = { id: crypto.randomUUID(), detectedAtMs: progressAt, scheduledAtMs: Date.now()+seconds*1000,
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
      catch (_) { emit("player-recovery", { ...attempt, phase: "awaiting-gesture", reason: "awaiting-gesture" }); cancel("awaiting-gesture"); pausedByUser = true; }
      // Never reload or replace the document, player, native chat, or VLC source.
    }, seconds*1000);
  }
  function captionState() {
    const now = Date.now();
    const active = Object.fromEntries(Object.entries(stamps).map(([key,value]) => [key, value > 0 && now-value < 15000]));
    emit("caption-state", { metadataPresent, menuAvailable, ...active, activityTtlMs: 15000 });
  }
  root.addEventListener("message", (event) => {
    if (event.source !== root || event.origin !== location.origin || event.data?.source !== "tiktok-live-companion") return;
    const d = event.data;
    if (d.type === "hook-status") emit("hook-status", { installed: d.hook?.installed === true, connected: d.hook?.connected === true });
    else if (d.type === "hook-recovery") emit("hook-recovery", { ...root.TLC_EXPORT_PRIVACY.hookRecovery(d.recovery), hookDocumentId: d.recovery?.documentId });
    else if (d.type === "socket-telemetry") emit("socket-telemetry", d.telemetry || {});
    else if (d.type === "chat-message") emit("chat", { ...d.chatMessage, language: d.chatMessage?.contentLanguage || "" });
    else if (d.type === "caption") { stamps.websocket = Date.now(); emit("caption", { ...d.caption, source: "websocket" }); captionState(); }
    else if (d.type === "live-event") emit("live-stats", d.liveEvent || {});
    else if (d.type === "gift-message") emit("gift", d.giftMessage || {});
    else if (d.type === "hook-recovery-ready") emit("recovery-ready", {});
  });
  function command(name, payload = {}) {
    if (name === "set-connection") connectionEnabled = payload.enabled === true;
    if (name === "set-hook-reconnect") root.postMessage({source: "tiktok-live-companion-control", type: "hook-reconnect-config", enabled: payload.enabled === true, seconds: payload.delaySeconds}, location.origin);
    if (name === "set-auto-reconnect") { cancel("configuration-changed"); enabled = payload.enabled === true; seconds = Math.max(1,Math.min(59,Number(payload.delaySeconds)||3)); }
    if (name === "pause") { pausedByUser = true; cancel("user-paused"); }
    if (name === "play" || name === "start-audible") { pausedByUser = false; progressAt = Date.now(); }
    if (name === "set-vlc-active") { vlc = payload.active === true; cancel("vlc-changed"); }
  }
  root.TLC_MOBILE_RECOVERY = Object.freeze({documentId, recover, command, handles: name => ["set-hook-reconnect","set-vlc-active"].includes(name)});
  if (topFrame) {
    const interval = setInterval(() => {
      if (path !== location.pathname) { path = location.pathname; cancel("stream-changed"); for (const k of Object.keys(stamps)) stamps[k]=0; metadataPresent=false; lastCaption=""; }
      const v = mediaState();
      if (v) {
        if (!v.dataset.tlcRecoveryObserved) {
          v.dataset.tlcRecoveryObserved="true";
          v.addEventListener("pause", () => { if (v.readyState >= 3 && !v.ended) { pausedByUser=true; cancel("user-paused"); } });
          v.addEventListener("playing", () => { pausedByUser=false; progressAt=Date.now(); });
        }
        emit("player-observation", { playing: sawProgress && !v.paused && !v.ended && Date.now()-progressAt < 2000,
          paused: v.paused, ended: v.ended, currentTime: Number.isFinite(v.currentTime)?v.currentTime:null,
          userPaused: pausedByUser, vlcActive: vlc, mediaProgressAtMs: progressAt });
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
    }, 1000);
    root.addEventListener("pagehide",()=>{clearInterval(interval);cancel("document-ended");},{once:true});
  }
})(globalThis);
