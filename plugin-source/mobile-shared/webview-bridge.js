(function (root) {
  "use strict";

  if (location.protocol !== "https:" || location.hostname !== "www.tiktok.com" || root.top !== root) return;
  const MAX_MESSAGE_BYTES = 64 * 1024;
  const MAX_CHAT = 50;
  const MAX_AUDIO_SECONDS = 12;
  const ALLOWED_COMMANDS = new Set([
    "inspect", "hook-status", "play", "pause", "mute", "unmute", "set-volume",
    "fullscreen", "picture-in-picture", "reload-player", "captions", "refresh",
    "force-profile", "open-report", "start-webview-audio", "stop-webview-audio",
    "set-auto-reconnect", "set-limiter"
  ]);
  const QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400;
  let sequence = 0;
  let streamId = "";
  let audioCapture = null;
  let autoReconnectEnabled = true;
  let lastQuickRecoverAt = 0;
  let quickRecoverFailures = 0;
  let limiterStrength = 30;
  const monitoredVideos = new WeakSet();
  const chat = [];

  function nativePost(message) {
    const serialized = JSON.stringify(message);
    if (new TextEncoder().encode(serialized).byteLength > MAX_MESSAGE_BYTES) return;
    if (root.webkit?.messageHandlers?.tlcBridge?.postMessage) root.webkit.messageHandlers.tlcBridge.postMessage(message);
    else if (root.tlcBridge?.postMessage) root.tlcBridge.postMessage(serialized);
  }

  function emit(type, payload = {}) {
    nativePost({ version: 1, type, streamId, sequence: ++sequence, timestamp: new Date().toISOString(), payload });
  }

  function text(value, max = 2048) {
    return String(value ?? "").replace(/[\u0000-\u001f\u007f]/g, " ").trim().slice(0, max);
  }

  function primaryVideo() {
    return [...document.querySelectorAll("video")].sort((a, b) => (b.clientWidth * b.clientHeight) - (a.clientWidth * a.clientHeight))[0] || null;
  }

  function limiterStrengthToDbfs(value) {
    const strength = Math.max(0, Math.min(100, Number(value) || 0));
    return Math.round((-4 - (strength * 26 / 100)) * 100) / 100;
  }

  function currentLiveHandle() {
    const match = location.pathname.match(/^\/@([^/]+)\/live/);
    return match ? decodeURIComponent(match[1]).toLowerCase() : "";
  }

  function playableMediaLinks() {
    const seen = new Set();
    const links = [];
    const add = (url, label = "Video") => {
      try {
        const parsed = new URL(String(url || ""), location.href);
        if (parsed.protocol !== "https:" || seen.has(parsed.href)) return;
        const lower = parsed.pathname.toLowerCase();
        const type = lower.includes(".m3u8") ? "HLS" : lower.includes(".flv") ? "FLV" : lower.includes(".mp4") ? "MP4" : "";
        if (!type) return;
        seen.add(parsed.href);
        links.push({ url: parsed.href, type, label: text(label, 80) || type });
      } catch (_) {}
    };
    const video = primaryVideo();
    add(video?.currentSrc || video?.src, "Player");
    for (const source of document.querySelectorAll("video source[src],a[href]")) add(source.src || source.href, source.type || source.textContent || "Video");
    return links.slice(0, 12);
  }

  function inspect() {
    const video = primaryVideo();
    streamId = currentLiveHandle() || streamId;
    installVideoMonitor(video);
    const captionButtons = [...document.querySelectorAll("button,[role=menuitem]")].filter((node) => /caption|untertitel/i.test(node.textContent || ""));
    emit("inspection", {
      title: text(document.title, 256),
      url: `${location.origin}${location.pathname}`,
      videoPresent: Boolean(video),
      captionsControlPresent: captionButtons.length > 0,
      player: video ? { paused: video.paused, muted: video.muted, volume: video.volume, duration: Number.isFinite(video.duration) ? video.duration : null } : null
    });
    emit("media-links", { links: playableMediaLinks() });
  }

  function emitDecoded(decoded) {
    for (const item of decoded.chatMessages || []) {
      const entry = { nickname: text(item.nickname, 128), displayId: text(item.displayId, 128), content: text(item.content, 1000), language: text(item.contentLanguage, 24) };
      chat.push(entry);
      if (chat.length > MAX_CHAT) chat.splice(0, chat.length - MAX_CHAT);
      emit("chat", entry);
    }
    for (const item of decoded.captions || []) emit("caption", { sentenceId: text(item.sentenceId, 64), definite: Boolean(item.definite), contents: (item.contents || []).slice(0, 8).map((part) => ({ lang: text(part.lang, 24), text: text(part.text, 2000) })) });
    for (const item of decoded.liveEvents || []) emit("live-stats", item);
    for (const item of decoded.giftMessages || []) emit("gift", { nickname: text(item.nickname, 128), displayId: text(item.displayId, 128), repeatCount: text(item.repeatCount, 32), giftId: text(item.giftId, 64) });
  }

  function installWebSocketHook() {
    if (root.__tlcMobileHookInstalled) return;
    const NativeWebSocket = root.WebSocket;
    if (typeof NativeWebSocket !== "function") return emit("capability", { feature: "websocket-hook", available: false, reason: "WebSocket unavailable" });
    const proto = root[Symbol.for("tiktok-live-companion.proto")];
    const Proxied = new Proxy(NativeWebSocket, {
      construct(target, args, newTarget) {
        const socket = Reflect.construct(target, args, newTarget);
        socket.addEventListener("message", async (event) => {
          try {
            if (!proto?.decodeWebSocketPayload || !(event.data instanceof Blob || event.data instanceof ArrayBuffer || ArrayBuffer.isView(event.data))) return;
            emitDecoded(await proto.decodeWebSocketPayload(event.data));
          } catch (error) {
            emit("bridge-error", { operation: "decode-websocket", message: text(error?.message || error, 512) });
          }
        });
        return socket;
      }
    });
    for (const key of ["CONNECTING", "OPEN", "CLOSING", "CLOSED"]) Object.defineProperty(Proxied, key, { value: NativeWebSocket[key] });
    root.WebSocket = Proxied;
    Object.defineProperty(root, "__tlcMobileHookInstalled", { value: true, configurable: false });
    emit("capability", { feature: "websocket-hook", available: true });
  }

  function pcm16Base64(floatSamples) {
    const bytes = new Uint8Array(floatSamples.length * 2);
    const view = new DataView(bytes.buffer);
    for (let index = 0; index < floatSamples.length; index += 1) {
      const sample = Math.max(-1, Math.min(1, floatSamples[index]));
      view.setInt16(index * 2, sample < 0 ? sample * 0x8000 : sample * 0x7fff, true);
    }
    let binary = "";
    for (const byte of bytes) binary += String.fromCharCode(byte);
    return btoa(binary);
  }

  async function stopAudioCapture(reason = "stopped") {
    if (!audioCapture) return;
    const current = audioCapture;
    audioCapture = null;
    try { current.processor.disconnect(); } catch (_) {}
    try { current.source.disconnect(); } catch (_) {}
    try { await current.context.close(); } catch (_) {}
    emit("audio-complete", { reason });
  }

  async function startAudioCapture() {
    if (audioCapture) return;
    const video = primaryVideo();
    if (!video || typeof AudioContext !== "function") return emit("capability", { feature: "webview-audio", available: false, reason: "Player or Web Audio unavailable" });
    try {
      const context = new AudioContext({ sampleRate: 48_000 });
      await context.resume();
      const source = context.createMediaElementSource(video);
      const processor = context.createScriptProcessor(2048, 1, 1);
      const startedAt = performance.now();
      processor.onaudioprocess = (event) => {
        if (!audioCapture) return;
        const elapsed = (performance.now() - startedAt) / 1000;
        if (elapsed >= MAX_AUDIO_SECONDS) return void stopAudioCapture("completed");
        const samples = event.inputBuffer.getChannelData(0);
        emit("audio-chunk", { encoding: "pcm_s16le", channels: 1, sampleRate: context.sampleRate, elapsed, data: pcm16Base64(samples) });
      };
      source.connect(processor).connect(context.destination);
      audioCapture = { context, source, processor };
      emit("capability", { feature: "webview-audio", available: true, sampleRate: context.sampleRate });
    } catch (error) {
      await stopAudioCapture("failed");
      emit("capability", { feature: "webview-audio", available: false, reason: text(error?.message || error, 512) });
    }
  }

  async function playAndUnmute(video = primaryVideo()) {
    if (!video) return false;
    video.muted = false;
    try { await video.play(); return true; } catch (_) { return false; }
  }

  async function quickRecover(reason = "player-stall") {
    if (!autoReconnectEnabled) return;
    const now = Date.now();
    if (now - lastQuickRecoverAt < QUICK_RECOVER_RELOAD_COOLDOWN_MS) return;
    lastQuickRecoverAt = now;
    quickRecoverFailures += 1;
    const video = primaryVideo();
    const played = await playAndUnmute(video);
    emit("quick-recover", { reason, handle: currentLiveHandle(), attempt: quickRecoverFailures, played });
    if (!played || quickRecoverFailures >= 3) {
      quickRecoverFailures = 0;
      location.reload();
    }
  }

  function installVideoMonitor(video = primaryVideo()) {
    if (!video || monitoredVideos.has(video)) return;
    monitoredVideos.add(video);
    for (const eventName of ["stalled", "error", "waiting"]) {
      video.addEventListener(eventName, () => quickRecover(eventName), { passive: true });
    }
    video.addEventListener("playing", () => { quickRecoverFailures = 0; }, { passive: true });
  }

  async function command(name, payload = {}) {
    if (!ALLOWED_COMMANDS.has(name)) return emit("bridge-error", { operation: "command", message: "Unknown command" });
    const video = primaryVideo();
    try {
      if (name === "inspect" || name === "hook-status") inspect();
      else if (name === "play") await video?.play();
      else if (name === "pause") video?.pause();
      else if (name === "mute" && video) video.muted = true;
      else if (name === "unmute" && video) video.muted = false;
      else if (name === "set-volume" && video) video.volume = Math.max(0, Math.min(1, Number(payload.value) || 0));
      else if (name === "fullscreen") await video?.requestFullscreen?.();
      else if (name === "picture-in-picture") await video?.requestPictureInPicture?.();
      else if (name === "reload-player" && video) video.load();
      else if (name === "captions") [...document.querySelectorAll("button,[role=menuitem]")].find((node) => /caption|untertitel/i.test(node.textContent || ""))?.click();
      else if (name === "refresh") { location.reload(); setTimeout(() => playAndUnmute(), 800); }
      else if (name === "force-profile") {
        const match = location.pathname.match(/^\/@([^/]+)\/live/);
        if (match) location.assign(`/@${encodeURIComponent(match[1])}`);
      } else if (name === "open-report") [...document.querySelectorAll("button,[role=menuitem]")].find((node) => /report|melden/i.test(node.textContent || ""))?.click();
      else if (name === "start-webview-audio") await startAudioCapture();
      else if (name === "stop-webview-audio") await stopAudioCapture();
      else if (name === "set-auto-reconnect") autoReconnectEnabled = Boolean(payload.enabled);
      else if (name === "set-limiter") {
        limiterStrength = Math.max(0, Math.min(100, Number(payload.strength) || 0));
        emit("limiter", { enabled: Boolean(payload.enabled), strength: limiterStrength, thresholdDbfs: limiterStrengthToDbfs(limiterStrength), mode: "mobile-webview" });
      }
      emit("command-result", { command: name, ok: true });
    } catch (error) {
      emit("command-result", { command: name, ok: false, error: text(error?.message || error, 512) });
    }
  }

  root.TLC_MOBILE_BRIDGE = Object.freeze({ command, inspect });
  installWebSocketHook();
  setInterval(() => installVideoMonitor(), 2000);
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", inspect, { once: true }); else inspect();
  emit("bridge-ready", { version: "0.7.1", origin: location.origin, autoReconnect: autoReconnectEnabled });
})(globalThis);
