(function (root) {
  "use strict";

  if (location.protocol !== "https:" || location.hostname !== "www.tiktok.com" || root.top !== root) return;
  const MAX_MESSAGE_BYTES = 64 * 1024;
  const MAX_CHAT = 50;
  const MAX_AUDIO_SECONDS = 12;
  const ALLOWED_COMMANDS = new Set([
    "inspect", "hook-status", "play", "pause", "mute", "unmute", "set-volume",
    "fullscreen", "picture-in-picture", "reload-player", "captions", "refresh",
    "force-profile", "open-report", "start-webview-audio", "stop-webview-audio"
  ]);
  let sequence = 0;
  let streamId = "";
  let audioCapture = null;
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
        if (match) location.assign(`/@${encodeURIComponent(match[1])}`);
      } else if (name === "open-report") [...document.querySelectorAll("button,[role=menuitem]")].find((node) => /report|melden/i.test(node.textContent || ""))?.click();
      else if (name === "start-webview-audio") await startAudioCapture();
      else if (name === "stop-webview-audio") await stopAudioCapture();
      emit("command-result", { command: name, ok: true });
    } catch (error) {
      emit("command-result", { command: name, ok: false, error: text(error?.message || error, 512) });
    }
  }

  root.TLC_MOBILE_BRIDGE = Object.freeze({ command, inspect });
  installWebSocketHook();
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", inspect, { once: true }); else inspect();
  emit("bridge-ready", { version: "0.7.0", origin: location.origin });
})(globalThis);
