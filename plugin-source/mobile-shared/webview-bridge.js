(function (root) {
  "use strict";

  if (location.protocol !== "https:" || location.hostname !== "www.tiktok.com") return;
  let isTop = true;
  try { isTop = root.top === root; } catch (_) { isTop = false; }
  const MAX_MESSAGE_BYTES = 64 * 1024;
  const MAX_CHAT = 50;
  const MAX_AUDIO_SECONDS = 12;
  const MAX_MEDIA_URLS = 12;
  const FORCE_RETURN_KEY = "tlc-force-return";
  const FORCE_RETURN_DELAY_MS = 8_000;
  const FORCE_RETURN_MAX_ATTEMPTS = 2;
  const ALLOWED_COMMANDS = new Set([
    "inspect", "hook-status", "play", "pause", "mute", "unmute", "set-volume",
    "reload-player", "captions", "refresh",
    "force-profile", "open-report", "start-audible", "start-webview-audio", "stop-webview-audio", "set-limiter"
  ]);
  let sequence = 0;
  let streamId = "";
  let audioCapture = null;
  let audioGraph = null;
  const limiter = { enabled: false, threshold: -6 };
  const chat = [];
  const seenLiveEventIds = new Set();
  const mediaUrls = new Map();
  let focusedVideo = null;
  let focusedVideoAncestors = [];
  let focusedVideoHadControls = false;
  let audibleStartRequested = false;
  const contentCore = root.TLC_CONTENT_CORE;

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

  function ensureMobileViewport() {
    if (!isTop) return;
    let viewport = document.querySelector('meta[name="viewport"]');
    if (!viewport) {
      viewport = document.createElement("meta");
      viewport.name = "viewport";
      (document.head || document.documentElement).appendChild(viewport);
    }
    viewport.content = "width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover";
  }

  function rememberMediaUrl(value, kind = "media") {
    try {
      const candidate = new URL(String(value || ""), location.href);
      if (candidate.protocol !== "https:" || !contentCore?.classifyMediaUrl) return false;
      const classified = contentCore.classifyMediaUrl(candidate.href);
      if (!classified) return false;
      const normalized = classified.url.slice(0, 4_096);
      if (mediaUrls.has(normalized)) return false;
      const label = `${classified.quality || "unbekannt"} · ${classified.protocol || kind}`;
      mediaUrls.set(normalized, text(label, 32));
      while (mediaUrls.size > MAX_MEDIA_URLS) mediaUrls.delete(mediaUrls.keys().next().value);
      emit("media-url", { url: normalized, kind: mediaUrls.get(normalized), count: mediaUrls.size, limit: MAX_MEDIA_URLS });
      return true;
    } catch (_) { return false; }
  }

  function collectMediaUrls() {
    const video = primaryVideo();
    rememberMediaUrl(video?.currentSrc || video?.src, "player");
    for (const source of video?.querySelectorAll?.("source[src]") || []) rememberMediaUrl(source.src, "source");
    for (const entry of (performance.getEntriesByType?.("resource") || []).slice(-400)) rememberMediaUrl(entry.name, "network");
    if (!contentCore?.inspectMetadata) return;
    for (const script of [...document.scripts].slice(-80)) {
      const value = script.textContent || "";
      if (!value || value.length > 2_000_000 || !/(?:\.flv|\.m3u8|only_audio)/i.test(value)) continue;
      const result = contentCore.inspectMetadata(value, { maxNodes: 5_000 });
      for (const item of result.media || []) rememberMediaUrl(item.url, item.protocol);
    }
  }

  function clearPlayerFocus() {
    if (focusedVideo) {
      focusedVideo.removeAttribute?.("data-tlc-mobile-primary-video");
      focusedVideo.controls = focusedVideoHadControls;
    }
    for (const ancestor of focusedVideoAncestors) ancestor.removeAttribute?.("data-tlc-mobile-video-ancestor");
    focusedVideo = null;
    focusedVideoAncestors = [];
    focusedVideoHadControls = false;
  }

  function applyPlayerFocus() {
    if (!isTop) return false;
    const video = primaryVideo();
    if (!video) return false;
    if (focusedVideo !== video) {
      clearPlayerFocus();
      focusedVideoHadControls = video.controls;
      focusedVideo = video;
      for (let ancestor = video.parentElement; ancestor && ancestor !== document.body; ancestor = ancestor.parentElement) {
        ancestor.setAttribute("data-tlc-mobile-video-ancestor", "true");
        focusedVideoAncestors.push(ancestor);
      }
    }
    if (video.dataset.tlcMediaObserved !== "true") {
      video.dataset.tlcMediaObserved = "true";
      for (const eventName of ["loadedmetadata", "canplay", "playing"]) video.addEventListener(eventName, collectMediaUrls);
    }
    document.documentElement.setAttribute("data-tlc-mobile-focus", "true");
    video.setAttribute("data-tlc-mobile-primary-video", "true");
    video.controls = true;
    if (!document.getElementById("tlc-mobile-player-style")) {
      const style = document.createElement("style");
      style.id = "tlc-mobile-player-style";
      style.textContent = `
        html[data-tlc-mobile-focus="true"],html[data-tlc-mobile-focus="true"] body{overflow-x:hidden!important;overflow-y:auto!important;background:#000!important}
        html[data-tlc-mobile-focus="true"] body *:not(video[data-tlc-mobile-primary-video="true"]){z-index:auto!important}
        [data-tlc-mobile-video-ancestor="true"]{position:static!important;transform:none!important;scale:none!important;translate:none!important;rotate:none!important;zoom:1!important;filter:none!important;perspective:none!important;contain:none!important;clip-path:none!important;overflow:visible!important;max-width:none!important;max-height:none!important}
        video[data-tlc-mobile-primary-video="true"]{position:absolute!important;top:0!important;left:0!important;width:100dvw!important;height:100dvh!important;max-width:none!important;max-height:none!important;margin:0!important;transform:none!important;scale:none!important;zoom:1!important;object-fit:contain!important;background:#000!important;z-index:2147483647!important;pointer-events:auto!important;touch-action:pan-y!important;visibility:visible!important}
      `;
      (document.head || document.documentElement).appendChild(style);
    }
    emit("capability", { feature: "player-focus", available: true });
    if (audibleStartRequested) void attemptAudibleStart();
    collectMediaUrls();
    return true;
  }

  async function attemptAudibleStart() {
    const video = primaryVideo();
    if (!video) return emit("player-state", { available: false, muted: true, paused: true, reason: "video-unavailable" });
    audibleStartRequested = true;
    video.muted = false;
    video.defaultMuted = false;
    if (video.volume <= 0) video.volume = 1;
    try {
      await video.play();
      emit("player-state", { available: true, muted: video.muted, paused: video.paused, volume: video.volume, audible: !video.muted && video.volume > 0 });
    } catch (error) {
      emit("player-state", { available: true, muted: video.muted, paused: video.paused, volume: video.volume, audible: false, reason: "autoplay-blocked", message: text(error?.message || error, 256) });
    }
  }

  function metaValue(name, property = false) {
    return text(document.querySelector(`meta[${property ? "property" : "name"}="${name}"]`)?.content || "", 1000);
  }

  function inspect() {
    const video = primaryVideo();
    applyPlayerFocus();
    collectMediaUrls();
    const captionButtons = [...document.querySelectorAll("button,[role=menuitem]")].filter((node) => /caption|untertitel/i.test(node.textContent || ""));
    const creatorHandle = decodeURIComponent((location.pathname.match(/^\/@([^/]+)/) || [])[1] || "");
    const creatorName = metaValue("og:title", true).replace(/\s*[|·-]\s*TikTok.*$/i, "");
    const followerNode = document.querySelector('[data-e2e="followers-count"]');
    emit("inspection", {
      title: text(document.title, 256),
      url: `${location.origin}${location.pathname}`,
      description: metaValue("description") || metaValue("og:description", true),
      imageUrl: metaValue("og:image", true),
      language: text(document.documentElement.lang, 24),
      creatorName,
      creatorHandle: creatorHandle ? `@${creatorHandle}` : "",
      followerText: text(followerNode?.textContent || "", 128),
      followingText: text(document.querySelector('[data-e2e="following-count"]')?.textContent || "", 128),
      profileLikesText: text(document.querySelector('[data-e2e="likes-count"]')?.textContent || "", 128),
      signature: text(document.querySelector('[data-e2e="user-bio"], [data-e2e="user-signature"]')?.textContent || "", 1000),
      verified: Boolean(document.querySelector('[data-e2e*="verified"], [aria-label*="Verified" i], [aria-label*="Verifiziert" i]')),
      livePage: /^\/@[^/]+\/live(?:\/|$)/.test(location.pathname),
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
    for (const item of decoded.liveEvents || []) {
      const eventId = text(item.eventId || item.messageId || item.msgId || "", 128);
      if (eventId && seenLiveEventIds.has(eventId)) continue;
      if (eventId) {
        seenLiveEventIds.add(eventId);
        if (seenLiveEventIds.size > 5_000) seenLiveEventIds.delete(seenLiveEventIds.values().next().value);
      }
      emit("live-stats", item);
    }
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
      const silentSink = context.createGain();
      silentSink.gain.value = 0;
      silentSink.connect(context.destination);
      compressor.ratio.value = 20;
      compressor.knee.value = 0;
      compressor.attack.value = 0.003;
      compressor.release.value = 0.25;
      audioGraph = { context, source, compressor, silentSink, video };
      rewireAudioGraph();
      return audioGraph;
    } catch (error) {
      emit("bridge-error", { operation: "audio-graph", message: text(error?.message || error, 512) });
      return null;
    }
  }

  function rewireAudioGraph() {
    if (!audioGraph) return;
    const { context, source, compressor, silentSink } = audioGraph;
    try { source.disconnect(); } catch (_) {}
    try { compressor.disconnect(); } catch (_) {}
    if (limiter.enabled) {
      compressor.threshold.value = Math.max(-30, Math.min(-1, Number(limiter.threshold) || -6));
      source.connect(compressor).connect(context.destination);
    } else {
      source.connect(context.destination);
    }
    if (audioCapture) { source.connect(audioCapture.processor); audioCapture.processor.connect(silentSink); }
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
        event.outputBuffer.getChannelData(0).fill(0);
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

  function rejectCookieConsent() {
    const rejectPattern = /alle ablehnen|reject all|decline all|nur (?:erforderliche|notwendige) cookies|only necessary cookies/i;
    const cookiePattern = /cookie|cookies|datenschutz|privacy/i;
    for (const node of document.querySelectorAll("button, [role=button]")) {
      if (node.offsetParent === null) continue;
      const label = `${node.getAttribute?.("aria-label") || ""} ${node.textContent || ""}`;
      if (!rejectPattern.test(label)) continue;
      const scope = node.closest('[role="dialog"], [aria-modal="true"]') || node.parentElement;
      if (!cookiePattern.test(scope?.textContent || label)) continue;
      try { node.click(); emit("capability", { feature: "cookie-consent", available: true, rejected: true }); return true; } catch (_) { return false; }
    }
    return false;
  }

  function validatedLiveUrl(value) {
    try {
      const candidate = new URL(String(value || ""), location.origin);
      return candidate.origin === location.origin && /^\/@[^/]+\/live(?:\/|$)/.test(candidate.pathname) ? candidate.href : null;
    } catch (_) { return null; }
  }

  function handleForceReturn() {
    const marker = readForceMarker();
    if (!marker || typeof marker.url !== "string") return;
    if (validatedLiveUrl(location.href) === validatedLiveUrl(marker.url)) {
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
      else if (name === "start-audible") await attemptAudibleStart();
      else if (name === "set-volume" && video) video.volume = Math.max(0, Math.min(1, Number(payload.value) || 0));
      else if (name === "reload-player" && video) video.load();
      else if (name === "captions") [...document.querySelectorAll("button,[role=menuitem]")].find((node) => /caption|untertitel/i.test(node.textContent || ""))?.click();
      else if (name === "refresh") location.reload();
      else if (name === "force-profile") {
        const match = location.pathname.match(/^\/@([^/]+)\/live/);
        const liveUrl = validatedLiveUrl(payload.liveUrl) || validatedLiveUrl(location.href);
        if (match && liveUrl) {
          try { sessionStorage.setItem(FORCE_RETURN_KEY, JSON.stringify({ url: liveUrl, attempts: 0, startedAt: Date.now() })); } catch (_) {}
          emit("force-start", { url: liveUrl, timeoutMs: 20_000, bridgeDelayMs: FORCE_RETURN_DELAY_MS, maxAttempts: FORCE_RETURN_MAX_ATTEMPTS });
          location.assign(`/@${encodeURIComponent(match[1])}`);
        } else emit("force-return", { ok: false, reason: "invalid-live-url" });
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
  const startTopFrame = () => {
    ensureMobileViewport();
    rejectCookieConsent();
    inspect();
    handleForceReturn();
    const observer = new MutationObserver(() => {
      ensureMobileViewport();
      rejectCookieConsent();
      if (!focusedVideo?.isConnected || primaryVideo() !== focusedVideo) applyPlayerFocus();
    });
    observer.observe(document.documentElement, { childList: true, subtree: true });
  };
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", startTopFrame, { once: true }); else startTopFrame();
  emit("bridge-ready", { version: "0.8.0", origin: location.origin, documentStart: true });
})(globalThis);
