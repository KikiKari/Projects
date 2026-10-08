(function (root) {
  "use strict";

  // Export-only projections: never mutate the tab state or playable media URLs.
  const bool = (v) => typeof v === "boolean" ? v : null;
  const num = (v) => typeof v === "number" && Number.isFinite(v) ? v : null;
  const count = (v) => /^(?:0|[1-9]\d{0,19})$/.test(String(v)) ? String(v) : null;
  const utc = (v) => typeof v === "string" && /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{1,3})?Z$/.test(v) ? v : null;
  const uuid = (v) => typeof v === "string" && /^[a-f0-9-]{32,36}$/i.test(v) ? v : null;
  const language = (v) => typeof v === "string" && /^(?:[a-z]{2,3}(?:-[a-zA-Z]{2,4})?|auto|und)$/.test(v) ? v : null;
  const choice = (...values) => (v) => values.includes(v) ? v : null;
  const list = (fn, limit = 2000) => (v) => Array.isArray(v) ? v.slice(-limit).map(fn).filter((x) => x != null) : [];
  function pick(value, schema) {
    const result = {};
    for (const [key, project] of Object.entries(schema)) {
      if (value && Object.hasOwn(value, key)) result[key] = project(value[key]);
    }
    return result;
  }
  const version = (v) => typeof v === "string" && /^\d+\.\d+\.\d+(?:[.-][a-z0-9.-]+)?$/i.test(v) ? v : null;
  const source = choice("dom", "websocket", "metadata", "network", "player", "playerText", "player-dom", "multiple");
  const method = choice("WebcastCaptionMessage", "DomCaption");
  function url(value) {
    try {
      const parsed = new URL(String(value));
      if (!["http:", "https:", "ws:", "wss:"].includes(parsed.protocol)) return null;
      // CDN paths can themselves contain bearer-like identifiers. Exports need
      // only the origin; complete URLs remain available locally for playback.
      return parsed.origin;
    } catch (_) { return null; }
  }
  const captionInfo = (v) => pick(v, {
    present: bool, observed: bool, open: bool, source,
    location: choice("player-dom", "caption_info", "metadata"),
    showType: num, supportLang: list(language, 50), lastObservedAtUtc: utc,
    lastCheckedAtUtc: utc, activeSources: list(source, 3), activityTtlMs: num
  });
  const captionSources = (v) => pick(v, {
    metadata: captionInfo,
    menu: (x) => pick(x, { available: bool, active: bool, lastCheckedAtUtc: utc, lastObservedAtUtc: utc }),
    ...Object.fromEntries(["dom", "websocket", "playerText"].map((key) => [key,
      (x) => pick(x, { active: bool, lastObservedAtUtc: utc, supportLang: list(language, 50) })]))
  });
  const captionSnapshot = (v) => pick(v, { id: uuid, capturedAtUtc: utc, protocolCount: num });
  const embedStartup = (v) => pick(v, {
    id: uuid, phase: choice("loading", "retry-wait", "awaiting-gesture", "playing", "failed", "cancelled"),
    attempt: num, startedAtMs: num, attemptStartedAtMs: num, nextAttemptAtMs: num, completedAtMs: num,
    reason: choice("server-error", "unavailable", "media-error", "timeout", "login-required", "ended", "awaiting-gesture", "navigation-error")
  });
  const hookRecovery = (v) => ({ socketOpenAtMs: null, firstFrameAtMs: null, firstDecodedAtMs: null,
    completedAtMs: null, disconnectToDecodedMs: null, connectToDecodedMs: null, ...pick(v, {
    controller: choice("hook-reconnect"), id: uuid, documentId: uuid, contentDocumentId: uuid,
    contentDocumentStartedAtMs: num, atUtc: utc, mode: choice("normal", "embed"), enabled: bool,
    phase: choice("disabled", "waiting", "unavailable", "scheduled", "connecting", "native", "socket-open",
      "first-frame", "first-decoded-message", "connected", "failed", "cancelled"),
    reason: choice("socket-close", "stream-changed", "configuration-changed", "disabled", "native-takeover",
      "native-connected", "qualified-data", "timeout", "connect-error", "policy-rejected", "protocol-unverified",
      "protocol-error", "send-error", "document-ended"),
    attempt: num, configuredDelayMs: num, effectiveDelayMs: num, detectedAtMs: num,
    scheduledAtMs: num, startedAtMs: num, socketOpenAtMs: num, firstFrameAtMs: num,
    firstDecodedAtMs: num, completedAtMs: num, endedAtMs: num, actualWaitMs: num,
    scheduleOverrunMs: num, disconnectToDecodedMs: num, connectToDecodedMs: num
  }) });
  const player = (v) => pick(v, {
    available: bool, videoAvailable: bool, controlAvailable: bool, playing: bool,
    paused: bool, muted: bool, ended: bool, readyState: num,
    pipActive: bool, fullscreenActive: bool, volume: num, volumePercent: num,
    volumeGainDb: num, peakDbfs: num, limiterEnabled: bool, limiterStrength: num,
    limiterThresholdDbfs: num, limiterReductionDb: num, connectedStreams: num,
    limiterInputPeakDbfs: num, limiterOutputPeakDbfs: num, limiterLookaheadMs: num,
    limiterAudioPath: choice("web-audio"),
    multiGuest: bool, vlcReplacementActive: bool, updatedAtUtc: utc,
    elapsedText: (x) => typeof x === "string" && /^\d{1,4}:\d\d(?::\d\d)?$/.test(x) ? x : null
  });
  const hook = (v) => ({ ...pick(v, { armed: bool, installed: bool, connected: bool, endpoint: url }), hasError: Boolean(v?.lastError) });
  const media = (v) => pick(v, {
    url, protocol: choice("FLV", "HLS", "MP4", "DASH"), source,
    audioOnly: bool, bitrate: num, width: num, height: num, fps: num,
    codec: choice("h264", "h265", "avc", "hevc", "aac"),
    quality: choice("original", "Original", "1080p", "720p", "540p", "480p", "360p", "240p"),
    discoveredAtUtc: utc
  });
  const reason = choice("login-page-no-video", "video-error", "video-ended", "video-paused", "video-not-ready",
    "stale-attempt", "recovered-before-reload", "play-resumed", "play-unconfirmed", "preflight-unavailable",
    "in-flight", "disabled", "not-tiktok", "timeout", "play", "playing", "pause", "waiting", "stalled", "error", "ended", "loadedmetadata");
  const events = new Set([
    "reconnect-skipped", "reconnect-cancelled", "reconnect-superseded", "reconnect-soft-recovery",
    "reconnect-attempt-started", "reconnect-reload-requested", "reconnect-failed", "reconnect-video-progress",
    "socket-telemetry", "hook-recovery",
    "embed-startup",
    "speech-queue-error", "page-state", "hook-status", "player-state", "player-action", "quick-recover", "quality",
    "content", "scan", "quality-clicked-unverified", "audio-context-resume-deferred", "limiter-capture-fallback",
    "timed-live-interruption-dismissed", "quick-recover-error", "media-fallback", "limiter", "limiter-unavailable",
    "dom-chat-scan-error", "dom-chat-loop-error", "dom-observer-error", "audio-settings-restore",
    ...["TLC_PAGE_STATE", "TLC_HOOK_STATUS", "TLC_CAPTION", "TLC_CHAT_MESSAGE", "TLC_LIVE_EVENT", "TLC_GIFT_MESSAGE",
      "TLC_PLAYER_STATE", "TLC_GET_TAB_ACTIVATION", "TLC_QUICK_RECOVER", "TLC_FULLSCREEN_EXITED"].map((x) => `raw:${x}`)
  ]);
  function debugEntry(value) {
    const detail = value?.detail || {};
    return {
      atUtc: utc(value?.atUtc), event: events.has(value?.event) ? value.event : "other-event",
      detail: {
        ...pick(detail, { armed: bool, installed: bool, connected: bool, enabled: bool, activated: bool,
          mediaCount: num, count: num, seconds: num, threshold: num, url, endpoint: url, reason,
          controller: choice("player-quick-recovery", "hook-reconnect"),
          action: choice("play", "pause", "mute", "unmute", "reload", "set-volume", "set-limiter", "fullscreen", "pip"),
          protocol: choice("FLV", "HLS", "MP4"), playerState: player, hook, captionInfo, embedStartup, hookRecovery,
          socket: (value) => pick(value, { documentId: uuid, socketId: uuid, atUtc: utc, elapsedMs: num,
            contentDocumentId: uuid, contentDocumentStartedAtMs: num, recoveryAttemptId: uuid,
            hookAttemptId: uuid, owner: choice("extension", "tiktok"),
            mode: choice("normal", "embed"), stage: choice("socket-created", "socket-open", "first-frame", "first-decoded-message", "socket-close", "socket-error"),
            kind: choice("caption", "chat", "live", "gift"), closeCode: num, wasClean: bool }),
          recoveryAttempt: (value) => pick(value, { id: uuid, documentId: uuid, playbackDocumentId: uuid,
            completedAtMs: num, endedAtMs: num, reloadToVideoMs: num, interruptionToVideoMs: num,
            detectedAtMs: num, scheduledAtMs: num, requestedAtMs: num, startedAtMs: num,
            configuredDelayMs: num, actualWaitMs: num, scheduleOverrunMs: num,
            mode: choice("normal"), trigger: reason, outcome: choice("started", "reload-requested", "reload-failed", "video-progress-confirmed", "cancelled", "superseded") }) }),
        hasError: Boolean(detail.hasError || detail.error || detail.lastError)
      }
    };
  }
  const flagsAndNumbers = (value) => {
    const schema = {};
    for (const key of ["liveInformationBeforePageInformation", "recommendationsAfterWebSocketHook", "bundled", "active",
      "settingsDialogAvailable", "languageControlAvailable", "voiceControlAvailable", "auddTokenConfigured", "pairingConfigured",
      "universalCaptionApiKeyConfigured", "speakNames", "shortenNames", "gameModeEnabled", "rawJsonExportAvailable",
      "jsonLinesExportAvailable", "enabled", "providerConfigured", "resetAvailable"]) schema[key] = bool;
    for (const key of ["candidateCount", "protocolCount", "observedCount", "mutedCount", "permanentMutedCount", "delaySeconds"]) schema[key] = num;
    return pick(value, { ...schema, sources: list(choice("dom", "websocket", "DomCaption", "WebcastCaptionMessage"), 50),
      languages: list(language, 50), placement: choice("main-video-frame"), engine: choice("mpegts.js-media-source-extensions"),
      path: choice("browser-local-service-audd"), controller: choice("player-quick-recovery", "hook-reconnect"),
      delayMeaning: choice("continuous-failure-confirmation", "attempt-start-delay"), scope: choice("tab") });
  };
  function diagnosticReport(report) {
    return {
      schema: "tiktok-live-companion-diagnostic-v3",
      exportProfile: "diagnostic-redacted",
      ...pick(report, {
        generatedAtUtc: utc, version, browserSessionId: uuid, captionSnapshot,
        page: (v) => pick(v, { url, scannedAtUtc: utc }), captionInfo, captionSources,
        profileInfo: (v) => pick(v, { present: bool, live: bool, verified: bool, livePro: bool }),
        aiSummaryInfo: (v) => ({ ...pick(v, { featureFlagPresent: bool, featureEnabled: bool, overviewCardFound: bool }), hasText: Boolean(v?.text) }),
        hook, hookRecovery, playerState: player, media: list(media, 60), embedStartup,
        liveStats: (v) => pick(v, { viewerCount: count, totalViewers: count, likeCount: count, followEvents: count,
          shareEvents: count, shareCount: count, followerCount: count, lastUpdatedUtc: utc }),
        counts: (v) => pick(v, { chat: num, captions: num }),
        localService: (v) => pick(v, { serviceUrl: url, pairingConfigured: bool, auddTokenConfigured: bool,
          reachable: bool, healthStatus: num, installationPending: bool,
          runtime: (x) => pick(x, { version, ttsAvailable: bool, sherpaConfigured: bool, sherpaInstalling: bool,
            auddConfigured: bool, bootstrapPending: bool, extensionConfigured: bool }) }),
        components: (v) => pick(v, Object.fromEntries(["layout", "vlcReplacement", "speechAndChatSettings", "captions",
          "songRecognition", "topChatters", "playerQuickRecovery", "hookReconnect"].map((key) => [key, flagsAndNumbers]))),
        debug: (v) => pick(v, { enabled: bool, entries: (entries) => Array.isArray(entries) ? entries.map(debugEntry) : [] })
      })
    };
  }
  function contentText(value, secrets = []) {
    if (typeof value !== "string") return "";
    let text = value;
    for (const secret of secrets.filter((x) => typeof x === "string" && x.length)) text = text.split(secret).join("[REDACTED]");
    return text.replace(/(?:https?|wss?):\/\/[^\s<>"']+/gi, (match) => url(match) || "[URL]")
      .replace(/\bBearer\s+[a-z0-9._~+/-]+=*/gi, "Bearer [REDACTED]")
      .replace(/\b(?:api[_-]?key|token|secret|password|pairing[_-]?code|cookie|authorization)\s*[:=]\s*[^\s,;]+/gi, "[REDACTED]")
      .replace(/\beyJ[a-z0-9_-]+\.[a-z0-9_-]+\.[a-z0-9_-]+/gi, "[REDACTED]");
  }
  function captions(records, secrets = []) {
    return (Array.isArray(records) ? records : []).slice(-2000).map((entry) => ({
      ...pick(entry, { receivedAtUtc: utc, timestampMs: count, durationMs: count, sentenceId: count,
        sequenceId: count, definite: bool, method, source, endpoint: url }),
      contents: (Array.isArray(entry?.contents) ? entry.contents : []).map((item) => ({
        lang: language(item?.lang), text: contentText(item?.text, secrets)
      }))
    }));
  }
  function captionReport(report, secrets = []) {
    const messages = captions(report.messages, secrets);
    return {
      schema: "tiktok-live-companion-caption-raw-v2", exportProfile: "caption-content-redacted",
      ...pick(report, { generatedAtUtc: utc, version, tabId: num, browserSessionId: uuid, captionSnapshot,
        configuration: (v) => pick(v, { universalApiKeyConfigured: bool }) }),
      stream: { page: pick(report.stream?.page, { url, scannedAtUtc: utc }) },
      text: messages.flatMap((entry) => entry.contents.map((item) => item.text).filter(Boolean)),
      data: { captionInfo: captionInfo(report.data?.captionInfo), captionSources: captionSources(report.data?.captionSources), playerState: player(report.data?.playerState) },
      sources: [...new Set(messages.flatMap((entry) => [entry.method, entry.source]).filter(Boolean))],
      languages: [...new Set(messages.flatMap((entry) => entry.contents.map((item) => item.lang)).filter(Boolean))],
      messages, dataStreams: list(media, 60)(report.dataStreams),
      playerTexts: (Array.isArray(report.playerTexts) ? report.playerTexts : [])
        .filter((item) => item.field === "elapsedText" && /^\d{1,4}:\d\d(?::\d\d)?$/.test(item.text))
        .map((item) => ({ field: "elapsedText", text: item.text })),
      captionProtocol: messages
    };
  }
  const api = { hookRecovery, diagnosticReport, debugEntry, captionReport, captions, url };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  root.TLC_EXPORT_PRIVACY = api;
})(typeof globalThis !== "undefined" ? globalThis : this);
