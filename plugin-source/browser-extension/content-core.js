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
      return { present: false, open: null, supportLang: [], location: null, showType: null };
    }
    const support = value.support_lang || value.supportLang || value.support_language || [];
    return {
      present: true,
      open: value.open ?? value.is_open ?? value.enabled ?? null,
      supportLang: Array.isArray(support) ? support.map(String) : [],
      location: value.location ?? null,
      showType: value.show_type ?? value.showType ?? null
    };
  }

  function parseJsonValue(value) {
    if (value && typeof value === "object") return value;
    if (typeof value !== "string") return null;
    try { return JSON.parse(value); } catch (_) { return null; }
  }

  function sanitizeChatText(value) {
    return String(value || "")
      .normalize("NFKC")
      .replace(EMOJI_SEQUENCE, " ")
      .replace(/[\u{1F3FB}-\u{1F3FF}\uFE0E\uFE0F\u200D\u20E3\uFFFC]/gu, " ")
      .replace(/\s+/g, " ")
      .trim();
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
      source: present ? source : null
    };
  }

  function profileScore(info, preferredUniqueId = "") {
    if (!info?.present) return 0;
    const preferred = preferredUniqueId && String(info.uniqueId).toLocaleLowerCase() === String(preferredUniqueId).toLocaleLowerCase() ? 100 : 0;
    return preferred + (info.uniqueId ? 4 : 0) + (info.nickname ? 2 : 0) +
      (info.followerCount != null ? 4 : 0) + (info.followingCount != null ? 2 : 0) +
      (info.likeCount != null ? 2 : 0) + (info.signature ? 1 : 0);
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

  return {
    CDN_SUFFIXES,
    normalizeEscapedText,
    isAllowedCdnHostname,
    extractUrlsFromText,
    classifyMediaUrl,
    QUALITY_LABELS,
    extractStreamVariants,
    normalizeCaptionInfo,
    sanitizeChatText,
    normalizeProfileInfo,
    EMPTY_PROFILE_INFO,
    EMPTY_AI_SUMMARY_INFO,
    inspectMetadata
  };
});
