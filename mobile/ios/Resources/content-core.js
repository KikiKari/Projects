(function (root, factory) {
  const api = factory();
  if (typeof module === "object" && module.exports) {
    module.exports = api;
  } else {
    root.TLC_CONTENT_CORE = Object.freeze(api);
  }
})(globalThis, function () {
  "use strict";

  const CDN_SUFFIXES = Object.freeze([
    ".tiktokcdn.com",
    ".tiktokcdn-eu.com",
    ".tiktokcdn-us.com",
    ".tiktokcdn-in.com",
    ".ttlivecdn.com"
  ]);

  const QUALITY_LABELS = Object.freeze({
    auto: "Automatisch",
    origin: "Original",
    uhd_60: "1080p60",
    uhd: "1080p",
    hd_60: "720p60",
    hd: "720p",
    sd: "540p",
    ld: "360p"
  });

  const EMPTY_PROFILE_INFO = Object.freeze({
    present: false,
    nickname: "",
    uniqueId: "",
    signature: "",
    followingCount: null,
    followerCount: null,
    likeCount: null,
    live: null,
    verified: false,
    verifiedLabel: "",
    livePro: false,
    liveProLabel: "",
    sponsoredContent: false,
    sponsoredContentLabel: "",
    paidPartnership: false,
    paidPartnershipLabel: "",
    source: null
  });

  const EMPTY_AI_SUMMARY_INFO = Object.freeze({
    featureFlagPresent: false,
    featureEnabled: null,
    text: "",
    source: null,
    overviewCardFound: false,
    overviewCardHovered: false
  });

  const EMOJI_SEQUENCE = /(?:\p{Regional_Indicator}{2}|[#*0-9]\uFE0F?\u20E3|\p{Extended_Pictographic}(?:[\uFE0E\uFE0F])?(?:\u200D\p{Extended_Pictographic}(?:[\uFE0E\uFE0F])?)*)/gu;

  function normalizeEscapedText(value) {
    return String(value || "")
      .replace(/\\u0026/gi, "&")
      .replace(/\\u003d/gi, "=")
      .replace(/\\u002f/gi, "/")
      .replace(/\\\//g, "/")
      .replace(/&amp;/gi, "&");
  }

  function isAllowedCdnHostname(hostname) {
    const host = String(hostname || "").toLowerCase();
    return CDN_SUFFIXES.some((suffix) => host === suffix.slice(1) || host.endsWith(suffix));
  }

  function cleanUrlCandidate(candidate) {
    return normalizeEscapedText(candidate).replace(/[),;\]}]+$/g, "");
  }

  function extractUrlsFromText(text) {
    const normalized = normalizeEscapedText(text);
    const matches = normalized.match(/https?:\/\/[^\s"'<>\\]+/gi) || [];
    return [...new Set(matches.map(cleanUrlCandidate))];
  }

  function classifyMediaUrl(rawUrl) {
    let parsed;
    try {
      parsed = new URL(cleanUrlCandidate(rawUrl));
    } catch (_) {
      return null;
    }
    if (!/^https?:$/.test(parsed.protocol) || !isAllowedCdnHostname(parsed.hostname)) {
      return null;
    }

    const comparable = `${parsed.pathname}${parsed.search}`.toLowerCase();
    const isFlv = parsed.pathname.toLowerCase().includes(".flv");
    const isHls = parsed.pathname.toLowerCase().includes(".m3u8");
    const isAudio = parsed.searchParams.get("only_audio") === "1" || /(?:^|[_-])audio(?:[_-]|\.|$)/.test(comparable);
    if (!isFlv && !isHls && !isAudio) {
      return null;
    }

    let quality = "unbekannt";
    if (isAudio) quality = "Audio";
    else if (/(?:_|-)hd(?:\.|_|-|$)/.test(comparable)) quality = "HD";
    else if (/(?:_|-)ld(?:\.|_|-|$)/.test(comparable)) quality = "LD";
    else if (/(?:_|-)sd\d*(?:\.|_|-|$)/.test(comparable)) quality = "SD";

    const resolutionMatch = comparable.match(/(?:^|[^0-9])(\d{3,4})p(?:[^0-9]|$)/);
    if (resolutionMatch) quality = `${resolutionMatch[1]}p`;

    return {
      url: parsed.href,
      protocol: isHls ? "HLS" : "FLV",
      quality,
      audioOnly: isAudio,
      hostname: parsed.hostname
    };
  }

  function normalizeCaptionInfo(value) {
    if (!value || typeof value !== "object") {
      return { present: false, open: null, supportLang: [], location: null, showType: null, observed: false, source: null };
    }
    const support = value.support_lang || value.supportLang || value.support_language || [];
    return {
      present: value.present !== false,
      open: value.open ?? value.is_open ?? value.enabled ?? null,
      supportLang: Array.isArray(support) ? support.map(String) : [],
      location: value.location ?? null,
      showType: value.show_type ?? value.showType ?? null,
      observed: Boolean(value.observed),
      source: value.source ?? null
    };
  }

  function mergeObservedCaptionInfo(value, captions) {
    const base = normalizeCaptionInfo(value);
    const items = (Array.isArray(captions) ? captions : [captions]).filter(Boolean);
    const languages = items.flatMap((caption) => (caption.contents || []).map((content) => String(content.lang || "").trim())).filter(Boolean);
    const observed = items.some((caption) => (caption.contents || []).some((content) => String(content.text || "").trim()));
    if (!observed) return base;
    const domOnly = items.every((caption) => caption.source === "dom" || caption.method === "DomCaption");
    return {
      ...base,
      present: true,
      open: true,
      supportLang: [...new Set([...base.supportLang, ...languages])],
      location: base.location || (domOnly ? "player-dom" : "WebcastCaptionMessage"),
      observed: true,
      source: domOnly ? "dom" : "websocket"
    };
  }

  function normalizeCaptionText(value) {
    return String(value || "")
      .normalize("NFKC")
      .toLocaleLowerCase()
      .replace(/[^\p{L}\p{N}]+/gu, " ")
      .trim()
      .replace(/\s+/g, " ");
  }

  // Availability is an observation, not proof that a caption stream is still
  // alive. Keep metadata, menu and received text on independent clocks.
  const CAPTION_ACTIVITY_TTL_MS = 15_000;
  function captionSource(caption) {
    if (caption?.method === "WebcastCaptionMessage") return "websocket";
    if (caption?.source === "playerText") return "playerText";
    if (caption?.method === "DomCaption" || caption?.source === "dom") return "dom";
    return null;
  }

  function captionSourceSnapshot(value, now = Date.now()) {
    const result = { metadata: { ...normalizeCaptionInfo(null), ...value?.metadata }, menu: { ...value?.menu } };
    for (const key of ["dom", "websocket", "playerText"]) {
      const previous = value?.[key] || {};
      const age = now - Date.parse(previous.lastObservedAtUtc);
      result[key] = { ...previous, active: Number.isFinite(age) && age >= 0 && age <= CAPTION_ACTIVITY_TTL_MS };
    }
    return result;
  }

  function observeCaptionSource(value, caption, now = Date.now()) {
    const result = captionSourceSnapshot(value, now);
    const key = captionSource(caption);
    if (!key || !captionText(caption)) return result;
    result[key] = { ...result[key], active: true, lastObservedAtUtc: new Date(now).toISOString(),
      supportLang: [...new Set((caption.contents || []).map((item) => item.lang).filter(Boolean))] };
    return result;
  }

  function summarizeCaptionSources(value, now = Date.now()) {
    const sources = captionSourceSnapshot(value, now);
    const active = ["websocket", "dom", "playerText"].filter((key) => sources[key].active);
    const metadata = sources.metadata;
    return { ...metadata, present: Boolean(metadata.present || active.length), observed: active.length > 0,
      // A WebSocket caption does not prove that TikTok's visible menu is on.
      open: sources.dom.active || sources.playerText.active ? true : metadata.open,
      source: active.length > 1 ? "multiple" : active[0] || (metadata.present ? "metadata" : null),
      activeSources: active, activityTtlMs: CAPTION_ACTIVITY_TTL_MS,
      supportLang: [...new Set([...(metadata.present ? metadata.supportLang || [] : []),
        ...active.flatMap((key) => sources[key].supportLang || [])])],
      lastObservedAtUtc: active.map((key) => sources[key].lastObservedAtUtc).sort().at(-1) || null };
  }

  function captionText(caption) {
    return normalizeCaptionText((caption?.contents || []).map((content) => content.text || "").join(" "));
  }

  function captionsOverlap(left, right) {
    const a = typeof left === "string" ? normalizeCaptionText(left) : captionText(left);
    const b = typeof right === "string" ? normalizeCaptionText(right) : captionText(right);
    if (!a || !b) return false;
    if (a.includes(b) || b.includes(a)) return true;
    const aWords = a.split(" ");
    const bWords = b.split(" ");
    const max = Math.min(8, aWords.length, bWords.length);
    for (let size = max; size >= 3; size -= 1) {
      if (aWords.slice(-size).join(" ") === bWords.slice(0, size).join(" ")) return true;
      if (bWords.slice(-size).join(" ") === aWords.slice(0, size).join(" ")) return true;
    }
    return false;
  }

  // Self-contained so the exact tested kernel can run on the audio rendering thread.
  function createPeakLimiter(sampleRate) {
    const delay = Math.max(1, Math.round(sampleRate * 0.005));
    const size = delay + 1;
    const peakValues = new Float32Array(size + 1);
    const peakTimes = new Float64Array(size + 1);
    let head = 0, tail = 0, clock = 0, gain = 1;
    let channels = [];
    const release = Math.exp(-1 / (sampleRate * 0.06));
    const db = value => value > 0 ? Math.max(-100, 20 * Math.log10(value)) : -100;
    return {
      delaySamples: delay,
      process(input, output, enabled, strength) {
        const frames = output[0]?.length || 0;
        const percent = Math.max(0, Math.min(100, Number(strength) || 0));
        const ceiling = Math.pow(10, (-4 - percent * 0.26) / 20);
        while (channels.length < output.length) channels.push(new Float32Array(size));
        let inputPeak = 0, outputPeak = 0, minGain = 1;
        for (let i = 0; i < frames; i++, clock++) {
          let peak = 0;
          for (let c = 0; c < output.length; c++) {
            const value = input[c]?.[i] ?? 0;
            const sample = Number.isFinite(value) ? value : 0;
            channels[c][clock % size] = sample;
            peak = Math.max(peak, Math.abs(sample));
          }
          inputPeak = Math.max(inputPeak, peak);
          while (head !== tail && peakTimes[head] < clock - delay) head = (head + 1) % peakValues.length;
          while (head !== tail) {
            const previous = (tail + peakValues.length - 1) % peakValues.length;
            if (peakValues[previous] > peak) break;
            tail = previous;
          }
          peakValues[tail] = peak;
          peakTimes[tail] = clock;
          tail = (tail + 1) % peakValues.length;
          const target = enabled ? Math.min(1, ceiling / Math.max(peakValues[head], 1e-12)) : 1;
          gain = enabled ? Math.min(target, 1 - (1 - gain) * release) : 1;
          minGain = Math.min(minGain, gain);
          for (let c = 0; c < output.length; c++) {
            const sample = clock >= delay ? channels[c][(clock - delay) % size] : 0;
            const value = sample * gain;
            output[c][i] = value;
            outputPeak = Math.max(outputPeak, Math.abs(value));
          }
        }
        return { inputPeakDbfs: db(inputPeak), outputPeakDbfs: db(outputPeak),
          reductionDb: -db(minGain), lookaheadMs: delay * 1000 / sampleRate };
      }
    };
  }

  async function createPeakLimiterNode(context) {
    if (!context.audioWorklet || typeof AudioWorkletNode !== "function") {
      throw new Error("Pegelschutz benötigt AudioWorklet-Unterstützung.");
    }
    const source = `const createPeakLimiter = ${createPeakLimiter.toString()};
      class TLCPeakLimiter extends AudioWorkletProcessor {
        static get parameterDescriptors() {
          return [
            { name: 'enabled', defaultValue: 0, minValue: 0, maxValue: 1, automationRate: 'k-rate' },
            { name: 'strength', defaultValue: 30, minValue: 0, maxValue: 100, automationRate: 'k-rate' }
          ];
        }
        constructor() {
          super(); this.kernel = createPeakLimiter(sampleRate);
          this.enabled = false; this.strength = 30; this.frames = 0;
          this.inputPeakDbfs = -100; this.outputPeakDbfs = -100; this.reductionDb = 0;
        }
        process(inputs, outputs, parameters) {
          const report = this.kernel.process(inputs[0] || [], outputs[0], parameters.enabled[0] >= 0.5, parameters.strength[0]);
          this.inputPeakDbfs = Math.max(this.inputPeakDbfs, report.inputPeakDbfs);
          this.outputPeakDbfs = Math.max(this.outputPeakDbfs, report.outputPeakDbfs);
          this.reductionDb = Math.max(this.reductionDb, report.reductionDb);
          this.frames += outputs[0][0]?.length || 0;
          if (this.frames >= sampleRate / 10) {
            this.port.postMessage({ ...report, inputPeakDbfs: this.inputPeakDbfs,
              outputPeakDbfs: this.outputPeakDbfs, reductionDb: this.reductionDb });
            this.frames = 0; this.inputPeakDbfs = -100; this.outputPeakDbfs = -100; this.reductionDb = 0;
          }
          return true;
        }
      }
      registerProcessor('tlc-peak-limiter', TLCPeakLimiter);`;
    const url = URL.createObjectURL(new Blob([source], { type: "text/javascript" }));
    try { await context.audioWorklet.addModule(url); }
    finally { URL.revokeObjectURL(url); }
    const node = new AudioWorkletNode(context, "tlc-peak-limiter");
    node.setProtection = ({ enabled, strength }) => {
      node.parameters.get("enabled").setValueAtTime(enabled === true ? 1 : 0, context.currentTime);
      node.parameters.get("strength").setValueAtTime(Math.max(0, Math.min(100, Number(strength) || 0)), context.currentTime);
    };
    node.measurements = null;
    node.port.onmessage = event => { node.measurements = event.data; };
    return node;
  }

  function limiterStrengthToDbfs(value) {
    const strength = Math.max(0, Math.min(100, Number(value) || 0));
    return Math.round((-4 - (strength * 26 / 100)) * 100) / 100;
  }

  function limiterDbfsToStrength(value) {
    const threshold = Math.max(-30, Math.min(-4, Number(value) || -4));
    return Math.round(((-4 - threshold) / 26) * 100);
  }

  function limiterMakeupCompensation(thresholdDbfs, ratio = 20) {
    const threshold = Math.max(-100, Math.min(0, Number(thresholdDbfs) || 0));
    const safeRatio = Math.max(1, Number(ratio) || 1);
    const fullScaleOutputDb = threshold + ((0 - threshold) / safeRatio);
    const strength = limiterDbfsToStrength(threshold);
    const compensation = strength >= 75 ? 0.75 : strength >= 50 ? 0.55 : 0.45;
    return Math.pow(10, (fullScaleOutputDb * compensation) / 20);
  }

  function parseJsonValue(value) {
    if (value && typeof value === "object") return value;
    if (typeof value !== "string") return null;
    try { return JSON.parse(value); } catch (_) { return null; }
  }

  function shouldFilterExternalSpeechTrigger(text, enabled) {
    return enabled === true && String(text || "").trimStart().startsWith(".");
  }

  function sanitizeChatText(value) {
    return String(value || "")
      .normalize("NFKC")
      .replace(EMOJI_SEQUENCE, " ")
      .replace(/[\u{1F3FB}-\u{1F3FF}\uFE0E\uFE0F\u200D\u20E3\uFFFC]/gu, " ")
      .replace(/\s+/g, " ")
      .trim();
  }

  function normalizedIdentity(value) {
    return sanitizeChatText(value).toLocaleLowerCase().replace(/^@/, "").replace(/\s+/g, "_");
  }

  function wordCount(value) {
    return (sanitizeChatText(value).match(/[\p{L}\p{N}]+(?:['’][\p{L}\p{N}]+)*/gu) || []).length;
  }

  function standaloneTokenPattern(token) {
    const escaped = String(token || "").replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    return new RegExp(`(^|[^\\p{L}\\p{N}])${escaped}(?=$|[^\\p{L}\\p{N}])`, "giu");
  }

  function stripTeamTag(value, teamTag) {
    if (!teamTag) return sanitizeChatText(value);
    return sanitizeChatText(value)
      .replace(standaloneTokenPattern(teamTag), "$1")
      .replace(/\s+([:,.!?])/g, "$1")
      .replace(/\s+/g, " ")
      .trim();
  }

  function teamSuffixCandidate(author) {
    const tokens = sanitizeChatText(author).match(/[\p{L}\p{N}]+/gu) || [];
    if (tokens.length < 2) return "";
    const candidate = tokens.at(-1) || "";
    return /^[\p{L}\p{N}]{3}$/u.test(candidate) ? candidate.toLocaleLowerCase() : "";
  }

  function contentHasToken(content, token) {
    return Boolean(token && standaloneTokenPattern(token).test(sanitizeChatText(content)));
  }

  function accumulateTeamEvidence(previousEvidence, author, content, priorContents = []) {
    const evidence = structuredClone(previousEvidence || {});
    const contents = [...priorContents, content];
    const candidate = teamSuffixCandidate(author);
    if (candidate) {
      const entry = evidence[candidate] || { authors: {}, contentHits: 0 };
      entry.authors[normalizedIdentity(author)] = true;
      evidence[candidate] = entry;
    }
    for (const [token, entry] of Object.entries(evidence)) {
      entry.contentHits = contents.filter((value) => contentHasToken(value, token)).length;
      const authorCount = Object.keys(entry.authors || {}).length;
      if (authorCount >= 2 || (authorCount >= 1 && entry.contentHits >= 1)) return { evidence, teamTag: token };
    }
    return { evidence, teamTag: "" };
  }

  function streamIdentityChanged(current = {}, incoming = {}) {
    const currentHandle = String(current.handle || "").toLocaleLowerCase();
    const incomingHandle = String(incoming.handle || "").toLocaleLowerCase();
    const currentRoom = String(current.roomId || "");
    const incomingRoom = String(incoming.roomId || "");
    return Boolean(
      (currentHandle && incomingHandle && currentHandle !== incomingHandle) ||
      (currentRoom && incomingRoom && currentRoom !== incomingRoom)
    );
  }

  function sameParticipant(left = {}, right = {}) {
    if (left.userId && right.userId && String(left.userId) === String(right.userId)) return true;
    if (left.displayId && right.displayId && normalizedIdentity(left.displayId) === normalizedIdentity(right.displayId)) return true;
    const leftName = normalizedIdentity(left.name || left.author || left.nickname);
    const rightName = normalizedIdentity(right.name || right.author || right.nickname);
    return Boolean(leftName && rightName && leftName !== "chat" && leftName === rightName);
  }

  function sortParticipants(values) {
    return [...(values || [])].sort((a, b) =>
      (Number(b.messageCount) - Number(a.messageCount)) ||
      (Number(b.wordCount) - Number(a.wordCount)) ||
      String(a.name || "").localeCompare(String(b.name || ""), "de")
    );
  }

  function mergeParticipantRecord(existing = {}, raw = {}, author = "", patch = {}) {
    return {
      userId: null,
      displayId: "",
      name: "Chat",
      messageCount: 0,
      wordCount: 0,
      giftEventCount: 0,
      giftItemCount: 0,
      lastSeenAtUtc: raw.receivedAtUtc || new Date().toISOString(),
      ...existing,
      userId: raw.userId || existing.userId || null,
      displayId: raw.displayId || existing.displayId || "",
      name: author || existing.name || "Chat",
      lastSeenAtUtc: raw.receivedAtUtc || existing.lastSeenAtUtc || new Date().toISOString(),
      ...patch
    };
  }

  function collapseLaughter(value) {
    return String(value || "")
      .replace(/\b(?=[ha]{6,}\b)(?=[ha]*h)(?=[ha]*a)[ha]+\b/giu, "haha")
      .replace(/\s+/g, " ")
      .trim();
  }

  function spokenNickname(value) {
    const name = sanitizeChatText(String(value || "").replace(/[№#]\s*\d+/gu, " ")).replace(/^@\s*/, "").replace(/\s*:\s*$/, "");
    const systemName = name.match(/^user[^\p{L}\p{N}]*(\d{1,})/iu);
    if (systemName) return `user${systemName[1].slice(0, 3)}`;
    return name
      .replace(/\d+/gu, "")
      .replace(/[^\p{L}\s]+/gu, " ")
      .replace(/\s+/g, " ")
      .trim();
  }

  function shortenNickname(value) {
    const rawName = sanitizeChatText(value).replace(/^@\s*/, "").replace(/\s*:\s*$/, "");
    const name = spokenNickname(rawName);
    if (!name || /^user\d{1,3}$/iu.test(name)) return name;

    const rawParts = rawName.split(/[\s._-]+/).filter(Boolean);
    const parts = rawParts.map(spokenNickname).filter(Boolean);
    if (parts.length < 2) return name;

    const first = parts[0];
    if (/^(?:team|official|the|real|mrs|mr|miss|dr)$/iu.test(first)) return name;
    if (/^(?:die|der|das)$/iu.test(first) && parts[1]) return parts[1];
    if (/^[\p{Lu}]{2,5}$/u.test(first) && parts[1]) return parts[1];
    if (!/^[\p{L}]{2,24}$/u.test(first)) return name;

    const hadExplicitSeparator = /[._-]/u.test(rawName);
    const hadNumberSuffix = /\d/u.test(rawName);
    const looksLikeNameSuffix = parts.slice(1).every((part) => /^[\p{Lu}][\p{L}]{2,}$/u.test(part));
    return hadExplicitSeparator || hadNumberSuffix || looksLikeNameSuffix ? first : name;
  }

  function resolveSpeechLanguage(mode, contentLanguage) {
    if (mode === "de-DE" || mode === "en-US") return mode;
    const detected = String(contentLanguage || "").toLocaleLowerCase();
    if (detected.startsWith("de")) return "de-DE";
    if (detected.startsWith("en")) return "en-US";
    return "";
  }

  function composeSpeechText(item, options = {}) {
    if (item?.systemSpeechText) return sanitizeChatText(item.systemSpeechText);
    const teamTag = options.teamTag || "";
    const speakNames = options.speakNames !== false;
    const shortenNames = Boolean(options.shortenNames && speakNames);
    const content = collapseLaughter(stripTeamTag(item?.content, teamTag));
    const isQuestion = content.includes("?");
    const mention = content.match(/@\s*([\p{L}\p{N}_.-]+)/u);
    const rawRecipient = mention?.[1] || "";
    const recipient = rawRecipient ? (shortenNames ? shortenNickname(rawRecipient) : spokenNickname(rawRecipient)) : "";
    const body = content
      .replace(/\?/g, " ")
      .replace(mention?.[0] || /$a/, recipient)
      .replace(/\s+([:,.!])/g, "$1")
      .replace(/\s+/g, " ")
      .trim();
    if (!speakNames) return body;
    const rawAuthor = stripTeamTag(item?.author || "Chat", teamTag).replace(/\s*:\s*$/, "");
    const author = shortenNames ? shortenNickname(rawAuthor) : spokenNickname(rawAuthor);
    if (recipient) {
      const remainder = body.replace(new RegExp(`^${recipient.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\b\\s*`, "iu"), "");
      return `${author} ${isQuestion ? "fragt" : "sagt zu"} ${recipient}${remainder ? ` ${remainder}` : ""}`.trim();
    }
    return `${author} ${isQuestion ? "fragt" : "sagt"}${body ? ` ${body}` : ""}`.trim();
  }

  function liveHandleFromUrl(value) {
    try {
      const path = decodeURIComponent(new URL(String(value || "")).pathname);
      return (path.match(/^\/@([^/]+)\/live\/?$/i)?.[1] || path.match(/^\/embed\/live\/@?([^/?#]+)\/?$/i)?.[1] || "").toLocaleLowerCase();
    }
    catch (_) { return ""; }
  }

  function parseCompactCount(value) {
    const raw = String(value ?? "").trim().replace(/\s+/g, "");
    if (!raw) return null;
    const match = raw.match(/^([0-9]+(?:[.,][0-9]+)?)([KMB])?$/i);
    if (!match) return null;
    const suffix = String(match[2] || "").toLocaleUpperCase();
    if (!suffix) {
      const digits = raw.replace(/[.,]/g, "");
      const parsed = Number(digits);
      return Number.isSafeInteger(parsed) ? parsed : null;
    }
    const base = Number(match[1].replace(",", "."));
    const multiplier = suffix === "K" ? 1_000 : suffix === "M" ? 1_000_000 : 1_000_000_000;
    const parsed = Math.round(base * multiplier);
    return Number.isSafeInteger(parsed) ? parsed : null;
  }

  function dedupeRecommendations(items = []) {
    const byHandle = new Map();
    for (const raw of items) {
      const handle = String(raw?.handle || "").replace(/^@/, "").trim().toLocaleLowerCase();
      if (!handle) continue;
      const position = Math.max(1, Math.round(Number(raw.position) || byHandle.size + 1));
      const item = {
        handle,
        displayName: String(raw.displayName || "").trim(),
        title: String(raw.title || "").trim(),
        viewerCount: raw.viewerCount != null && Number.isSafeInteger(Number(raw.viewerCount)) ? Number(raw.viewerCount) : null,
        viewerLabel: String(raw.viewerLabel || "").trim(),
        url: String(raw.url || "").trim(),
        position
      };
      const existing = byHandle.get(handle);
      if (!existing) {
        byHandle.set(handle, item);
        continue;
      }
      byHandle.set(handle, {
        ...existing,
        displayName: existing.displayName || item.displayName,
        title: existing.title || item.title,
        viewerCount: item.viewerCount ?? existing.viewerCount,
        viewerLabel: item.viewerLabel || existing.viewerLabel,
        url: existing.url || item.url,
        position: Math.min(existing.position, item.position)
      });
    }
    return [...byHandle.values()].sort((left, right) => left.position - right.position);
  }

  function sortRecommendations(items = [], mode = "tiktok") {
    const result = dedupeRecommendations(items);
    if (mode !== "viewers") return result;
    return result.sort((left, right) => {
      const leftCount = Number.isSafeInteger(left.viewerCount) ? left.viewerCount : -1;
      const rightCount = Number.isSafeInteger(right.viewerCount) ? right.viewerCount : -1;
      return rightCount - leftCount || left.position - right.position;
    });
  }

  function gameModeSpeechKey(value) {
    return sanitizeChatText(value)
      .toLocaleLowerCase()
      .replace(/^@+/, "")
      .replace(/[^\p{L}\p{N}]+/gu, "")
      .trim();
  }

  function shouldFilterGameModeSpeech(item, participants = {}, recentItems = []) {
    const contentKey = gameModeSpeechKey(item?.content || "");
    if (!contentKey || contentKey.length < 2 || item?.systemSpeechText) return false;
    const aliases = new Set();
    for (const participant of Object.values(participants || {})) {
      for (const value of [participant?.name, participant?.displayId]) {
        const key = gameModeSpeechKey(value || "");
        if (key) aliases.add(key);
      }
    }
    if (!aliases.has(contentKey)) return false;
    const now = Date.parse(item?.receivedAtUtc || "") || Date.now();
    const repeats = (recentItems || []).filter((entry) => {
      const entryAt = Date.parse(entry?.receivedAtUtc || "") || 0;
      return Math.abs(now - entryAt) <= 45000 && gameModeSpeechKey(entry?.content || "") === contentKey;
    }).length;
    return repeats >= 2;
  }

  function gameEventSpeech(rawMessage = {}) {
    const raw = sanitizeChatText(rawMessage.rawText || rawMessage.content || "");
    const explicitName = sanitizeChatText(rawMessage.giftName || rawMessage.gift_name || rawMessage.gift || "");
    const nameFromText =
      raw.match(/hat\s+\d+\s+(.+?)\s+gesendet/i)?.[1] ||
      raw.match(/hat\s+(.+?)\s+gesendet(?:\s*x\s*\d+)?/i)?.[1] ||
      raw.match(/sent\s+\d+\s+(.+?)(?:\s*x\s*\d+)?$/i)?.[1] ||
      "";
    const giftName = sanitizeChatText(explicitName || nameFromText);
    if (!giftName) return "";
    if (/(?:booster|boosterhandschuh)/i.test(giftName)) return "Booster wurde gesetzt";
    if (/(?:game|controller|handschuh|schild|schutz|boost)/i.test(giftName)) return `${giftName} wurde gesetzt`;
    return "";
  }

  function numericString(value) {
    if (value == null || value === "") return null;
    if (typeof value === "object") {
      value = value.value ?? value.count ?? value.number ?? null;
    }
    return value == null || value === "" ? null : String(value);
  }

  function normalizeProfileInfo(value, source = "metadata") {
    if (!value || typeof value !== "object") return { ...EMPTY_PROFILE_INFO };
    const stats = value.stats || value.userStats || value.statsV2 || value.authorStats || value.statistics || value.user_statistics || {};
    const uniqueId = value.uniqueId || value.unique_id || value.displayId || value.display_id || value.secUidInfo?.uniqueId || "";
    const nickname = value.nickname || value.nickName || value.displayName || value.display_name || value.name || "";
    const signature = value.signature || value.bioDescription || value.bio || value.description || "";
    const followingCount = numericString(stats.followingCount ?? stats.following_count ?? stats.followCount ?? stats.follow_count ?? value.followingCount ?? value.following_count);
    const followerCount = numericString(stats.followerCount ?? stats.follower_count ?? stats.fansCount ?? stats.fans_count ?? value.followerCount ?? value.follower_count ?? value.fansCount);
    const likeCount = numericString(stats.heartCount ?? stats.heart_count ?? stats.heart ?? stats.likeCount ?? stats.like_count ?? stats.likes ?? stats.totalFavorited ?? value.likeCount ?? value.heartCount);
    const roomId = value.roomId ?? value.room_id ?? value.liveRoomId ?? value.live_room_id ?? value.ownRoom?.roomId;
    const liveStatus = value.liveStatus ?? value.live_status ?? value.isLive ?? value.is_live;
    const live = liveStatus == null && roomId == null ? null : Boolean(liveStatus === true || Number(liveStatus) > 0 || String(roomId || "0") !== "0");
    const verifiedValue = value.verified ?? value.isVerified ?? value.is_verified ?? value.author?.verified ?? value.user?.verified ?? value.user?.isVerified;
    const verified = verifiedValue === true || verifiedValue === 1 || /^(?:true|1|yes|verified)$/i.test(String(verifiedValue || ""));
    const present = Boolean(uniqueId || nickname) && Boolean(followingCount != null || followerCount != null || likeCount != null || signature);
    return {
      present,
      nickname: String(nickname || ""),
      uniqueId: String(uniqueId || "").replace(/^@/, ""),
      signature: String(signature || ""),
      followingCount,
      followerCount,
      likeCount,
      live,
      verified,
      verifiedLabel: verified ? "Zertifiziert" : "",
      livePro: false,
      liveProLabel: "",
      sponsoredContent: false,
      sponsoredContentLabel: "",
      paidPartnership: false,
      paidPartnershipLabel: "",
      source: present ? source : null
    };
  }

  function profileScore(info, preferredUniqueId = "") {
    if (!info?.present) return 0;
    const preferred = preferredUniqueId && String(info.uniqueId).toLocaleLowerCase() === String(preferredUniqueId).toLocaleLowerCase() ? 100 : 0;
    return preferred + (info.uniqueId ? 4 : 0) + (info.nickname ? 2 : 0) +
      (info.followerCount != null ? 4 : 0) + (info.followingCount != null ? 2 : 0) +
      (info.likeCount != null ? 2 : 0) + (info.signature ? 1 : 0) + (info.verified ? 1 : 0) +
      (info.livePro ? 1 : 0) + (info.sponsoredContent ? 1 : 0) + (info.paidPartnership ? 1 : 0);
  }

  function summaryFlagValue(value) {
    if (typeof value === "boolean") return value;
    if (typeof value === "number") return value !== 0;
    if (typeof value === "string") return !/^(?:0|false|off|disabled|control)$/i.test(value.trim());
    if (value && typeof value === "object") {
      const variant = value.vid ?? value.value ?? value.enabled ?? value.status;
      return variant == null ? true : summaryFlagValue(variant);
    }
    return null;
  }

  function extractStreamVariants(value) {
    if (!value || typeof value !== "object") return [];
    const streamData = parseJsonValue(value.stream_data || value.streamData);
    if (!streamData?.data || typeof streamData.data !== "object") return [];
    const names = new Map();
    for (const quality of value.options?.qualities || []) {
      if (quality?.sdk_key) names.set(String(quality.sdk_key), String(quality.name || ""));
    }
    const result = [];
    for (const [sdkKey, variant] of Object.entries(streamData.data)) {
      for (const sourceRole of ["main", "backup"]) {
        const source = variant?.[sourceRole];
        if (!source || typeof source !== "object") continue;
        const params = parseJsonValue(source.sdk_params || source.sdkParams) || {};
        for (const [protocolKey, url] of [["FLV", source.flv], ["HLS", source.hls]]) {
          const classified = classifyMediaUrl(url);
          if (!classified) continue;
          const width = Number(params.width || params.Width || 0) || null;
          const height = Number(params.height || params.Height || 0) || null;
          const fps = Number(params.fps || params.FPS || params.vfps || 0) || null;
          result.push({
            ...classified,
            protocol: protocolKey,
            quality: names.get(sdkKey) || QUALITY_LABELS[sdkKey] || classified.quality,
            sdkKey,
            bitrate: Number(params.vbitrate || params.video_bitrate || 0) || null,
            codec: String(params.VCodec || params.vcodec || params.codec || "") || null,
            width,
            height,
            fps,
            sourceRole
          });
        }
      }
    }
    return result;
  }

  function inspectMetadata(rootValue, options = {}) {
    const maxNodes = Number(options.maxNodes || 50000);
    const preferredProfileId = String(options.profileUniqueId || "").replace(/^@/, "");
    const media = new Map();
    let captionInfo = null;
    let profileInfo = { ...EMPTY_PROFILE_INFO };
    let aiSummaryInfo = { ...EMPTY_AI_SUMMARY_INFO };
    let nodes = 0;
    const seen = new WeakSet();

    function addMedia(item, preferDetails = false) {
      if (!item?.url) return;
      const previous = media.get(item.url);
      if (!previous) media.set(item.url, item);
      else media.set(item.url, preferDetails ? { ...previous, ...item } : { ...item, ...previous });
    }

    function addText(text) {
      for (const url of extractUrlsFromText(text)) {
        const item = classifyMediaUrl(url);
        if (item) addMedia(item, false);
      }
    }

    function visit(value, keyHint = "") {
      if (++nodes > maxNodes || value == null) return;
      if (typeof value === "string") {
        addText(value);
        if (value.length < 200000 && /^[\s]*[{[]/.test(value) && /(caption_info|\.flv|\.m3u8)/i.test(value)) {
          try { visit(JSON.parse(value), keyHint); } catch (_) { /* JSON-in-JSON is optional. */ }
        }
        return;
      }
      if (typeof value !== "object" || seen.has(value)) return;
      seen.add(value);

      for (const item of extractStreamVariants(value)) addMedia(item, true);

      const profileCandidate = normalizeProfileInfo(value);
      if (profileScore(profileCandidate, preferredProfileId) > profileScore(profileInfo, preferredProfileId)) profileInfo = profileCandidate;

      if (/^caption_?info$/i.test(keyHint)) {
        captionInfo = normalizeCaptionInfo(value);
      }

      if (Array.isArray(value)) {
        for (const item of value) visit(item, keyHint);
      } else {
        for (const [key, item] of Object.entries(value)) {
          if (/^caption_?info$/i.test(key)) captionInfo = normalizeCaptionInfo(item);
          if (/^(?:live_?ai_?summary_?ui|show_?preview_?asr_?summary|show_?preview_?traffic_?tag_?summary)$/i.test(key)) {
            aiSummaryInfo.featureFlagPresent = true;
            const enabled = summaryFlagValue(item);
            if (enabled != null) aiSummaryInfo.featureEnabled = aiSummaryInfo.featureEnabled === true || enabled;
          }
          if (/^(?:ai|asr|live|preview)_?summary(?:_?text)?$/i.test(key) && typeof item === "string") {
            const candidate = item.trim();
            if (candidate.length >= 4 && !/^(?:summary|zusammenfassung)$/i.test(candidate)) {
              aiSummaryInfo.text = candidate.slice(0, 4000);
              aiSummaryInfo.source = "metadata";
            }
          }
          visit(item, key);
        }
      }
    }

    visit(rootValue);
    return {
      captionInfo: captionInfo || normalizeCaptionInfo(null),
      profileInfo,
      aiSummaryInfo,
      media: [...media.values()],
      visitedNodes: nodes
    };
  }

  // Bounded startup recovery, independent of the hook/quick-recovery timer.
  // Persist this small state across page reloads and service-worker restarts.
  function newEmbedSession(id, handle, now) {
    return { id, handle, phase: "loading", attempt: 1, startedAtMs: now,
      attemptStartedAtMs: now, nextAttemptAtMs: null, documentId: null,
      excludedDocumentId: null, reason: null, completedAtMs: null };
  }

  function classifyEmbedObservation({ text = "", playing = false, paused = false, readyState = 0, ended = false, mediaError = false } = {}) {
    if (playing && !ended && readyState >= 2) return "playing";
    const message = String(text).toLowerCase();
    if (/log in to|sign in to|melde dich an|anmelden, um/.test(message)) return "login-required";
    if (ended || /live has ended|live ist beendet|livestream beendet/.test(message)) return "ended";
    if (/server error|serverfehler|something is wrong on our end/.test(message)) return "server-error";
    if (/live is unavailable|cannot be played in the embed player|live ist nicht verfügbar/.test(message)) return "unavailable";
    if (mediaError) return "media-error";
    if (paused && readyState >= 2) return "awaiting-gesture";
    return "waiting";
  }

  function advanceEmbedSession(session, observation, now) {
    if (!session || ["playing", "failed", "cancelled"].includes(session.phase)) return { session, action: "none" };
    const states = ["playing", "waiting", "server-error", "unavailable", "media-error", "awaiting-gesture", "login-required", "ended"];
    if (!states.includes(observation?.status) || !observation.documentId ||
        !Number.isFinite(observation.documentStartedAtMs) || observation.documentStartedAtMs < session.attemptStartedAtMs ||
        observation.documentId === session.excludedDocumentId ||
        (session.documentId && observation.documentId !== session.documentId)) return { session, action: "none" };
    const next = { ...session, documentId: observation.documentId };
    if (observation.status === "playing") {
      return { session: { ...next, phase: "playing", nextAttemptAtMs: null, reason: null, completedAtMs: now }, action: "none" };
    }
    if (["login-required", "ended"].includes(observation.status)) {
      return { session: { ...next, phase: "failed", reason: observation.status, nextAttemptAtMs: null, completedAtMs: now }, action: "none" };
    }
    if (observation.status === "awaiting-gesture") {
      return { session: { ...next, phase: "awaiting-gesture", reason: "awaiting-gesture", nextAttemptAtMs: null }, action: "none" };
    }
    const failure = ["server-error", "unavailable", "media-error"].includes(observation.status)
      ? observation.status : now - session.attemptStartedAtMs >= 15000 ? "timeout" : null;
    if (!failure) return { session: { ...next, phase: "loading", reason: null, nextAttemptAtMs: null }, action: "none" };
    if (session.attempt >= 3 || now - session.startedAtMs >= 90000) {
      return { session: { ...next, phase: "failed", reason: failure, nextAttemptAtMs: null, completedAtMs: now }, action: "none" };
    }
    const due = session.nextAttemptAtMs ?? now + 2000 * session.attempt;
    if (now < due) return { session: { ...next, phase: "retry-wait", reason: failure, nextAttemptAtMs: due }, action: "none" };
    return { session: { ...next, phase: "loading", attempt: session.attempt + 1,
      attemptStartedAtMs: now, nextAttemptAtMs: null, excludedDocumentId: observation.documentId,
      documentId: null, reason: failure }, action: "reload" };
  }

  return {
    mediaRecoveryReason(video, { userPaused = false, graceElapsed = true } = {}) {
      if (!video || userPaused) return "";
      if (video.error) return "video-error";
      if (video.ended) return "video-ended";
      if (!graceElapsed) return "";
      if (video.paused) return "video-paused";
      if (video.readyState < 2) return "video-not-ready";
      return "";
    },
    observeRecoveryMedia(attempt, observation, now) {
      if (!attempt || attempt.completedAtMs != null || attempt.endedAtMs != null || attempt.outcome === "reload-failed" ||
          observation?.playing !== true || !observation.documentId || observation.documentId === attempt.documentId ||
          !Number.isFinite(observation.documentStartedAtMs) || observation.documentStartedAtMs < attempt.startedAtMs ||
          observation.documentStartedAtMs > now) return attempt;
      return { ...attempt, completedAtMs: now, playbackDocumentId: observation.documentId,
        outcome: "video-progress-confirmed", reloadToVideoMs: Math.max(0, now - attempt.startedAtMs),
        interruptionToVideoMs: Number.isFinite(attempt.detectedAtMs) ? Math.max(0, now - attempt.detectedAtMs) : null };
    },
    newEmbedSession,
    classifyEmbedObservation,
    advanceEmbedSession,
    CDN_SUFFIXES,
    normalizeEscapedText,
    isAllowedCdnHostname,
    extractUrlsFromText,
    classifyMediaUrl,
    QUALITY_LABELS,
    extractStreamVariants,
    normalizeCaptionInfo,
    mergeObservedCaptionInfo,
    captionSource,
    captionSourceSnapshot,
    observeCaptionSource,
    summarizeCaptionSources,
    normalizeCaptionText,
    captionText,
    captionsOverlap,
    limiterStrengthToDbfs,
    createPeakLimiter,
    createPeakLimiterNode,
    shouldFilterExternalSpeechTrigger,
    limiterDbfsToStrength,
    limiterMakeupCompensation,
    sanitizeChatText,
    normalizedIdentity,
    wordCount,
    stripTeamTag,
    teamSuffixCandidate,
    contentHasToken,
    accumulateTeamEvidence,
    streamIdentityChanged,
    liveHandleFromUrl,
    parseCompactCount,
    dedupeRecommendations,
    sortRecommendations,
    sameParticipant,
    sortParticipants,
    mergeParticipantRecord,
    collapseLaughter,
    spokenNickname,
    shortenNickname,
    resolveSpeechLanguage,
    composeSpeechText,
    shouldFilterGameModeSpeech,
    gameEventSpeech,
    normalizeProfileInfo,
    EMPTY_PROFILE_INFO,
    EMPTY_AI_SUMMARY_INFO,
    inspectMetadata
  };
});
