(function (root) {
  "use strict";

  if (location.protocol !== "https:" || location.hostname !== "www.tiktok.com") return;
  let isTop = true;
  try { isTop = root.top === root; } catch (_) { isTop = false; }
  const MAX_MESSAGE_BYTES = 64 * 1024;
  const MAX_CHAT = 50;
  const MAX_AUDIO_SECONDS = 12;
  const FORCE_RETURN_KEY = "tlc-force-return";
  const FORCE_RETURN_DELAY_MS = 8_000;
  const FORCE_RETURN_MAX_ATTEMPTS = 2;
  const ALLOWED_COMMANDS = new Set([
    "inspect", "hook-status", "play", "pause", "mute", "unmute", "set-volume",
    "fullscreen", "picture-in-picture", "reload-player", "captions", "refresh",
    "force-profile", "open-report", "start-webview-audio", "stop-webview-audio", "set-limiter"
  ]);
  let sequence = 0;
  let streamId = "";
  let audioCapture = null;
  let audioGraph = null;
  const limiter = { enabled: false, threshold: -6 };
  const chat = [];

  function nativePost(message) {
    const serialized = JSON.stringify(message);
    if (new TextEncoder().encode(serialized).byteLength > MAX_MESSAGE_BYTES) return;
    if (root.webkit?.messageHandlers?.tlcBridge?.postMessage) root.webkit.messageHandlers.tlcBridge.postMessage(message);
    else if (root.tlcBridge?.postMessage) root.tlcBridge.postMessage(serialized);
  }

  function emit(type, payload = {}) {
    nativePost({ version: 1, type, streamId, sequence: ++sequence, timestamp: new Date().toISOString(), payload: { ...payload, frameOrigin: location.origin, frameKind: isTop ? "top" : "sub" } });
  }

  function text(value, max = 2048) {
    return String(value ?? "").replace(/[\u0000-\u001f\u007f]/g, " ").trim().slice(0, max);
  }

  function primaryVideo() {
    return [...document.querySelectorAll("video")].sort((a, b) => (b.clientWidth * b.clientHeight) - (a.clientWidth * a.clientHeight))[0] || null;
  }

  function inspect() {
    const video = primaryVideo();
    const captionButtons = [...document.querySelectorAll("button,[role=menuitem]")].filter((node) => /caption|untertitel/i.test(node.textContent || ""));
    emit("inspection", {
      title: text(document.title, 256),
      url: `${location.origin}${location.pathname}`,
      videoPresent: Boolean(video),
      captionsControlPresent: captionButtons.length > 0,
      player: video ? { paused: video.paused, muted: video.muted, volume: video.volume, duration: Number.isFinite(video.duration) ? video.duration : null } : null
    });
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
        try {
          const parsed = new URL(String(args[0] ?? ""), location.href);
          emit("socket-open", { endpoint: `${parsed.origin}${parsed.pathname}`, frame: isTop ? "top" : "sub" });
        } catch (_) {}
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
    emit("capability", { feature: "websocket-hook", available: true, frame: isTop ? "top" : "sub" });
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

  async function ensureAudioGraph() {
    const video = primaryVideo();
    if (!video || typeof AudioContext !== "function") return null;
    if (audioGraph && audioGraph.video === video) return audioGraph;
    if (audioGraph) { try { await audioGraph.context.close(); } catch (_) {} audioGraph = null; }
    try {
      const context = new AudioContext({ sampleRate: 48_000 });
      await context.resume();
      const source = context.createMediaElementSource(video);
      const compressor = context.createDynamicsCompressor();
      compressor.ratio.value = 20;
      compressor.knee.value = 0;
      compressor.attack.value = 0.003;
      compressor.release.value = 0.25;
      audioGraph = { context, source, compressor, video };
      rewireAudioGraph();
      return audioGraph;
    } catch (error) {
      emit("bridge-error", { operation: "audio-graph", message: text(error?.message || error, 512) });
      return null;
    }
  }

  function rewireAudioGraph() {
    if (!audioGraph) return;
    const { context, source, compressor } = audioGraph;
    try { source.disconnect(); } catch (_) {}
    try { compressor.disconnect(); } catch (_) {}
    if (limiter.enabled) {
      compressor.threshold.value = Math.max(-30, Math.min(-1, Number(limiter.threshold) || -6));
      source.connect(compressor).connect(context.destination);
    } else {
      source.connect(context.destination);
    }
    if (audioCapture) { source.connect(audioCapture.processor); audioCapture.processor.connect(context.destination); }
  }

  async function applyLimiter(payload) {
    limiter.enabled = payload.enabled === true;
    limiter.threshold = Number(payload.threshold);
    if (!Number.isFinite(limiter.threshold)) limiter.threshold = -6;
    const graph = limiter.enabled ? await ensureAudioGraph() : audioGraph;
    if (limiter.enabled && !graph) return emit("capability", { feature: "limiter", available: false, reason: "Player or Web Audio unavailable" });
    rewireAudioGraph();
    emit("capability", { feature: "limiter", available: true, enabled: limiter.enabled, threshold: limiter.threshold });
  }

  async function stopAudioCapture(reason = "stopped") {
    if (!audioCapture) return;
    const current = audioCapture;
    audioCapture = null;
    try { current.processor.disconnect(); } catch (_) {}
    rewireAudioGraph();
    emit("audio-complete", { reason });
  }

  async function startAudioCapture() {
    if (audioCapture) return;
    const graph = await ensureAudioGraph();
    if (!graph) return emit("capability", { feature: "webview-audio", available: false, reason: "Player or Web Audio unavailable" });
    try {
      const processor = graph.context.createScriptProcessor(2048, 1, 1);
      const startedAt = performance.now();
      processor.onaudioprocess = (event) => {
        if (!audioCapture) return;
        const elapsed = (performance.now() - startedAt) / 1000;
        if (elapsed >= MAX_AUDIO_SECONDS) return void stopAudioCapture("completed");
        const input = event.inputBuffer.getChannelData(0);
        event.outputBuffer.getChannelData(0).set(input);
        emit("audio-chunk", { encoding: "pcm_s16le", channels: 1, sampleRate: graph.context.sampleRate, elapsed, data: pcm16Base64(input) });
      };
      audioCapture = { processor };
      rewireAudioGraph();
      emit("capability", { feature: "webview-audio", available: true, sampleRate: graph.context.sampleRate });
    } catch (error) {
      await stopAudioCapture("failed");
      emit("capability", { feature: "webview-audio", available: false, reason: text(error?.message || error, 512) });
    }
  }

  function dismissOverlays() {
    const pattern = /alle akzeptieren|accept all|akzeptieren|zustimmen|einverstanden|schließen|close|not now|jetzt nicht|später|skip|überspringen|weiter im browser|continue in browser|dismiss|ablehnen/i;
    let clicks = 0;
    for (const node of document.querySelectorAll("button, [role=button], [aria-label]")) {
      if (clicks >= 3) break;
      const label = `${node.getAttribute?.("aria-label") || ""} ${node.textContent || ""}`;
      if (pattern.test(label) && node.offsetParent !== null) { try { node.click(); clicks += 1; } catch (_) {} }
    }
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));
    return clicks;
  }

  function readForceMarker() {
    try { return JSON.parse(sessionStorage.getItem(FORCE_RETURN_KEY) || "null"); } catch (_) { return null; }
  }

  function handleForceReturn() {
    const marker = readForceMarker();
    if (!marker || typeof marker.url !== "string") return;
    if (/^\/@[^/]+\/live/.test(location.pathname)) {
      sessionStorage.removeItem(FORCE_RETURN_KEY);
      emit("force-return", { ok: true, attempts: marker.attempts || 0 });
      return;
    }
    if ((marker.attempts || 0) >= FORCE_RETURN_MAX_ATTEMPTS) {
      sessionStorage.removeItem(FORCE_RETURN_KEY);
      emit("force-return", { ok: false, reason: "max-attempts", attempts: marker.attempts });
      return;
    }
    emit("force-return", { ok: null, pending: true, attempts: marker.attempts || 0 });
    const interval = setInterval(dismissOverlays, 1_000);
    setTimeout(() => {
      clearInterval(interval);
      const current = readForceMarker();
      if (!current) return;
      current.attempts = (current.attempts || 0) + 1;
      try { sessionStorage.setItem(FORCE_RETURN_KEY, JSON.stringify(current)); } catch (_) {}
      location.assign(current.url);
    }, FORCE_RETURN_DELAY_MS);
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
      else if (name === "refresh") location.reload();
      else if (name === "force-profile") {
        const match = location.pathname.match(/^\/@([^/]+)\/live/);
        if (match) {
          try { sessionStorage.setItem(FORCE_RETURN_KEY, JSON.stringify({ url: `${location.origin}${location.pathname}`, attempts: 0 })); } catch (_) {}
          location.assign(`/@${encodeURIComponent(match[1])}`);
        }
      } else if (name === "open-report") [...document.querySelectorAll("button,[role=menuitem]")].find((node) => /report|melden/i.test(node.textContent || ""))?.click();
      else if (name === "start-webview-audio") await startAudioCapture();
      else if (name === "stop-webview-audio") await stopAudioCapture();
      else if (name === "set-limiter") await applyLimiter(payload);
      emit("command-result", { command: name, ok: true });
    } catch (error) {
      emit("command-result", { command: name, ok: false, error: text(error?.message || error, 512) });
    }
  }

  installWebSocketHook();
  if (!isTop) return; // Subframes liefern nur dekodierte WebSocket-Daten.
  root.TLC_MOBILE_BRIDGE = Object.freeze({ command, inspect });
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", () => { inspect(); handleForceReturn(); }, { once: true }); else { inspect(); handleForceReturn(); }
  emit("bridge-ready", { version: "0.8.0", origin: location.origin, documentStart: true });
})(globalThis);
