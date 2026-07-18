(function (root, factory) {
  const api = factory();
  if (typeof module === "object" && module.exports) {
    module.exports = api;
  } else {
    Object.defineProperty(root, Symbol.for("tiktok-live-companion.proto"), {
      value: Object.freeze(api),
      configurable: false,
      enumerable: false,
      writable: false
    });
  }
})(globalThis, function () {
  "use strict";

  const decoder = new TextDecoder("utf-8", { fatal: false });

  function toBytes(value) {
    if (value instanceof Uint8Array) return value;
    if (value instanceof ArrayBuffer) return new Uint8Array(value);
    if (ArrayBuffer.isView(value)) return new Uint8Array(value.buffer, value.byteOffset, value.byteLength);
    throw new TypeError("Expected binary data");
  }

  function readVarint(bytes, offset) {
    let value = 0n;
    let shift = 0n;
    let cursor = offset;
    while (cursor < bytes.length && shift <= 70n) {
      const byte = bytes[cursor++];
      value |= BigInt(byte & 0x7f) << shift;
      if ((byte & 0x80) === 0) return { value, offset: cursor };
      shift += 7n;
    }
    throw new Error("Invalid protobuf varint");
  }

  function parseFields(input) {
    const bytes = toBytes(input);
    const fields = new Map();
    let offset = 0;
    while (offset < bytes.length) {
      const tag = readVarint(bytes, offset);
      offset = tag.offset;
      const field = Number(tag.value >> 3n);
      const wire = Number(tag.value & 7n);
      let value;
      if (field <= 0) throw new Error("Invalid protobuf field number");
      if (wire === 0) {
        const result = readVarint(bytes, offset);
        value = result.value;
        offset = result.offset;
      } else if (wire === 1) {
        if (offset + 8 > bytes.length) throw new Error("Truncated fixed64 field");
        value = bytes.slice(offset, offset + 8);
        offset += 8;
      } else if (wire === 2) {
        const lengthResult = readVarint(bytes, offset);
        const length = Number(lengthResult.value);
        offset = lengthResult.offset;
        if (!Number.isSafeInteger(length) || length < 0 || offset + length > bytes.length) {
          throw new Error("Truncated length-delimited field");
        }
        value = bytes.slice(offset, offset + length);
        offset += length;
      } else if (wire === 5) {
        if (offset + 4 > bytes.length) throw new Error("Truncated fixed32 field");
        value = bytes.slice(offset, offset + 4);
        offset += 4;
      } else {
        throw new Error(`Unsupported protobuf wire type ${wire}`);
      }
      if (!fields.has(field)) fields.set(field, []);
      fields.get(field).push({ wire, value });
    }
    return fields;
  }

  function first(fields, number, wire) {
    return (fields.get(number) || []).find((item) => wire == null || item.wire === wire)?.value;
  }

  function all(fields, number, wire) {
    return (fields.get(number) || []).filter((item) => wire == null || item.wire === wire).map((item) => item.value);
  }

  function text(value) {
    return value ? decoder.decode(value) : "";
  }

  function integer(value) {
    return value == null ? null : value.toString();
  }

  function decodeCommonPayload(payload) {
    if (!payload) return { messageId: null, displayKey: "" };
    const fields = parseFields(payload);
    const displayText = first(fields, 8, 2);
    let displayKey = "";
    if (displayText) {
      const textFields = parseFields(displayText);
      displayKey = text(first(textFields, 1, 2));
    }
    return { messageId: integer(first(fields, 2, 0)), displayKey };
  }

  function decodeCaptionPayload(payload) {
    const fields = parseFields(payload);
    const contents = all(fields, 4, 2).map((item) => {
      const contentFields = parseFields(item);
      return { lang: text(first(contentFields, 1, 2)), text: text(first(contentFields, 2, 2)) };
    }).filter((item) => item.lang || item.text);
    return {
      timestampMs: integer(first(fields, 2, 0)),
      durationMs: integer(first(fields, 3, 0)),
      sentenceId: integer(first(fields, 5, 0)),
      sequenceId: integer(first(fields, 6, 0)),
      definite: first(fields, 7, 0) === 1n,
      contents
    };
  }

  function decodeUserPayload(payload) {
    if (!payload) return { userId: null, nickname: "", displayId: "" };
    const fields = parseFields(payload);
    return {
      userId: integer(first(fields, 1, 0)),
      nickname: text(first(fields, 3, 2)),
      displayId: text(first(fields, 38, 2))
    };
  }

  function decodeChatPayload(payload) {
    const fields = parseFields(payload);
    const user = decodeUserPayload(first(fields, 2, 2));
    return {
      method: "WebcastChatMessage",
      ...decodeCommonPayload(first(fields, 1, 2)),
      ...user,
      content: text(first(fields, 3, 2)),
      contentLanguage: text(first(fields, 14, 2)),
      emoteCount: all(fields, 13, 2).length
    };
  }

  function decodeRoomUserPayload(payload) {
    const fields = parseFields(payload);
    return {
      method: "WebcastRoomUserSeqMessage",
      ...decodeCommonPayload(first(fields, 1, 2)),
      viewerCount: integer(first(fields, 3, 0)),
      totalViewers: integer(first(fields, 7, 0)),
      popularity: integer(first(fields, 6, 0)),
      displayCount: text(first(fields, 4, 2))
    };
  }

  function decodeLikePayload(payload) {
    const fields = parseFields(payload);
    return {
      method: "WebcastLikeMessage",
      ...decodeCommonPayload(first(fields, 1, 2)),
      likeDelta: integer(first(fields, 2, 0)),
      likeCount: integer(first(fields, 3, 0))
    };
  }

  function decodeSocialPayload(payload) {
    const fields = parseFields(payload);
    const common = decodeCommonPayload(first(fields, 1, 2));
    const displayKey = common.displayKey.toLowerCase();
    const kind = displayKey.includes("follow") ? "follow" : displayKey.includes("share") ? "share" : "social";
    return {
      method: "WebcastSocialMessage",
      ...common,
      kind,
      followerCount: integer(first(fields, 6, 0)),
      shareCount: integer(first(fields, 8, 0)),
      action: integer(first(fields, 4, 0)),
      shareType: integer(first(fields, 3, 0))
    };
  }

  function decodeGiftPayload(payload) {
    const fields = parseFields(payload);
    const user = decodeUserPayload(first(fields, 7, 2));
    return {
      method: "WebcastGiftMessage",
      ...decodeCommonPayload(first(fields, 1, 2)),
      ...user,
      giftId: integer(first(fields, 2, 0)),
      repeatCount: integer(first(fields, 5, 0)) || "1",
      repeatEnd: first(fields, 9, 0) === 1n
    };
  }

  function decodeFetchResult(payload) {
    const resultFields = parseFields(payload);
    const captions = [];
    const liveEvents = [];
    const chatMessages = [];
    const giftMessages = [];
    for (const messageBytes of all(resultFields, 1, 2)) {
      const messageFields = parseFields(messageBytes);
      const method = text(first(messageFields, 1, 2));
      const body = first(messageFields, 2, 2);
      if (method === "WebcastCaptionMessage" && body) {
        captions.push({ method, ...decodeCaptionPayload(body) });
      } else if (method === "WebcastChatMessage" && body) {
        chatMessages.push(decodeChatPayload(body));
      } else if (method === "WebcastRoomUserSeqMessage" && body) {
        liveEvents.push(decodeRoomUserPayload(body));
      } else if (method === "WebcastLikeMessage" && body) {
        liveEvents.push(decodeLikePayload(body));
      } else if (method === "WebcastSocialMessage" && body) {
        liveEvents.push(decodeSocialPayload(body));
      } else if (method === "WebcastGiftMessage" && body) {
        giftMessages.push(decodeGiftPayload(body));
      }
    }
    return { captions, liveEvents, chatMessages, giftMessages };
  }

  async function gunzip(bytes) {
    if (typeof DecompressionStream !== "function") throw new Error("gzip is not supported by this browser");
    const stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream("gzip"));
    return new Uint8Array(await new Response(stream).arrayBuffer());
  }

  async function decodeWebSocketPayload(data) {
    let bytes;
    if (data instanceof Blob) bytes = new Uint8Array(await data.arrayBuffer());
    else bytes = toBytes(data);

    const pushFields = parseFields(bytes);
    let payload = first(pushFields, 8, 2);
    const encoding = text(first(pushFields, 6, 2)).toLowerCase();
    if (!payload) {
      payload = bytes;
    } else if (encoding.includes("gzip") || (payload[0] === 0x1f && payload[1] === 0x8b)) {
      payload = await gunzip(payload);
    }
    return decodeFetchResult(payload);
  }

  return {
    toBytes, readVarint, parseFields, decodeCommonPayload, decodeCaptionPayload,
    decodeUserPayload, decodeChatPayload, decodeRoomUserPayload, decodeLikePayload, decodeSocialPayload, decodeGiftPayload,
    decodeFetchResult, decodeWebSocketPayload
  };
});
