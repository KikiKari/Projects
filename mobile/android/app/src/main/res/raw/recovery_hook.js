(function () {
  "use strict";

  const installedKey = Symbol.for("tiktok-live-companion.ws-hook");
  if (window[installedKey]) return;

  const proto = window[Symbol.for("tiktok-live-companion.proto")];
  const NativeWebSocket = window.WebSocket;
  const documentId = crypto.randomUUID();
  const openSockets = new Map();
  const recentMessages = new Map();
  const recoveryFactory = window[Symbol.for("tiktok-live-companion.hook-recovery")];
  const identity = () => currentLiveHandle() ? `${location.pathname}|${currentLiveHandle()}` : "";
  const controller = recoveryFactory?.create({ identity,
    emit: (recovery) => post("hook-recovery", { recovery: { ...recovery, documentId,
      mode: /^\/embed\/live\//i.test(location.pathname) ? "embed" : "normal" } }),
    connect: (template, token) => {
      const socket = Reflect.construct(NativeWebSocket, template.args);
      const state = observeSocket(socket, template.args, token, template.profile);
      return { close() { state.open = false; clearInterval(state.heartbeat); openSockets.delete(state.id); socket.close(); publishStatus(); } };
    }
  });

  function trace(socketState, stage, extra = {}) {
    post("socket-telemetry", { telemetry: {
      documentId, socketId: socketState.id, stage,
      atUtc: new Date().toISOString(), elapsedMs: Math.max(0, performance.now() - socketState.started),
      mode: /^\/embed\/live\//i.test(location.pathname) ? "embed" : "normal",
      owner: socketState.token ? "extension" : "tiktok", hookAttemptId: socketState.token?.id || null, ...extra
    } });
  }

  function post(type, payload) {
    window.postMessage({ source: "tiktok-live-companion", version: 1, type, ...payload }, location.origin);
  }

  if (!proto || !NativeWebSocket) {
    post("hook-status", { hook: { armed: true, installed: false, connected: false, lastError: "WebSocket oder Decoder nicht verfügbar" } });
    return;
  }

  function safeEndpoint(url) {
    try {
      const parsed = new URL(String(url), location.href);
      return `${parsed.origin}${parsed.pathname}`;
    } catch (_) {
      return "unbekannt";
    }
  }

  function currentLiveHandle() {
    const path = decodeURIComponent(location.pathname);
    return (
      path.match(/^\/@([^/]+)\/live\/?$/i)?.[1]
      || path.match(/^\/embed\/live\/@?([^/?#]+)\/?$/i)?.[1]
      || ""
    ).toLocaleLowerCase();
  }

  function streamIdentity(url) {
    try {
      const parsed = new URL(String(url), location.href);
      return {
        handle: currentLiveHandle(),
        roomId: parsed.searchParams.get("room_id") || parsed.searchParams.get("roomId") || ""
      };
    } catch (_) {
      return { handle: "", roomId: "" };
    }
  }

  async function inspectMessage(event, endpoint, socketState) {
    try {
      if (typeof event.data === "string") return;
      const size = event.data?.size ?? event.data?.byteLength ?? 0;
      if (size > 16 * 1024 * 1024) return;
      const envelope = proto.decodeWebSocketEnvelope ? await proto.decodeWebSocketEnvelope(event.data) : null;
      const decoded = envelope?.records || await proto.decodeWebSocketPayload(event.data);
      if (!socketState.open || socketState.identity !== identity() ||
          (socketState.token && !controller.isCurrent(socketState.token))) return;
      if (envelope?.transport?.type === "msg" && envelope.transport.id) {
        const transport = envelope.transport;
        socketState.responses.set(transport.id, transport);
        if (socketState.responses.size > 50) socketState.responses.delete(socketState.responses.keys().next().value);
        if (socketState.token) {
          if (socketState.profile.ack === "ext" && transport.needAck && !transport.internalExt) {
            controller.failed(socketState.token, "protocol-unverified"); return;
          }
          if (transport.needAck && BigInt(transport.id) > 0n) socketState.socket.send(proto.encodeTransport("ack", transport.id,
            socketState.profile.ack === "ext" ? transport.internalExt : null));
        } else validateControls(socketState);
      }
      const carriesLiveData = [decoded.captions, decoded.chatMessages, decoded.liveEvents, decoded.giftMessages]
        .some((records) => records?.length > 0);
      if (carriesLiveData && socketState.open && !socketState.qualified) {
        socketState.qualified = true;
        openSockets.set(socketState.id, { endpoint, stream: socketState.stream });
        if (socketState.token) {
          controller.stage(socketState.token, "first-decoded-message");
          controller.connected(socketState.token);
        } else controller?.nativeConnected(socketState.template);
        post("hook-status", { hook: { armed: true, installed: true, connected: true,
          endpoint, stream: socketState.stream, lastError: null } });
      }
      for (const [kind, records] of Object.entries({ caption: decoded.captions, chat: decoded.chatMessages,
        live: decoded.liveEvents, gift: decoded.giftMessages })) {
        if (records?.length && !socketState.decoded.has(kind)) {
          socketState.decoded.add(kind);
          trace(socketState, "first-decoded-message", { kind });
        }
      }
      for (const caption of decoded.captions) {
        if (duplicate("caption", caption)) continue;
        post("caption", {
          caption: {
            ...caption,
            receivedAtUtc: new Date().toISOString(),
            endpoint
          }
        });
      }
      for (const liveEvent of decoded.liveEvents) {
        if (duplicate("live", liveEvent)) continue;
        post("live-event", {
          liveEvent: {
            ...liveEvent,
            receivedAtUtc: new Date().toISOString(),
            endpoint
          }
        });
      }
      for (const chatMessage of decoded.chatMessages || []) {
        if (duplicate("chat", chatMessage)) continue;
        post("chat-message", {
          chatMessage: {
            ...chatMessage,
            source: "websocket",
            receivedAtUtc: new Date().toISOString(),
            endpoint
          }
        });
      }
      for (const giftMessage of decoded.giftMessages || []) {
        if (duplicate("gift", giftMessage)) continue;
        post("gift-message", {
          giftMessage: {
            ...giftMessage,
            source: "websocket",
            receivedAtUtc: new Date().toISOString(),
            endpoint
          }
        });
      }
    } catch (error) {
      if (socketState.token) { controller.failed(socketState.token, "protocol-error"); return; }
      const message = String(error?.message || error);
      if (!/Invalid protobuf|Truncated|Unsupported protobuf/.test(message)) {
        post("hook-status", { hook: { installed: true, lastError: message.slice(0, 300) } });
      }
    }
  }

  function duplicate(kind, record) {
    if (!record.messageId) return false;
    const key = `${identity()}|${kind}|${record.messageId}`;
    if (recentMessages.has(key)) return true;
    recentMessages.set(key, true);
    if (recentMessages.size > 2000) recentMessages.delete(recentMessages.keys().next().value);
    return false;
  }

  function publishStatus() {
    const active = [...openSockets.values()].at(-1);
    post("hook-status", { hook: { armed: true, installed: true, connected: Boolean(active),
      ...(active ? { endpoint: active.endpoint, stream: active.stream, lastError: null } : {}) } });
  }

  function validateControls(state) {
    for (const control of state.controls) {
      const response = state.responses.get(control.id);
      if (!response) continue;
      if (control.payload === null) state.profile.ack = "id";
      else if (control.payload === response.internalExt) state.profile.ack = "ext";
    }
    state.template.supported = Boolean(state.profile.heartbeatIntervalMs && state.profile.ack && state.allowed);
  }

  function observeSocket(socket, args, token = null, profile = {}) {
      const endpoint = safeEndpoint(args[0]);
      const stream = streamIdentity(args[0]);
      const socketState = { id: crypto.randomUUID(), started: performance.now(), firstFrame: false, decoded: new Set(),
        stream, open: false, qualified: false, identity: identity(), socket, token, profile,
        responses: new Map(), controls: [], heartbeat: null };
      try {
        const parsed = new URL(String(args[0]));
        socketState.allowed = parsed.protocol === "wss:" && /(^|\.)(tiktok\.com|tiktokv\.com)$/.test(parsed.hostname);
      } catch (_) { socketState.allowed = false; }
      socketState.template = { args: [String(args[0]), ...(args.length > 1 ? [Array.isArray(args[1]) ? [...args[1]] : args[1]] : [])],
        profile, supported: false };
      if (!token && typeof socket.send === "function" && proto.inspectTransportControl) {
        const nativeSend = socket.send;
        socket.send = function (data) {
          const result = nativeSend.call(this, data);
          if (this === socket) {
            const control = proto.inspectTransportControl(data);
            if (control?.type === "hb") { const stamp = performance.now();
              if (socketState.lastHeartbeatAt != null) {
                const interval = stamp - socketState.lastHeartbeatAt;
                if (interval >= 100 && interval <= 60000) profile.heartbeatIntervalMs = interval;
              }
              socketState.lastHeartbeatAt = stamp;
            }
            if (control?.type === "ack") {
              socketState.controls.push(control);
              if (socketState.controls.length > 50) socketState.controls.shift();
            }
            validateControls(socketState);
          }
          return result;
        };
      }
      trace(socketState, "socket-created");
      socket.addEventListener("open", () => {
        if (token && !controller.isCurrent(token)) { socket.close(); return; }
        socketState.open = true;
        trace(socketState, "socket-open");
        if (token) {
          controller.stage(token, "socket-open");
          socketState.heartbeat = setInterval(() => {
            if (!controller.isCurrent(token) || !socketState.open) return;
            try { socket.send(proto.encodeTransport("hb")); }
            catch (_) { controller.failed(token, "send-error"); }
          }, profile.heartbeatIntervalMs);
        }
      });
      socket.addEventListener("close", (event) => {
        socketState.open = false;
        if (socketState.heartbeat != null) clearInterval(socketState.heartbeat);
        openSockets.delete(socketState.id);
        trace(socketState, "socket-close", { closeCode: event.code, wasClean: event.wasClean });
        if (token) controller.failed(token, event.code === 1008 ? "policy-rejected" : "socket-close");
        if (!socketState.qualified) return;
        // A replacement connection may already be open when its predecessor
        // closes. Preserve that connection rather than reporting a false gap.
        const active = [...openSockets.values()].at(-1);
        post("hook-status", { hook: { armed: true, installed: true, connected: Boolean(active),
          endpoint: active?.endpoint || endpoint, ...(active ? { stream: active.stream, lastError: null } : {}) } });
        if (!active && !token && socketState.identity === identity()) controller?.nativeDisconnected();
      });
      socket.addEventListener("error", () => trace(socketState, "socket-error"));
      socket.addEventListener("message", (event) => {
        if (!socketState.firstFrame) {
          socketState.firstFrame = true;
          trace(socketState, "first-frame");
          if (token) controller.stage(token, "first-frame");
        }
        inspectMessage(event, endpoint, socketState);
      });
      return socketState;
  }
  const WrappedWebSocket = new Proxy(NativeWebSocket, {
    construct(target, args, newTarget) {
      const socket = Reflect.construct(target, args, newTarget);
      observeSocket(socket, args);
      return socket;
    }
  });

  Object.defineProperty(window, installedKey, { value: true, configurable: false, enumerable: false });
  Object.defineProperty(window, "WebSocket", { value: WrappedWebSocket, configurable: true, writable: true });
  if (controller) {
    window.addEventListener("message", (event) => {
      if (event.source !== window || event.origin !== location.origin ||
          event.data?.source !== "tiktok-live-companion-control") return;
      if (event.data.type === "hook-reconnect-config") controller.configure(event.data);
    });
    window.addEventListener("pagehide", () => controller.dispose(), { once: true });
    setInterval(() => { if (!controller.checkStream()) { openSockets.clear(); recentMessages.clear(); publishStatus(); } }, 250);
    post("hook-recovery-ready", {});
  }
  post("hook-status", { hook: { armed: true, installed: true, connected: false, lastError: null } });
})();
