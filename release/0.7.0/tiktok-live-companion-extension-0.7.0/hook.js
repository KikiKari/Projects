(function () {
  "use strict";

  const installedKey = Symbol.for("tiktok-live-companion.ws-hook");
  if (window[installedKey]) return;

  const proto = window[Symbol.for("tiktok-live-companion.proto")];
  const NativeWebSocket = window.WebSocket;

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

  function streamIdentity(url) {
    try {
      const parsed = new URL(String(url), location.href);
      return {
        handle: decodeURIComponent(location.pathname.match(/^\/@([^/]+)/)?.[1] || "").toLocaleLowerCase(),
        roomId: parsed.searchParams.get("room_id") || parsed.searchParams.get("roomId") || ""
      };
    } catch (_) {
      return { handle: "", roomId: "" };
    }
  }

  async function inspectMessage(event, endpoint) {
    try {
      if (typeof event.data === "string") return;
      const size = event.data?.size ?? event.data?.byteLength ?? 0;
      if (size > 16 * 1024 * 1024) return;
      const decoded = await proto.decodeWebSocketPayload(event.data);
      for (const caption of decoded.captions) {
        post("caption", {
          caption: {
            ...caption,
            receivedAtUtc: new Date().toISOString(),
            endpoint
          }
        });
      }
      for (const liveEvent of decoded.liveEvents) {
        post("live-event", {
          liveEvent: {
            ...liveEvent,
            receivedAtUtc: new Date().toISOString(),
            endpoint
          }
        });
      }
      for (const chatMessage of decoded.chatMessages || []) {
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
      const message = String(error?.message || error);
      if (!/Invalid protobuf|Truncated|Unsupported protobuf/.test(message)) {
        post("hook-status", { hook: { installed: true, lastError: message.slice(0, 300) } });
      }
    }
  }

  const WrappedWebSocket = new Proxy(NativeWebSocket, {
    construct(target, args, newTarget) {
      const socket = Reflect.construct(target, args, newTarget);
      const endpoint = safeEndpoint(args[0]);
      const stream = streamIdentity(args[0]);
      socket.addEventListener("open", () => {
        post("hook-status", { hook: { armed: true, installed: true, connected: true, endpoint, stream, lastError: null } });
      });
      socket.addEventListener("close", () => {
        post("hook-status", { hook: { armed: true, installed: true, connected: false, endpoint } });
      });
      socket.addEventListener("message", (event) => { inspectMessage(event, endpoint); });
      return socket;
    }
  });

  Object.defineProperty(window, installedKey, { value: true, configurable: false, enumerable: false });
  Object.defineProperty(window, "WebSocket", { value: WrappedWebSocket, configurable: true, writable: true });
  post("hook-status", { hook: { armed: true, installed: true, connected: false, lastError: null } });
})();
