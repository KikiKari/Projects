importScripts("content-core.js", "export-privacy.js");
importScripts("pipeline-client.js", "pipeline-capture.js");

const STATE_PREFIX = "tlc-tab-";
const LEGACY_HOOK_SCRIPT_ID = "tiktok-live-companion-ws-hook";
const SETTINGS_KEY = "tlc-settings";
const SERVICE_INSTALL_KEY = "tlc-service-install";
const quickRecoverInFlight = new Set();
const tabEventTasks = new Map();
const liveModeTasks = new Map();
const liveModeGenerations = new Map();
const pendingModeRequests = new Map();
function enqueueLiveMode(tabId, mode, task) {
  const previous = liveModeTasks.get(tabId);
  if (previous?.mode === mode) return previous.promise;
  // Keep navigation separate from observation queues: a page may publish state
  // while a mode change awaits its response. Opposite mode clicks stay ordered.
  const promise = (previous?.promise || Promise.resolve()).catch(() => {}).then(task);
  const entry = { mode, promise };
  liveModeTasks.set(tabId, entry);
  const clear = () => { if (liveModeTasks.get(tabId) === entry) liveModeTasks.delete(tabId); };
  promise.then(clear, clear);
  return promise;
}
const SERIAL_TAB_EVENTS = new Set(["TLC_PAGE_STATE", "TLC_CAPTION", "TLC_MEDIA_FOUND", "TLC_CHAT_MESSAGE",
  "TLC_RECOVERY_MEDIA_OBSERVATION", "TLC_QUICK_RECOVER", "TLC_SET_HOOK_RECONNECT", "TLC_SET_QUICK_RECOVER", "TLC_HOOK_RECOVERY",
  "TLC_GIFT_MESSAGE", "TLC_LIVE_EVENT", "TLC_HOOK_STATUS", "TLC_PLAYER_STATE_PUSH", "TLC_DEBUG_EVENT"]);
function enqueueTabEvent(tabId, task) {
  const next = (tabEventTasks.get(tabId) || Promise.resolve()).then(task);
  // A failed event must not poison the next event's queue.
  const settled = next.catch(() => {});
  tabEventTasks.set(tabId, settled);
  settled.then(() => { if (tabEventTasks.get(tabId) === settled) tabEventTasks.delete(tabId); });
  return next;
}
const PROFILE_PREFIX = "tlc-profile-";
const STREAM_CACHE_PREFIX = "tlc-stream-";
const MAX_MEDIA = 60;
const MAX_CAPTIONS = 2000;
const MAX_CHAT = 500;
const MAX_EVENT_IDS = 500;
const MAX_PARTICIPANTS = 5000;
const core = globalThis.TLC_CONTENT_CORE;
const exportPrivacy = globalThis.TLC_EXPORT_PRIVACY;
let offscreenCreation = null;

function stateKey(tabId) {
  return `${STATE_PREFIX}${tabId}`;
}

function newBrowserSessionId() {
  if (typeof crypto.randomUUID === "function") return crypto.randomUUID();
  const bytes = crypto.getRandomValues(new Uint8Array(16));
  return [...bytes].map((value) => value.toString(16).padStart(2, "0")).join("");
}

function emptyRecommendationScan() {
  return {
    status: "idle",
    runId: "",
    sourceUrl: "",
    sourceHandle: "",
    requested: 20,
    scanned: 0,
    found: 0,
    items: [],
    startedAtUtc: null,
    updatedAtUtc: null,
    completedAtUtc: null,
    error: ""
  };
}

function emptyState() {
  return {
    enabled: false,
    browserSessionId: "",
    page: { url: "", title: "", scannedAtUtc: null },
    captionInfo: { present: false, open: null, supportLang: [], location: null, showType: null, observed: false, source: null },
    captionSources: core.captionSourceSnapshot(),
    profileInfo: { ...core.EMPTY_PROFILE_INFO },
    aiSummaryInfo: { ...core.EMPTY_AI_SUMMARY_INFO },
    recommendationScan: emptyRecommendationScan(),
    menuCaptionAvailable: false,
    menuCaptionActive: false,
    hook: { armed: false, installed: false, connected: false, lastError: null },
    stream: { key: "", handle: "", roomId: "", teamTag: "", teamEvidence: {} },
    liveStats: {
      viewerCount: null,
      totalViewers: null,
      likeCount: null,
      followEvents: 0,
      shareEvents: 0,
      shareCount: null,
      followerCount: null,
      lastUpdatedUtc: null,
      recentEventIds: []
    },
    selectedQuality: null,
    playerState: {
      available: false, playing: false, muted: false, elapsedText: "", pipActive: false, fullscreenActive: false,
      volume: 1, volumePercent: 100, volumeGainDb: 0, peakDbfs: null,
      limiterEnabled: false, limiterStrength: 30, limiterThresholdDbfs: core.limiterStrengthToDbfs(30), limiterReductionDb: 0,
      connectedStreams: 0, multiGuest: false
    },
    media: [],
    captions: [],
    chatMessages: [],
    chatSourceTabId: null,
    chatTargetTabId: null,
    chatSourceOnly: false,
    participants: {},
    participantsTruncated: false,
    streamMutes: [],
    recentGiftIds: [],
    quickRecoverEnabled: false,
    quickRecoverSeconds: 3,
    recoveryConfigVersion: 1,
    hookReconnect: { enabled: false, seconds: 3 },
    hookRecovery: { phase: "disabled" },
    speech: { enabled: false, status: "Vorlesen ist ausgeschaltet.", lastSpokenKey: "", lastSpokenAtUtc: null, queueDepth: 0 },
    recovery: { lastQuickRecoverAtUtc: null, lastReason: "" },
    debug: { enabled: false, entries: [] }
  };
}

async function getState(tabId) {
  const stored = await chrome.storage.session.get(stateKey(tabId));
  const defaults = emptyState();
  let state = stored[stateKey(tabId)];
  // Older releases used the global delay at runtime but exported a stale tab
  // value. Migrate from the formerly effective value once, then keep it local.
  if (!state || state.recoveryConfigVersion !== 1) {
    const settings = await getSettings();
    const migrated = {
      ...(state || defaults),
      quickRecoverSeconds: normalizeRecoveryDelay(settings.quickRecoverSeconds),
      recoveryConfigVersion: 1
    };
    if (Number.isInteger(tabId) && tabId >= 0) {
      await chrome.storage.session.set({ [stateKey(tabId)]: migrated });
    }
    state = migrated;
  }
  const capturedAt = Date.now();
  let captionSources = state.captionSources;
  if (!captionSources) {
    captionSources = core.captionSourceSnapshot();
    if (!state.captionInfo?.observed) captionSources.metadata = core.normalizeCaptionInfo(state.captionInfo);
    for (const caption of state.captions || []) {
      const observedAt = Date.parse(caption.receivedAtUtc);
      if (Number.isFinite(observedAt) && observedAt <= capturedAt) {
        captionSources = core.observeCaptionSource(captionSources, caption, observedAt);
      }
    }
  }
  captionSources = core.captionSourceSnapshot(captionSources, capturedAt);
  return {
    ...defaults,
    ...state,
    captionSources,
    captionInfo: core.summarizeCaptionSources(captionSources, capturedAt),
    captionSnapshot: { id: newBrowserSessionId(), capturedAtUtc: new Date(capturedAt).toISOString(),
      protocolCount: (state.captions || []).length },
    hook: { ...defaults.hook, ...(state.hook || {}) },
    stream: { ...defaults.stream, ...(state.stream || {}), teamEvidence: state.stream?.teamEvidence || {} },
    liveStats: { ...defaults.liveStats, ...(state.liveStats || {}) },
    playerState: { ...defaults.playerState, ...(state.playerState || {}) },
    profileInfo: { ...defaults.profileInfo, ...(state.profileInfo || {}) },
    aiSummaryInfo: { ...defaults.aiSummaryInfo, ...(state.aiSummaryInfo || {}) },
    recommendationScan: { ...defaults.recommendationScan, ...(state.recommendationScan || {}), items: (state.recommendationScan?.items || []).slice(0, 50) },
    chatMessages: state.chatMessages || [],
    participants: state.participants || {},
    participantsTruncated: Boolean(state.participantsTruncated),
    streamMutes: state.streamMutes || [],
    recentGiftIds: state.recentGiftIds || [],
    quickRecoverEnabled: Boolean(state.quickRecoverEnabled),
    quickRecoverSeconds: normalizeRecoveryDelay(state.quickRecoverSeconds),
    hookReconnect: { enabled: Boolean(state.hookReconnect?.enabled), seconds: normalizeRecoveryDelay(state.hookReconnect?.seconds) },
    speech: { ...defaults.speech, ...(state.speech || {}) },
    recovery: { ...defaults.recovery, ...(state.recovery || {}) },
    captions: state.captions || [],
    media: state.media || [],
    debug: { ...defaults.debug, ...(state.debug || {}), entries: state.debug?.entries || [] }
  };
}

function pageHandle(page) {
  return core.liveHandleFromUrl(page?.url);
}

function normalizeHandle(value) {
  return String(value || "").replace(/^@/, "").toLocaleLowerCase();
}

function profileHandle(profile) {
  return normalizeHandle(profile?.uniqueId || profile?.handle || "");
}

function stateIdentityHandle(state) {
  return normalizeHandle(state?.stream?.handle || state?.profileInfo?.uniqueId || pageHandle(state?.page) || "");
}

function pageStateHandle(state, message = {}) {
  return normalizeHandle(pageHandle(message.page || state?.page) || profileHandle(message.profileInfo) || state?.stream?.handle || "");
}

function profileMatchesHandle(profile, handle) {
  const candidate = profileHandle(profile);
  return !handle || !candidate || candidate === handle;
}

function resetPageIdentityState(state, handle) {
  state.captionSources = core.captionSourceSnapshot();
  state.captionInfo = core.summarizeCaptionSources(state.captionSources);
  state.menuCaptionAvailable = false;
  state.menuCaptionActive = false;
  state.captions = [];
  state.profileInfo = { ...core.EMPTY_PROFILE_INFO };
  state.aiSummaryInfo = { ...core.EMPTY_AI_SUMMARY_INFO };
  state.liveStats = { ...state.liveStats, followerCount: null };
  state.recommendationScan = emptyRecommendationScan();
}

function cleanRecommendationText(value, limit) {
  return String(value || "").normalize("NFKC").replace(/\s+/g, " ").trim().slice(0, limit);
}

function sanitizeRecommendationItem(raw, fallbackPosition) {
  const handle = normalizeHandle(raw?.handle).replace(/[^a-z0-9._-]/g, "").slice(0, 64);
  if (!handle) return null;
  let url = "";
  try {
    const parsed = new URL(String(raw?.url || ""));
    if (parsed.protocol === "https:" && parsed.hostname === "www.tiktok.com" && core.liveHandleFromUrl(parsed.href) === handle) url = parsed.href;
  } catch (_) {}
  const numericCount = raw?.viewerCount == null ? null : Number(raw.viewerCount);
  return {
    handle,
    displayName: cleanRecommendationText(raw?.displayName, 160),
    title: cleanRecommendationText(raw?.title, 300),
    viewerCount: Number.isSafeInteger(numericCount) && numericCount >= 0 ? numericCount : null,
    viewerLabel: cleanRecommendationText(raw?.viewerLabel, 32),
    url: url || `https://www.tiktok.com/@${handle}/live`,
    position: Math.max(1, Math.min(50, Math.round(Number(raw?.position) || fallbackPosition)))
  };
}

function sanitizeRecommendationItems(items, limit = 50) {
  const sanitized = (Array.isArray(items) ? items : [])
    .slice(0, 100)
    .map((item, index) => sanitizeRecommendationItem(item, index + 1))
    .filter(Boolean);
  return core.dedupeRecommendations(sanitized).slice(0, Math.max(1, Math.min(50, limit)));
}

function resetPageIdentityIfChanged(state, nextHandle) {
  const currentHandle = stateIdentityHandle(state);
  if (!nextHandle || !currentHandle || nextHandle === currentHandle) return false;
  resetPageIdentityState(state, nextHandle);
  return true;
}

function profileKey(handle) {
  return `${PROFILE_PREFIX}${String(handle || "").toLocaleLowerCase()}`;
}

async function cacheProfile(profile) {
  if (!profile?.present || !profile.uniqueId) return;
  const normalizedHandle = String(profile.uniqueId).toLocaleLowerCase();
  await chrome.storage.session.set({ [profileKey(normalizedHandle)]: profile });
  const stored = await chrome.storage.session.get(null);
  for (const [key, value] of Object.entries(stored)) {
    if (!key.startsWith(STATE_PREFIX) || pageHandle(value?.page) !== normalizedHandle) continue;
    const merged = mergeProfile(value.profileInfo, profile);
    value.profileInfo = merged;
    if (merged?.followerCount != null) value.liveStats.followerCount = merged.followerCount;
    const targetTabId = Number(key.slice(STATE_PREFIX.length));
    if (Number.isInteger(targetTabId)) await setState(targetTabId, value);
  }
}

async function cachedProfile(handle) {
  if (!handle) return null;
  const stored = await chrome.storage.session.get(profileKey(handle));
  return stored[profileKey(handle)] || null;
}

async function addDebug(tabId, event, detail = {}) {
  if (!Number.isInteger(tabId) || tabId < 0) return;
  TLCPipelines.publish(tabId, 'debug-logs', { event, detail }, { event, detail }, 'background-debug').catch(() => {});
  if (event.startsWith("reconnect-") || event === "quick-recover") {
    detail = { ...detail, controller: "player-quick-recovery" };
  }
  const state = await getState(tabId);
  if (!state.debug?.enabled) return;
  state.debug.entries = [...(state.debug.entries || []), exportPrivacy.debugEntry({ atUtc: new Date().toISOString(), event, detail })];
  await setState(tabId, state);
}

function redactUrl(raw) {
  try {
    return exportPrivacy.url(raw) || "ungültig";
  } catch (_) { return "ungültig"; }
}

async function setState(tabId, state) {
  for (const [pipeline, data] of [['title', state.captionInfo], ['profile', state.profileInfo], ['live', state.liveStats], ['top-chatters', state.participants]]) {
    TLCPipelines.publish(tabId, pipeline, data, data, 'companion-state').catch(() => {});
  }
  await chrome.storage.session.set({ [stateKey(tabId)]: state });
  await cacheStreamSnapshot(state);
  const embedStartup = await getEmbedSession(tabId);
  chrome.runtime.sendMessage({ type: "TLC_STATE_UPDATED", tabId, state: { ...state, embedStartup } }).catch(() => {});
  return state;
}

async function getSettings() {
  const stored = await chrome.storage.local.get(SETTINGS_KEY);
  return {
    keepSpeechActive: false,
    speechVolume: 0.5,
    speechLanguage: "auto",
    speechVoiceName: "",
    gameModeEnabled: false,
    filterExternalSpeechTriggers: false,
    speakNames: true,
    shortenNames: false,
    autoChatRefreshEnabled: false,
    autoChatRefreshMinutes: 5,
    serviceUrl: "http://127.0.0.1:43117",
    pairingCode: "",
    auddApiToken: "",
    universalCaptionApiKey: "",
    playerVolume: 100,
    limiterStrength: 30,
    limiterEnabled: false,
    songRecognitionEnabled: false,
    hookEnabled: false,
    autoHook: false,
    quickRecoverEnabled: false,
    quickRecoverSeconds: 3,
    speechEnabled: false,
    waitingForTikTok: true,
    debugEnabled: false,
    permanentMutes: [],
    ...(stored[SETTINGS_KEY] || {})
  };
}

async function setSettings(patch) {
  const settings = { ...(await getSettings()), ...patch };
  await chrome.storage.local.set({ [SETTINGS_KEY]: settings });
  return settings;
}

function normalizeRecoveryDelay(value) {
  const seconds = Number(value);
  return Number.isFinite(seconds) && seconds > 0 ? Math.max(1, Math.min(59, Math.round(seconds))) : 3;
}

function booleanValue(value) {
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value !== 0;
  if (typeof value === "string") return /^(?:1|true|yes|ja|on)$/i.test(value.trim());
  return Boolean(value);
}

function normalizePlayerState(playerState = {}) {
  return {
    ...playerState,
    available: booleanValue(playerState.available),
    videoAvailable: booleanValue(playerState.videoAvailable ?? playerState.available),
    controlAvailable: booleanValue(playerState.controlAvailable),
    playing: booleanValue(playerState.playing),
    muted: booleanValue(playerState.muted),
    limiterEnabled: booleanValue(playerState.limiterEnabled),
    pipActive: booleanValue(playerState.pipActive),
    fullscreenActive: booleanValue(playerState.fullscreenActive),
    multiGuest: booleanValue(playerState.multiGuest)
  };
}

function buildCaptionRawExport(state, tabId, universalApiKeyConfigured = false) {
  const messages = Array.isArray(state.captions) ? state.captions.slice(-MAX_CAPTIONS) : [];
  const text = messages
    .map((message) => core.captionText(message))
    .filter(Boolean);
  const languages = new Set(Array.isArray(state.captionInfo?.supportLang) ? state.captionInfo.supportLang : []);
  const sources = new Set();
  for (const message of messages) {
    if (message?.source) sources.add(String(message.source));
    if (message?.method) sources.add(String(message.method));
    for (const content of message?.contents || []) {
      if (content?.lang) languages.add(String(content.lang));
    }
  }
  const playerTexts = Object.entries(state.playerState || {})
    .filter(([key, value]) => /text$/i.test(key) && typeof value === "string" && value.trim())
    .map(([field, value]) => ({ field, text: value.trim() }));
  return {
    schema: "tiktok-live-companion-caption-raw-v1",
    generatedAtUtc: new Date().toISOString(),
    version: chrome.runtime.getManifest().version,
    tabId,
    browserSessionId: state.browserSessionId || "",
    captionSnapshot: state.captionSnapshot,
    stream: {
      handle: state.stream?.handle || pageHandle(state.page) || "",
      roomId: state.stream?.roomId || null,
      page: state.page || null
    },
    configuration: { universalApiKeyConfigured: Boolean(universalApiKeyConfigured) },
    text,
    data: {
      captionInfo: state.captionInfo || null,
      captionSources: state.captionSources,
      playerState: state.playerState || null
    },
    sources: [...sources],
    languages: [...languages],
    messages: messages,
    dataStreams: Array.isArray(state.media) ? state.media : [],
    playerTexts: playerTexts,
    captionProtocol: messages
  };
}

function loopbackServiceUrl(value) {
  try {
    const url = new URL(String(value || ""));
    if (url.protocol !== "http:" || !["127.0.0.1", "localhost"].includes(url.hostname)) return "";
    return url.origin;
  } catch (_) {
    return "";
  }
}

function profileCompleteness(profile) {
  return [profile?.uniqueId, profile?.nickname, profile?.signature, profile?.followingCount, profile?.followerCount, profile?.likeCount, profile?.verified ? "verified" : "", profile?.livePro ? "livePro" : "", profile?.sponsoredContent ? "sponsoredContent" : "", profile?.paidPartnership ? "paidPartnership" : ""]
    .filter((value) => value != null && value !== "").length;
}

function mergeProfile(current, incoming) {
  if (!incoming?.present) return current;
  const merged = !current?.present || profileCompleteness(incoming) >= profileCompleteness(current)
    ? { ...current, ...incoming }
    : { ...incoming, ...current };
  return {
    ...merged,
    live: Boolean(current?.live || incoming.live),
    verified: Boolean(current?.verified || incoming.verified),
    verifiedLabel: current?.verifiedLabel || incoming.verifiedLabel || "",
    livePro: Boolean(current?.livePro || incoming.livePro),
    liveProLabel: current?.liveProLabel || incoming.liveProLabel || "",
    sponsoredContent: Boolean(current?.sponsoredContent || incoming.sponsoredContent),
    sponsoredContentLabel: current?.sponsoredContentLabel || incoming.sponsoredContentLabel || "",
    paidPartnership: Boolean(current?.paidPartnership || incoming.paidPartnership),
    paidPartnershipLabel: current?.paidPartnershipLabel || incoming.paidPartnershipLabel || ""
  };
}

function streamCacheKey(handle) {
  return `${STREAM_CACHE_PREFIX}${String(handle || "").toLocaleLowerCase()}`;
}

function streamCacheHandle(state) {
  return String(state?.stream?.handle || pageHandle(state?.page) || state?.profileInfo?.uniqueId || "").toLocaleLowerCase();
}

function mergeLiveStats(current = {}, incoming = {}) {
  if (!incoming || typeof incoming !== "object") return current;
  const merged = { ...emptyState().liveStats, ...(current || {}) };
  for (const key of ["viewerCount", "totalViewers", "likeCount", "shareCount", "followerCount"]) {
    if (incoming[key] != null && incoming[key] !== "") merged[key] = incoming[key];
  }
  if (incoming.lastUpdatedUtc) merged.lastUpdatedUtc = incoming.lastUpdatedUtc;
  return merged;
}

async function cacheStreamSnapshot(state) {
  const handle = streamCacheHandle(state);
  if (!handle) return;
  const hasLiveStats = Boolean(state.liveStats?.lastUpdatedUtc || state.liveStats?.viewerCount != null || state.liveStats?.totalViewers != null || state.liveStats?.likeCount != null);
  const hasChat = Boolean(state.chatMessages?.length || Object.keys(state.participants || {}).length);
  if (!hasLiveStats && !hasChat) return;
  await chrome.storage.session.set({
    [streamCacheKey(handle)]: {
      handle,
      stream: state.stream,
      liveStats: state.liveStats,
      chatMessages: state.chatMessages || [],
      participants: state.participants || {},
      participantsTruncated: Boolean(state.participantsTruncated),
      updatedAtUtc: new Date().toISOString()
    }
  });
}

async function cachedStreamSnapshot(handle) {
  if (!handle) return null;
  const stored = await chrome.storage.session.get(streamCacheKey(handle));
  return stored[streamCacheKey(handle)] || null;
}

function mergeStreamSnapshot(state, snapshot) {
  if (!snapshot) return state;
  const sameHandle = !state.stream?.handle || !snapshot.handle || state.stream.handle === snapshot.handle;
  if (!sameHandle) return state;
  state.liveStats = mergeLiveStats(state.liveStats, snapshot.liveStats);
  if (!(state.chatMessages || []).length && snapshot.chatMessages?.length) state.chatMessages = snapshot.chatMessages;
  if (!Object.keys(state.participants || {}).length && snapshot.participants) {
    state.participants = snapshot.participants;
    state.participantsTruncated = Boolean(snapshot.participantsTruncated);
  }
  return state;
}

async function patchState(tabId, patch) {
  const state = await getState(tabId);
  return setState(tabId, { ...state, ...patch });
}

async function addMedia(tabId, entries, source) {
  if (!Number.isInteger(tabId) || tabId < 0) return;
  const state = await getState(tabId);
  const mediaKey = (item) => {
    try {
      const parsed = new URL(item.url);
      return `${item.protocol}|${item.audioOnly ? 1 : 0}|${parsed.pathname}`;
    } catch (_) {
      return item.url;
    }
  };
  const expiry = (item) => {
    try { return Number(new URL(item.url).searchParams.get("expire") || 0); }
    catch (_) { return 0; }
  };
  const byUrl = new Map();
  for (const item of state.media) {
    const key = mediaKey(item);
    const previous = byUrl.get(key);
    if (!previous || expiry(item) >= expiry(previous)) byUrl.set(key, item);
  }
  for (const raw of entries || []) {
    const classified = typeof raw === "string" ? core.classifyMediaUrl(raw) : core.classifyMediaUrl(raw.url);
    if (!classified) continue;
    const enriched = typeof raw === "object" ? { ...classified, ...raw, url: classified.url } : classified;
    const key = mediaKey(enriched);
    const previous = byUrl.get(key);
    const candidate = {
      ...previous,
      ...enriched,
      source: previous?.source || source,
      discoveredAtUtc: previous?.discoveredAtUtc || new Date().toISOString()
    };
    if (!previous || expiry(candidate) >= expiry(previous)) byUrl.set(key, candidate);
  }
  TLCPipelines.publish(tabId, 'media-links', [...byUrl.values()], entries, source).catch(() => {});
  state.media = [...byUrl.values()];
  await setState(tabId, state);
}

async function addCaption(tabId, caption) {
  const state = await getState(tabId);
  const receivedAtUtc = caption.receivedAtUtc || new Date().toISOString();
  const timestamp = Date.parse(receivedAtUtc) || Date.now();
  const entry = { ...caption, receivedAtUtc };
  state.captionSources = core.observeCaptionSource(state.captionSources, entry);
  state.captionInfo = core.summarizeCaptionSources(state.captionSources);
  // Retain both observations even when their words overlap. Deduplicate only
  // exact repeats within a source; final/revised text for the same ID survives.
  const key = (item) => JSON.stringify([core.captionSource(item), item.sentenceId || null,
    item.sequenceId || null, item.definite ?? null, item.contents || []]);
  const duplicate = state.captions.slice(-20).some((item) => key(item) === key(entry)
    && Math.abs(timestamp - Date.parse(item.receivedAtUtc)) < 2_500);
  if (!duplicate) state.captions.push(entry);
  state.captions = state.captions.slice(-MAX_CAPTIONS);
  await setState(tabId, state);
}

function chatKey(author, content) {
  return `${String(author || "").toLocaleLowerCase()}\n${String(content || "").toLocaleLowerCase()}`;
}

function participantKey(message, fallbackAuthor = "") {
  if (message?.userId) return `id:${message.userId}`;
  if (message?.displayId) return `handle:${core.normalizedIdentity(message.displayId)}`;
  return `name:${core.normalizedIdentity(message?.author || message?.nickname || fallbackAuthor || "chat")}`;
}

function participantMuted(state, settings, key) {
  return (state.streamMutes || []).includes(key) || (settings.permanentMutes || []).includes(key);
}

function cleanSpeechPayload(value) {
  return String(value || "")
    .normalize("NFC")
    .replace(/[\u0000-\u001f\u007f-\u009f]/g, " ")
    .replace(/[\u200b-\u200f\u202a-\u202e\u2060-\u206f\ufeff]/g, "")
    .replace(/[\ufe00-\ufe0f\u200d]/g, "")
    .replace(/[\u{1f000}-\u{1faff}\u{2600}-\u{27bf}]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function speechLanguage(settings, item, text) {
  if (settings.speechLanguage === "auto" && /[äöüÄÖÜß]/.test(text)) return "de-DE";
  return core.resolveSpeechLanguage(settings.speechLanguage, item.contentLanguage);
}

async function ensureOffscreenDocument() {
  if (!chrome.offscreen?.createDocument) throw new Error("Offscreen-Sprachausgabe wird von diesem Browser nicht unterstützt.");
  if (chrome.runtime.getContexts) {
    const contexts = await chrome.runtime.getContexts({
      contextTypes: ["OFFSCREEN_DOCUMENT"],
      documentUrls: [chrome.runtime.getURL("offscreen.html")]
    });
    if (contexts.length) return;
  }
  if (!offscreenCreation) {
    offscreenCreation = chrome.offscreen.createDocument({
      url: "offscreen.html",
      reasons: ["AUDIO_PLAYBACK"],
      justification: "Tab-lokales Vorlesen muss beim Vollbild und beim Neuaufbau des Sidepanels weiterlaufen."
    }).catch((error) => {
      if (!/single offscreen|already exists/i.test(String(error?.message || error))) throw error;
    }).finally(() => { offscreenCreation = null; });
  }
  await offscreenCreation;
}

async function sendOffscreen(message) {
  await ensureOffscreenDocument();
  return chrome.runtime.sendMessage({ target: "offscreen", ...message });
}

async function queueSpeechForTab(tabId, state, item) {
  if (!state.speech?.enabled || item.muted) return;
  const settings = await getSettings();
  if (core.shouldFilterExternalSpeechTrigger(item.content || item.text || "", settings.filterExternalSpeechTriggers)) return;
  if (settings.gameModeEnabled && core.shouldFilterGameModeSpeech(item, state.participants || {}, state.chatMessages || [])) return;
  const text = cleanSpeechPayload(core.composeSpeechText(item, {
    teamTag: state.stream?.teamTag || "",
    speakNames: settings.speakNames !== false,
    shortenNames: Boolean(settings.shortenNames)
  }));
  if (!text) return;
  const key = `${core.spokenNickname(item.author || "")}|${text}`.toLocaleLowerCase("de-DE").replace(/\s+/g, " ").trim();
  const lastAt = Date.parse(state.speech.lastSpokenAtUtc || "") || 0;
  if (key && state.speech.lastSpokenKey === key && Date.now() - lastAt <= 20000) return;
  state.speech = {
    ...state.speech,
    status: "Vorlesen aktiv · Zeile vorgemerkt.",
    lastSpokenKey: key,
    lastSpokenAtUtc: new Date().toISOString(),
    queueDepth: Math.min(5, Number(state.speech.queueDepth || 0) + 1)
  };
  await setState(tabId, state);
  await sendOffscreen({
    type: "TLC_OFFSCREEN_SPEAK",
    tabId,
    text,
    language: speechLanguage(settings, item, text),
    voiceName: settings.speechVoiceName || "",
    volume: Math.max(0, Math.min(1, Number(settings.speechVolume ?? 0.5))),
    serviceUrl: loopbackServiceUrl(settings.serviceUrl) || "http://127.0.0.1:43117",
    pairingCode: settings.pairingCode || ""
  });
}

function participantAliases(participant, fallbackKey = "") {
  return [...new Set([
    fallbackKey,
    participant?.userId ? `id:${participant.userId}` : "",
    participant?.displayId ? `handle:${core.normalizedIdentity(participant.displayId)}` : "",
    participant?.name ? `name:${core.normalizedIdentity(participant.name)}` : ""
  ].filter(Boolean))];
}

function relayTargetTabId(state) {
  const targetTabId = state?.chatTargetTabId;
  return state?.chatSourceOnly && Number.isInteger(targetTabId) && targetTabId >= 0 ? targetTabId : null;
}

async function relayToEmbedTab(sourceTabId, state, type, payload) {
  const targetTabId = relayTargetTabId(state);
  if (targetTabId == null || targetTabId === sourceTabId || payload?.relayedFromTabId != null) return;
  // Only a reciprocal, same-stream pair may cross tab boundaries. A stale
  // source pointer must not route to a normal tab, tab zero, or a different LIVE.
  const targetState = (await chrome.storage.session.get(stateKey(targetTabId)))[stateKey(targetTabId)];
  if (targetState?.chatSourceTabId !== sourceTabId || targetState.chatSourceOnly) return;
  await enqueueTabEvent(targetTabId, async () => {
    const current = (await chrome.storage.session.get(stateKey(targetTabId)))[stateKey(targetTabId)];
    if (current?.chatSourceTabId !== sourceTabId || current.chatSourceOnly) return;
    const handle = state.stream?.handle;
    if (!handle || normalizeHandle(current.stream?.handle) !== normalizeHandle(handle)) return;
    const sourceTab = await chrome.tabs.get(sourceTabId).catch(() => null);
    const targetTab = await chrome.tabs.get(targetTabId).catch(() => null);
    if (!sameLiveUrl(sourceTab?.url, normalLiveUrl(handle)) || !sameLiveUrl(targetTab?.url, embedLiveUrl(handle))) return;
    const relayPayload = { ...payload, relayedFromTabId: sourceTabId };
    if (type === "chat") await addChatMessage(targetTabId, relayPayload);
    else if (type === "gift") await addGiftMessage(targetTabId, relayPayload);
    else if (type === "live") await addLiveEvent(targetTabId, relayPayload);
  });
}

function updateParticipant(state, raw, author, patch = {}) {
  const requestedKey = participantKey(raw, author);
  const matchedEntry = Object.entries(state.participants).find(([, participant]) =>
    core.sameParticipant(participant, { ...raw, name: author })
  );
  const key = state.participants[requestedKey] ? requestedKey : (matchedEntry?.[0] || requestedKey);
  const existing = state.participants[key];
  const participant = {
    key,
    ...core.mergeParticipantRecord(existing, raw, author, patch)
  };
  state.participants[key] = participant;
  return { key, participant };
}

function observeTeamTag(state, author, content) {
  if (state.stream.teamTag) return state.stream.teamTag;
  const result = core.accumulateTeamEvidence(
    state.stream.teamEvidence,
    author,
    content,
    (state.chatMessages || []).map((item) => item.content)
  );
  state.stream.teamEvidence = result.evidence;
  if (result.teamTag) {
    state.stream.teamTag = result.teamTag;
    state.chatMessages = (state.chatMessages || []).map((item) => ({
      ...item,
      author: core.stripTeamTag(item.author, result.teamTag),
      content: core.stripTeamTag(item.content, result.teamTag)
    }));
    for (const participant of Object.values(state.participants || {})) participant.name = core.stripTeamTag(participant.name, result.teamTag);
  }
  return state.stream.teamTag;
}

function resetStreamData(state, identity) {
  const hadIdentity = Boolean(state.stream?.handle || state.stream?.roomId);
  if (hadIdentity) {
    state.captionSources = core.captionSourceSnapshot();
    state.captionInfo = core.summarizeCaptionSources(state.captionSources);
    state.captions = [];
    state.menuCaptionAvailable = false;
    state.menuCaptionActive = false;
  }
  state.stream = {
    key: `${identity.handle || ""}|${identity.roomId || ""}`,
    handle: identity.handle || "",
    roomId: identity.roomId || "",
    teamTag: "",
    teamEvidence: {}
  };
  state.chatMessages = [];
  state.participants = {};
  state.participantsTruncated = false;
  state.streamMutes = [];
  state.recentGiftIds = [];
  state.liveStats = emptyState().liveStats;
}

function applyStreamIdentity(state, identity = {}) {
  const handle = String(identity.handle || state.stream?.handle || "").toLocaleLowerCase();
  const roomId = String(identity.roomId || state.stream?.roomId || "");
  const currentHandle = state.stream?.handle || "";
  const currentRoomId = state.stream?.roomId || "";
  const changed = core.streamIdentityChanged(
    { handle: currentHandle, roomId: currentRoomId },
    { handle, roomId }
  );
  if (changed) resetStreamData(state, { handle, roomId });
  else state.stream = { ...state.stream, handle, roomId, key: `${handle}|${roomId}` };
}

async function handleLiveTabUrlChange(tabId, url, title = "") {
  const nextHandle = core.liveHandleFromUrl(url);
  if (!nextHandle) return;
  const state = await getState(tabId);
  resetPageIdentityIfChanged(state, nextHandle);
  applyStreamIdentity(state, { handle: nextHandle });
  state.page = { ...state.page, url, title: title || state.page?.title || "", scannedAtUtc: null };
  await setState(tabId, state);
}

async function addChatMessage(tabId, rawMessage) {
  if (!Number.isInteger(tabId) || tabId < 0) return;
  const rawAuthor = core.sanitizeChatText(rawMessage.nickname || rawMessage.displayId || rawMessage.author || "Chat");
  let content = core.sanitizeChatText(rawMessage.content);
  if (!content) return;
  const state = await getState(tabId);
  const teamTag = observeTeamTag(state, rawAuthor, content);
  const author = core.stripTeamTag(rawAuthor, teamTag) || "Chat";
  content = core.stripTeamTag(content, teamTag);
  const receivedAtUtc = rawMessage.receivedAtUtc || new Date().toISOString();
  const dedupeKey = chatKey(author, content);
  const receivedAt = Date.parse(receivedAtUtc) || Date.now();
  const duplicateMessageId = rawMessage.messageId && (state.chatMessages || []).some((item) =>
    item.messageId && String(item.messageId) === String(rawMessage.messageId)
  );
  if (duplicateMessageId) return;
  const duplicate = (state.chatMessages || []).some((item) => {
    const existingKey = item.dedupeKey || chatKey(item.author, item.content);
    const existingAt = Date.parse(item.receivedAtUtc) || 0;
    return existingKey === dedupeKey && Math.abs(receivedAt - existingAt) <= 15000;
  });
  const participantResult = updateParticipant(state, rawMessage, author);
  if (participantResult.participant) {
    participantResult.participant.messageCount += 1;
    participantResult.participant.wordCount += core.wordCount(content);
  }
  if (duplicate) {
    await setState(tabId, state);
    await relayToEmbedTab(tabId, state, "chat", rawMessage);
    return;
  }
  const settings = await getSettings();
  const chatMessage = {
    messageId: rawMessage.messageId || null,
    author: author || "Chat",
    content,
    userId: rawMessage.userId || null,
    displayId: rawMessage.displayId || "",
    participantKey: participantResult.key,
    muted: participantMuted(state, settings, participantResult.key),
    contentLanguage: rawMessage.contentLanguage || "",
    source: rawMessage.source || "unbekannt",
    receivedAtUtc,
    dedupeKey
  };
  state.chatMessages = [...(state.chatMessages || []), chatMessage].slice(-MAX_CHAT);
  await setState(tabId, state);
  await queueSpeechForTab(tabId, state, chatMessage).catch((error) => addDebug(tabId, "speech-queue-error", { error: String(error?.message || error).slice(0, 300) }));
  await relayToEmbedTab(tabId, state, "chat", rawMessage);
}

async function addGiftMessage(tabId, rawMessage) {
  if (!Number.isInteger(tabId) || tabId < 0) return;
  if (rawMessage.source === "websocket" && rawMessage.repeatEnd === false) return;
  const state = await getState(tabId);
  const author = core.stripTeamTag(rawMessage.nickname || rawMessage.displayId || rawMessage.author || "Chat", state.stream.teamTag);
  const count = Math.max(1, Number.parseInt(rawMessage.repeatCount || "1", 10) || 1);
  const timeBucket = Math.floor((Date.parse(rawMessage.receivedAtUtc) || Date.now()) / 15000);
  const correlationId = `gift-match:${core.normalizedIdentity(author)}:${count}:${timeBucket}`;
  const messageId = rawMessage.messageId ? `gift:${rawMessage.messageId}` : "";
  if ((messageId && state.recentGiftIds.includes(messageId)) || state.recentGiftIds.includes(correlationId)) return;
  state.recentGiftIds = [...state.recentGiftIds, messageId, correlationId].filter(Boolean).slice(-MAX_EVENT_IDS);
  const { participant } = updateParticipant(state, rawMessage, author);
  if (participant) {
    participant.giftEventCount += 1;
    participant.giftItemCount += count;
  }
  const settings = await getSettings();
  const systemSpeechText = settings.gameModeEnabled ? core.gameEventSpeech(rawMessage) : "";
  if (systemSpeechText) {
    const receivedAtUtc = rawMessage.receivedAtUtc || new Date().toISOString();
    state.chatMessages = [...(state.chatMessages || []), {
      messageId: rawMessage.messageId ? `game:${rawMessage.messageId}` : null,
      author: "System",
      content: systemSpeechText,
      systemSpeechText,
      userId: null,
      displayId: "",
      participantKey: "",
      muted: false,
      contentLanguage: "de",
      source: "game-mode",
      receivedAtUtc,
      dedupeKey: `game-mode:${core.normalizedIdentity(author)}:${core.normalizedIdentity(systemSpeechText)}:${timeBucket}`
    }].slice(-MAX_CHAT);
  }
  await setState(tabId, state);
  await relayToEmbedTab(tabId, state, "gift", rawMessage);
}

function greaterNumericString(current, incoming) {
  if (incoming == null) return current;
  if (current == null) return incoming;
  try { return BigInt(incoming) >= BigInt(current) ? incoming : current; }
  catch (_) { return incoming; }
}

async function addLiveEvent(tabId, liveEvent) {
  const state = await getState(tabId);
  const stats = { ...emptyState().liveStats, ...(state.liveStats || {}) };
  const eventId = liveEvent.messageId ? `${liveEvent.method}:${liveEvent.messageId}` : null;
  if (eventId && stats.recentEventIds.includes(eventId)) return;

  if (liveEvent.method === "WebcastRoomUserSeqMessage") {
    if (liveEvent.viewerCount != null) stats.viewerCount = liveEvent.viewerCount;
    if (liveEvent.totalViewers != null) stats.totalViewers = greaterNumericString(stats.totalViewers, liveEvent.totalViewers);
  } else if (liveEvent.method === "WebcastLikeMessage") {
    stats.likeCount = greaterNumericString(stats.likeCount, liveEvent.likeCount);
  } else if (liveEvent.method === "WebcastSocialMessage") {
    if (liveEvent.kind === "follow") stats.followEvents += 1;
    if (liveEvent.kind === "share") stats.shareEvents += 1;
    stats.followerCount = greaterNumericString(stats.followerCount, liveEvent.followerCount);
    stats.shareCount = greaterNumericString(stats.shareCount, liveEvent.shareCount);
  }
  if (eventId) stats.recentEventIds = [...stats.recentEventIds, eventId].slice(-MAX_EVENT_IDS);
  stats.lastUpdatedUtc = liveEvent.receivedAtUtc || new Date().toISOString();
  state.liveStats = stats;
  await setState(tabId, state);
  await relayToEmbedTab(tabId, state, "live", liveEvent);
}

async function injectTabRuntime(tabId) {
  const tab = await chrome.tabs.get(tabId);
  if (!tab.url?.startsWith("https://www.tiktok.com/")) throw new Error("Der Tab ist kein TikTok-Tab.");
  const injection = {
    target: { tabId },
    files: ["popup-guard.js", "proto-main.js", "hook-recovery.js", "hook.js"],
    world: "MAIN",
    injectImmediately: true
  };
  try {
    await chrome.scripting.executeScript(injection);
  } catch (error) {
    if (!/injectImmediately|unexpected property/i.test(String(error?.message || error))) throw error;
    delete injection.injectImmediately;
    await chrome.scripting.executeScript(injection);
  }
}

async function removeLegacyGlobalHook() {
  const existing = await chrome.scripting.getRegisteredContentScripts({ ids: [LEGACY_HOOK_SCRIPT_ID] });
  if (existing.length) await chrome.scripting.unregisterContentScripts({ ids: [LEGACY_HOOK_SCRIPT_ID] });
}

async function setHookFlag(tabId, enabled) {
  let tab = null;
  if (Number.isInteger(tabId) && tabId >= 0) tab = await chrome.tabs.get(tabId).catch(() => null);
  if (!tab?.url?.startsWith("https://www.tiktok.com/")) {
    return { armed: Boolean(enabled), waitingForTikTok: Boolean(enabled), reloading: false };
  }
  const state = await getState(tab.id);
  const previousState = structuredClone(state);
  state.enabled = true;
  if (!state.browserSessionId) state.browserSessionId = newBrowserSessionId();
  state.hook = { armed: enabled, installed: false, connected: false, lastError: null };
  if (enabled) state.liveStats = emptyState().liveStats;
  await setState(tab.id, state);
  try { await chrome.tabs.reload(tab.id); }
  catch (error) { await setState(tab.id, previousState); throw error; }
  return { armed: Boolean(enabled), waitingForTikTok: Boolean(enabled), reloading: true, tabId: tab.id };
}

async function resetTabWithHook(tabId) {
  const tab = await chrome.tabs.get(tabId);
  if (!tab.url?.startsWith("https://www.tiktok.com/")) throw new Error("Der aktive Tab ist kein TikTok-Tab.");
  const state = emptyState();
  state.enabled = true;
  state.browserSessionId = newBrowserSessionId();
  state.page = { url: tab.url, title: tab.title || "", scannedAtUtc: null };
  state.hook.armed = true;
  await setState(tabId, state);
  await chrome.tabs.reload(tabId, { bypassCache: true });
  return { replaced: false, tabId, browserSessionId: state.browserSessionId };
}

function waitForTabComplete(tabId, expectedPrefix, timeoutMs = 12000) {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      chrome.tabs.onUpdated.removeListener(listener);
      reject(new Error("Zeitüberschreitung beim Laden der Profilseite."));
    }, timeoutMs);
    const listener = (updatedTabId, changeInfo, tab) => {
      if (updatedTabId !== tabId || changeInfo.status !== "complete" || !String(tab.url || "").startsWith(expectedPrefix)) return;
      clearTimeout(timeout);
      chrome.tabs.onUpdated.removeListener(listener);
      resolve(tab);
    };
    chrome.tabs.onUpdated.addListener(listener);
  });
}

async function forceProfileRefresh(tabId) {
  const tab = await chrome.tabs.get(tabId);
  const liveUrl = tab.url || "";
  const match = liveUrl.match(/^https:\/\/www\.tiktok\.com\/@([^/?#]+)\/live\/?/i) || liveUrl.match(/^https:\/\/www\.tiktok\.com\/embed\/live\/@?([^/?#]+)/i);
  if (!match) throw new Error("Force ist nur auf einer TikTok-LIVE-URL verfügbar.");
  const targetHandle = normalizeHandle(match[1]);
  const profileUrl = `https://www.tiktok.com/@${targetHandle}`;
  let profileResult = null;
  try {
    const profileLoaded = waitForTabComplete(tabId, profileUrl);
    await chrome.tabs.update(tabId, { url: profileUrl });
    await profileLoaded;
    profileResult = await chrome.tabs.sendMessage(tabId, { type: "TLC_SCAN" });
    if (!profileResult?.profileInfo?.present) throw new Error("Die vollständig geladene Profilseite lieferte keine Profilwerte.");
    if (!profileMatchesHandle(profileResult.profileInfo, targetHandle)) throw new Error("Die Profilseite lieferte Werte für einen anderen Stream.");
    await cacheProfile(profileResult.profileInfo);
    const state = await getState(tabId);
    resetPageIdentityIfChanged(state, targetHandle);
    applyStreamIdentity(state, { handle: targetHandle });
    state.profileInfo = mergeProfile({ ...core.EMPTY_PROFILE_INFO }, profileResult.profileInfo);
    if (state.profileInfo?.followerCount != null) state.liveStats.followerCount = state.profileInfo.followerCount;
    await setState(tabId, state);
    return { activated: true, profileInfo: profileResult.profileInfo };
  } finally {
    await chrome.tabs.update(tabId, { url: liveUrl }).catch(() => {});
    const state = await getState(tabId);
    state.enabled = true;
    if (!state.browserSessionId) state.browserSessionId = newBrowserSessionId();
    applyStreamIdentity(state, { handle: targetHandle });
    state.hook = { ...state.hook, armed: true, lastError: null };
    await setState(tabId, state);
    await injectTabRuntime(tabId).catch(() => {});
  }
}

function embedLiveUrl(handle) {
  return `https://www.tiktok.com/embed/live/@${encodeURIComponent(handle)}`;
}

function normalLiveUrl(handle) {
  return `https://www.tiktok.com/@${encodeURIComponent(handle)}/live`;
}

async function getEmbedSession(tabId) {
  const key = `tlc-embed-${tabId}`;
  return (await chrome.storage.session.get(key))[key] || null;
}

async function restoreEmbedDeadlines() {
  const stored = await chrome.storage.session.get(null);
  for (const key of Object.keys(stored)) {
    const match = /^tlc-embed-(\d+)$/.exec(key);
    if (!match) continue;
    const tabId = Number(match[1]);
    await enqueueLiveMode(tabId, "restore-embed-deadline", async () => {
      const session = await getEmbedSession(tabId);
      if (!session || !["loading", "retry-wait"].includes(session.phase) || !Number.isFinite(session.startedAtMs)) return;
      await chrome.alarms.create(`tlc-embed-deadline-${tabId}`, {
        when: Math.max(Date.now() + 1, session.startedAtMs + 90000)
      });
    });
  }
}

async function saveEmbedSession(tabId, session) {
  await chrome.storage.session.set({ [`tlc-embed-${tabId}`]: session });
  const alarmName = `tlc-embed-deadline-${tabId}`;
  if (["loading", "retry-wait"].includes(session.phase)) {
    await chrome.alarms.create(alarmName, { when: session.startedAtMs + 90000 });
  } else {
    await chrome.alarms.clear(alarmName);
  }
  const state = await getState(tabId);
  chrome.runtime.sendMessage({ type: "TLC_STATE_UPDATED", tabId, state: { ...state, embedStartup: session } }).catch(() => {});
}

chrome.alarms.onAlarm.addListener((alarm) => {
  const match = /^tlc-embed-deadline-(\d+)$/.exec(alarm.name);
  if (!match) return;
  const tabId = Number(match[1]);
  return enqueueLiveMode(tabId, "embed-deadline", async () => {
    const session = await getEmbedSession(tabId);
    if (!session || !["loading", "retry-wait"].includes(session.phase)) return;
    if (Date.now() < session.startedAtMs + 90000) {
      await chrome.alarms.create(alarm.name, { when: session.startedAtMs + 90000 });
      return;
    }
    const tab = await chrome.tabs.get(tabId).catch(() => null);
    if (!sameLiveUrl(tab?.url, embedLiveUrl(session.handle))) {
      await cancelEmbedSession(tabId);
      return;
    }
    const expired = { ...session, phase: "failed", reason: "timeout", nextAttemptAtMs: null, completedAtMs: Date.now() };
    await saveEmbedSession(tabId, expired);
    await addDebug(tabId, "embed-startup", { embedStartup: expired });
  }).catch(() => {});
});

async function cancelEmbedSession(tabId) {
  const session = await getEmbedSession(tabId);
  if (session) await saveEmbedSession(tabId, { ...session, phase: "cancelled", nextAttemptAtMs: null, completedAtMs: Date.now() });
}

async function observeEmbedStartup(tabId, observation) {
  const session = await getEmbedSession(tabId);
  if (!session) return null;
  const tab = await chrome.tabs.get(tabId).catch(() => null);
  if (!sameLiveUrl(tab?.url, embedLiveUrl(session.handle))) {
    await cancelEmbedSession(tabId);
    return getEmbedSession(tabId);
  }
  if (!/^[a-f0-9-]{36}$/i.test(String(observation?.documentId || "")) || observation.documentStartedAtMs > Date.now() + 1000) return session;
  const result = core.advanceEmbedSession(session, observation, Date.now());
  if (JSON.stringify(session) !== JSON.stringify(result.session)) {
    await saveEmbedSession(tabId, result.session);
    await addDebug(tabId, "embed-startup", { embedStartup: result.session });
  }
  if (result.action === "reload") {
    try { await chrome.tabs.reload(tabId); }
    catch {
      result.session = { ...result.session, phase: "failed", reason: "navigation-error", completedAtMs: Date.now() };
      await saveEmbedSession(tabId, result.session);
      await addDebug(tabId, "embed-startup", { embedStartup: result.session });
    }
  }
  return result.session;
}

async function armLiveTab(tabId, handle, patch = {}) {
  const state = await getState(tabId);
  state.enabled = true;
  if (!state.browserSessionId) state.browserSessionId = newBrowserSessionId();
  state.hook = { ...state.hook, armed: true, lastError: null };
  state.stream = { ...state.stream, handle: String(handle || state.stream?.handle || "").toLocaleLowerCase() };
  Object.assign(state, patch);
  await setState(tabId, state);
  return state;
}

async function closeEmbedChatSource(tabId, state = null) {
  const current = state || await getState(tabId);
  const sourceTabId = current.chatSourceTabId;
  if (!Number.isInteger(sourceTabId) || sourceTabId < 0 || sourceTabId === tabId) return;
  // Ownership inspection must not initialize or migrate an unrelated tab.
  const sourceState = (await chrome.storage.session.get(stateKey(sourceTabId)))[stateKey(sourceTabId)];
  current.chatSourceTabId = null;
  await setState(tabId, current).catch(() => {});
  const sourceTab = await chrome.tabs.get(sourceTabId).catch(() => null);
  if (sourceState?.chatTargetTabId === tabId && sourceState.chatSourceOnly &&
      sameLiveUrl(sourceTab?.url, normalLiveUrl(sourceState.stream?.handle))) {
    await chrome.tabs.remove(sourceTabId).catch(() => {});
  }
}

function sameLiveUrl(actual, expected) {
  try {
    const a = new URL(actual);
    const b = new URL(expected);
    return a.origin === b.origin && a.pathname.replace(/\/$/, "") === b.pathname.replace(/\/$/, "");
  } catch { return false; }
}

async function ensureEmbedChatSource(embedTabId, handle) {
  const embedState = await getState(embedTabId);
  const expectedUrl = normalLiveUrl(handle);
  const existingId = embedState.chatSourceTabId;
  let sourceTab = Number.isInteger(existingId) && existingId >= 0 && existingId !== embedTabId
    ? await chrome.tabs.get(existingId).catch(() => null)
    : null;
  const sourceState = sourceTab
    ? (await chrome.storage.session.get(stateKey(sourceTab.id)))[stateKey(sourceTab.id)] : null;
  const reusable = sourceState?.chatSourceOnly && sourceState.chatTargetTabId === embedTabId &&
    sameLiveUrl(sourceTab?.url, expectedUrl);
  if (!reusable) {
    await closeEmbedChatSource(embedTabId, embedState);
    sourceTab = await chrome.tabs.create({ url: expectedUrl, active: false, openerTabId: embedTabId });
  }
  await armLiveTab(sourceTab.id, handle, { chatTargetTabId: embedTabId, chatSourceOnly: true });
  await armLiveTab(embedTabId, handle, { chatSourceTabId: sourceTab.id, chatSourceOnly: false });
  await injectTabRuntime(sourceTab.id).catch(() => {});
  return { sourceTab, created: !reusable };
}

async function cancelRecoveryForModeChange(tabId) {
  await enqueueTabEvent(tabId, async () => {
    const state = await getState(tabId);
    const attempt = state.recovery?.attempt;
    if (!attempt || attempt.completedAtMs != null || attempt.endedAtMs != null || attempt.outcome === "reload-failed") return;
    state.recovery.attempt = { ...attempt, outcome: "cancelled", endedAtMs: Date.now() };
    await setState(tabId, state);
    await addDebug(tabId, "reconnect-cancelled", { recoveryAttempt: state.recovery.attempt });
  });
}

async function boundedRecoveryPreflight(tabId, reason) {
  let timeout;
  try {
    return await Promise.race([
      chrome.tabs.sendMessage(tabId, { type: "TLC_RECOVERY_PREFLIGHT", reason }).catch(() => null),
      new Promise((resolve) => { timeout = setTimeout(() => resolve(null), 2000); })
    ]);
  } finally {
    clearTimeout(timeout);
  }
}

async function openEmbedLive(tabId) {
  const tab = await chrome.tabs.get(tabId);
  if (!tab.url?.startsWith("https://www.tiktok.com/")) throw new Error("Der aktive Tab ist kein TikTok-Tab.");
  const state = await getState(tabId);
  const urlHandle = pageHandle({ url: tab.url });
  const handle = urlHandle || pageHandle(state.page) || state.stream?.handle;
  if (!handle) throw new Error("Für diesen Tab wurde kein LIVE-Handle gefunden.");
  const startup = await getEmbedSession(tabId);
  await cancelRecoveryForModeChange(tabId);
  if (startup?.handle === handle && ["loading", "retry-wait", "awaiting-gesture"].includes(startup.phase) &&
      sameLiveUrl(tab.url, embedLiveUrl(handle))) {
    return { activated: false, phase: startup.phase, reloading: false, tabId, handle };
  }
  const pairing = await ensureEmbedChatSource(tabId, handle);
  if (sameLiveUrl(tab.url, embedLiveUrl(handle))) {
    const current = await chrome.tabs.sendMessage(tabId, { type: "TLC_GET_PLAYER_STATE" }).catch(() => null);
    if (current?.playerState?.videoAvailable && current.playerState.playing) {
      return { activated: true, phase: "playing", reloading: false, tabId, handle };
    }
  }
  const session = core.newEmbedSession(newBrowserSessionId(), handle, Date.now());
  await saveEmbedSession(tabId, session);
  await addDebug(tabId, "embed-startup", { embedStartup: session });
  try {
    await chrome.tabs.update(tabId, { url: embedLiveUrl(handle) });
  } catch (error) {
    await saveEmbedSession(tabId, { ...session, phase: "failed", reason: "navigation-error", completedAtMs: Date.now() });
    if (pairing.created) await closeEmbedChatSource(tabId);
    throw error;
  }
  // Navigation acceptance is not evidence that TikTok's player is ready.
  return { activated: false, phase: "loading", reloading: true, tabId, handle };
}

async function openNormalLive(tabId) {
  const tab = await chrome.tabs.get(tabId);
  if (!tab.url?.startsWith("https://www.tiktok.com/")) throw new Error("Der aktive Tab ist kein TikTok-Tab.");
  const state = await getState(tabId);
  const urlHandle = pageHandle({ url: tab.url });
  const handle = urlHandle || pageHandle(state.page) || state.stream?.handle || state.profileInfo?.uniqueId;
  if (!handle) throw new Error("Für diesen Tab wurde kein LIVE-Handle gefunden.");
  await cancelEmbedSession(tabId);
  await cancelRecoveryForModeChange(tabId);
  await closeEmbedChatSource(tabId);
  await armLiveTab(tabId, handle, { chatSourceTabId: null, chatTargetTabId: null, chatSourceOnly: false });
  // The VLC replacement lives at the normal URL too. Navigation tears down
  // its media elements and audio routing even when the URL is unchanged.
  const reloading = true;
  await chrome.tabs.update(tabId, { url: normalLiveUrl(handle) });
  return { activated: false, phase: "loading", reloading, tabId, handle };
}

chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: true }).catch(() => {});

chrome.runtime.onInstalled.addListener(() => {
  chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: true }).catch(() => {});
  removeLegacyGlobalHook().catch(() => {});
});

chrome.runtime.onStartup.addListener(() => {
  removeLegacyGlobalHook().catch(() => {});
});

// Service-worker wakeups do not emit runtime.onStartup. Session storage survives
// them, so restore each deadline without navigating or starting another attempt.
restoreEmbedDeadlines().catch(() => {});

chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (!tab.url) return;
  const isTikTok = tab.url.startsWith("https://www.tiktok.com/");
  chrome.sidePanel.setOptions({
    tabId,
    path: "sidepanel.html",
    enabled: true
  }).catch(() => {});
  if (changeInfo.url && isTikTok) {
    handleLiveTabUrlChange(tabId, changeInfo.url, tab.title || "").catch(() => {});
  }
  if (changeInfo.status === "loading" && isTikTok) {
    getState(tabId).then(async (state) => {
      const shouldArm = Boolean(state.hook.armed);
      if (!shouldArm) return;
      state.enabled = true;
      if (!state.browserSessionId) state.browserSessionId = newBrowserSessionId();
      state.hook = { ...state.hook, armed: true, lastError: null };
      await setState(tabId, state);
      await injectTabRuntime(tabId);
      const refreshedState = await getState(tabId);
      refreshedState.hook = { ...refreshedState.hook, armed: true, lastError: null };
      await setState(tabId, refreshedState);
    }).catch(() => {});
  }
  if (changeInfo.status === "loading") {
    patchState(tabId, { page: { url: tab.url, title: tab.title || "", scannedAtUtc: null } }).catch(() => {});
  }
  if (changeInfo.status === "complete" && isTikTok) {
    getState(tabId).then(async (state) => {
      if (!state.enabled) return;
      const settings = await getSettings();
      return chrome.tabs.sendMessage(tabId, {
        type: "TLC_SET_TAB_ACTIVE",
        enabled: true,
        debugEnabled: Boolean(state.debug?.enabled),
        quickRecoverEnabled: Boolean(state.quickRecoverEnabled),
        quickRecoverSeconds: state.quickRecoverSeconds,
        chatSourceOnly: Boolean(state.chatSourceOnly)
      });
    }).catch(() => {});
  }
});

chrome.tabs.onRemoved.addListener((tabId) => {
  TLCPipelines.publish(tabId, 'browser-tab', { closed: true }, null, 'tab-closed').finally(() => chrome.storage.session.remove(`pipelineTab:${tabId}`)).catch(() => {});
  liveModeGenerations.delete(tabId);
  pendingModeRequests.delete(tabId);
  chrome.alarms.clear(`tlc-embed-deadline-${tabId}`).catch(() => {});
  sendOffscreen({ type: "TLC_OFFSCREEN_CANCEL", tabId }).catch(() => {});
  getState(tabId).then((state) => {
    return closeEmbedChatSource(tabId, state);
  }).catch(() => {}).finally(() => {
    chrome.storage.session.remove(stateKey(tabId)).catch(() => {});
    chrome.storage.session.remove(`tlc-embed-${tabId}`).catch(() => {});
  });
});

chrome.webRequest.onBeforeRequest.addListener(
  (details) => {
    if (details.tabId >= 0) {
      enqueueTabEvent(details.tabId, async () => {
        const state = await getState(details.tabId);
        if (state.enabled) await addMedia(details.tabId, [details.url], "network");
      }).catch(() => {});
    }
  },
  {
    urls: [
      "*://*.tiktokcdn.com/*",
      "*://*.tiktokcdn-eu.com/*",
      "*://*.tiktokcdn-us.com/*",
      "*://*.tiktokcdn-in.com/*",
      "*://*.ttlivecdn.com/*"
    ],
    types: ["media", "xmlhttprequest", "other"]
  }
);

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  TLCPipelines.message(message, sender).catch(() => {});
  const tabId = message.tabId ?? sender.tab?.id;
  const isModeRequest = ["TLC_OPEN_EMBED_LIVE", "TLC_OPEN_NORMAL_LIVE"].includes(message.type);
  if (isModeRequest) {
    liveModeGenerations.set(tabId, (liveModeGenerations.get(tabId) || 0) + 1);
    pendingModeRequests.set(tabId, (pendingModeRequests.get(tabId) || 0) + 1);
  }
  const modeGeneration = liveModeGenerations.get(tabId) || 0;
  const modePendingAtReceipt = (pendingModeRequests.get(tabId) || 0) > 0;
  let modeRequestReleased = false;
  const releaseModeRequest = () => {
    if (!isModeRequest || modeRequestReleased) return;
    modeRequestReleased = true;
    const remaining = (pendingModeRequests.get(tabId) || 0) - 1;
    if (remaining > 0) pendingModeRequests.set(tabId, remaining);
    else pendingModeRequests.delete(tabId);
  };
  const respond = sendResponse;
  sendResponse = (response) => { releaseModeRequest(); respond(response); };
  const handleMessage = async () => {
    if (sender.tab && Number.isInteger(tabId) && message?.type !== "TLC_DEBUG_EVENT") {
      await addDebug(tabId, `raw:${String(message?.type || "unknown")}`, message || {});
    }
    switch (message.type) {
      case "TLC_GET_STATE":
        {
          const state = await getState(tabId);
          const cached = await cachedProfile(pageHandle(state.page));
          if (cached) {
            state.profileInfo = mergeProfile(state.profileInfo, cached);
            if (state.profileInfo?.followerCount != null) state.liveStats.followerCount = state.profileInfo.followerCount;
          }
          mergeStreamSnapshot(state, await cachedStreamSnapshot(pageHandle(state.page) || state.stream?.handle));
          state.embedStartup = await getEmbedSession(tabId);
          sendResponse({ ok: true, state });
        }
        break;
      case "TLC_GET_CAPTION_JSONL_EXPORT":
      case "TLC_GET_CAPTION_RAW_EXPORT": {
        const state = await getState(tabId);
        const settings = await getSettings();
        const secrets = [settings.pairingCode, settings.auddApiToken, settings.universalCaptionApiKey];
        sendResponse({
          ok: true,
          ...(message.type === "TLC_GET_CAPTION_JSONL_EXPORT"
            ? { records: exportPrivacy.captions(state.captions, secrets) }
            : { report: exportPrivacy.captionReport(buildCaptionRawExport(state, tabId, Boolean(settings.universalCaptionApiKey)), secrets) })
        });
        break;
      }
      case "TLC_ACTIVATE_TAB": {
        const state = await getState(tabId);
        const settings = await getSettings();
        state.enabled = true;
        if (!state.browserSessionId) state.browserSessionId = newBrowserSessionId();
        await setState(tabId, state);
        await chrome.tabs.sendMessage(tabId, {
          type: "TLC_SET_TAB_ACTIVE",
          enabled: true,
          debugEnabled: Boolean(state.debug?.enabled),
          quickRecoverEnabled: Boolean(state.quickRecoverEnabled),
          quickRecoverSeconds: state.quickRecoverSeconds,
          chatSourceOnly: Boolean(state.chatSourceOnly)
        }).catch(() => {});
        sendResponse({ ok: true, state });
        break;
      }
      case "TLC_GET_TAB_ACTIVATION": {
        const state = await getState(tabId);
        sendResponse({ ok: true, enabled: Boolean(state.enabled), hookReconnect: state.hookReconnect,
          hookArmed: Boolean(state.hook.armed), quickRecoverEnabled: state.quickRecoverEnabled,
          quickRecoverSeconds: state.quickRecoverSeconds, debugEnabled: Boolean(state.debug?.enabled) });
        break;
      }
      case "TLC_GET_SETTINGS": {
        const settings = await getSettings();
        const state = Number.isInteger(tabId) && tabId >= 0 ? await getState(tabId) : emptyState();
        sendResponse({ ok: true, settings: {
          ...settings,
          hookEnabled: Boolean(state.hook?.armed),
          autoHook: Boolean(state.hook?.armed),
          quickRecoverEnabled: Boolean(state.quickRecoverEnabled),
          quickRecoverSeconds: state.quickRecoverSeconds,
          speechEnabled: Boolean(state.speech?.enabled),
          debugEnabled: Boolean(state.debug?.enabled)
        } });
        break;
      }
      case "TLC_INSTALL_LOCAL_SERVICE": {
        const nonce = String(message.nonce || "");
        if (!/^[A-Za-z0-9_-]{32,128}$/.test(nonce)) throw new Error("Der Installations-Nonce ist ungültig.");
        await chrome.storage.session.set({
          [SERVICE_INSTALL_KEY]: { nonce, startedAt: Date.now() }
        });
        sendResponse({ ok: true, installationStarted: true });
        break;
      }
      case "TLC_POLL_LOCAL_SERVICE_INSTALL": {
        const stored = await chrome.storage.session.get(SERVICE_INSTALL_KEY);
        const pending = stored[SERVICE_INSTALL_KEY];
        const nonce = String(pending?.nonce || "");
        const settings = await getSettings();
        const serviceUrl = loopbackServiceUrl(settings.serviceUrl) || "http://127.0.0.1:43117";
        const knownPairingCode = String(settings.pairingCode || "");
        if (knownPairingCode) {
          const healthResponse = await fetch(`${serviceUrl}/v1/health`, {
            headers: { Authorization: `Bearer ${knownPairingCode}` }
          }).catch(() => null);
          if (healthResponse?.ok) {
            await chrome.storage.session.remove(SERVICE_INSTALL_KEY);
            sendResponse({ ok: true, pending: false, pairingCode: knownPairingCode });
            break;
          }
        }
        if (!nonce || Date.now() - Number(pending?.startedAt || 0) > 120000) {
          await chrome.storage.session.remove(SERVICE_INSTALL_KEY);
          sendResponse({ ok: true, pending: false, pairingCode: "" });
          break;
        }
        const response = await fetch(`${serviceUrl}/v1/pair?nonce=${encodeURIComponent(nonce)}`).catch(() => null);
        if (!response?.ok) {
          sendResponse({ ok: true, pending: true, pairingCode: "" });
          break;
        }
        const payload = await response.json().catch(() => ({}));
        const pairingCode = String(payload.pairingCode || "");
        if (!pairingCode) {
          sendResponse({ ok: true, pending: true, pairingCode: "" });
          break;
        }
        await setSettings({ pairingCode });
        await chrome.storage.session.remove(SERVICE_INSTALL_KEY);
        sendResponse({ ok: true, pending: false, pairingCode });
        break;
      }
      case "TLC_START_LOCAL_SERVICE": {
        const settings = await getSettings();
        const nonce = String(message.nonce || "");
        if (!/^[A-Za-z0-9_-]{32,128}$/.test(nonce)) throw new Error("Der Start-Nonce ist ungültig.");
        const serviceUrl = loopbackServiceUrl(settings.serviceUrl) || "http://127.0.0.1:43117";
        let pairingCode = "";
        const attempts = 10;
        for (let attempt = 0; attempt < attempts && !pairingCode; attempt += 1) {
          await new Promise((resolve) => setTimeout(resolve, 400));
          const response = await fetch(`${serviceUrl}/v1/pair?nonce=${encodeURIComponent(nonce)}`).catch(() => null);
          if (!response?.ok) continue;
          const payload = await response.json().catch(() => ({}));
          pairingCode = String(payload.pairingCode || "");
        }
        if (pairingCode) await setSettings({ pairingCode });
        sendResponse({
          ok: true,
          pairingCode,
          setupRequired: !pairingCode,
          installationStarted: false
        });
        break;
      }
      case "TLC_SET_AUTOSTART": {
        const result = await setHookFlag(tabId, Boolean(message.enabled));
        sendResponse({ ok: true, reloading: Boolean(result.reloading), result });
        break;
      }
      case "TLC_SET_QUICK_RECOVER": {
        const state = await getState(tabId);
        const seconds = normalizeRecoveryDelay(message.seconds);
        state.quickRecoverEnabled = Boolean(message.enabled);
        state.quickRecoverSeconds = seconds;
        state.recoveryConfigVersion = 1;
        await setState(tabId, state);
        if (Number.isInteger(tabId) && tabId >= 0) {
          await chrome.tabs.sendMessage(tabId, { type: "TLC_QUICK_RECOVER_CONFIG", enabled: state.quickRecoverEnabled, seconds }).catch(() => {});
        }
        sendResponse({ ok: true, state, seconds });
        break;
      }
      case "TLC_SET_SPEECH_PREFERENCE": {
        const settings = await setSettings({
          ...(message.enabled == null ? {} : { keepSpeechActive: Boolean(message.enabled) }),
          ...(message.volume == null ? {} : { speechVolume: Math.max(0, Math.min(1, Number(message.volume))) }),
          ...(message.language == null ? {} : { speechLanguage: message.language === "auto" || /^[a-z]{2,3}(?:-[A-Z]{2})?$/.test(String(message.language)) ? String(message.language) : "auto" }),
          ...(message.voiceName == null ? {} : { speechVoiceName: String(message.voiceName).slice(0, 160) }),
          ...(message.auddApiToken == null ? {} : { auddApiToken: String(message.auddApiToken).trim().slice(0, 512) }),
          ...(message.universalCaptionApiKey == null ? {} : { universalCaptionApiKey: String(message.universalCaptionApiKey).trim().slice(0, 512) }),
          ...(message.filterExternalSpeechTriggers == null ? {} : { filterExternalSpeechTriggers: Boolean(message.filterExternalSpeechTriggers) }),
          ...(message.gameModeEnabled == null ? {} : { gameModeEnabled: Boolean(message.gameModeEnabled) }),
          ...(message.speakNames == null ? {} : { speakNames: Boolean(message.speakNames) }),
          ...(message.shortenNames == null ? {} : { shortenNames: Boolean(message.shortenNames) }),
          ...(message.autoChatRefreshEnabled == null ? {} : { autoChatRefreshEnabled: Boolean(message.autoChatRefreshEnabled) }),
          ...(message.autoChatRefreshMinutes == null ? {} : { autoChatRefreshMinutes: Math.max(1, Math.min(60, Math.round(Number(message.autoChatRefreshMinutes) || 5))) }),
          ...(message.pairingCode == null ? {} : { pairingCode: String(message.pairingCode) }),
          ...(message.songRecognitionEnabled == null ? {} : { songRecognitionEnabled: Boolean(message.songRecognitionEnabled) })
        });
        sendResponse({ ok: true, settings });
        break;
      }
      case "TLC_SET_TAB_SPEECH": {
        const state = await getState(tabId);
        state.speech = {
          ...state.speech,
          enabled: Boolean(message.enabled),
          status: message.enabled ? "Vorlesen ist aktiv; warte auf neue Chatzeilen." : "Vorlesen ist ausgeschaltet.",
          queueDepth: message.enabled ? Number(state.speech?.queueDepth || 0) : 0
        };
        await setState(tabId, state);
        if (!message.enabled) await sendOffscreen({ type: "TLC_OFFSCREEN_CANCEL", tabId }).catch(() => {});
        sendResponse({ ok: true, state });
        break;
      }
      case "TLC_OFFSCREEN_STATUS": {
        if (sender.url !== chrome.runtime.getURL("offscreen.html")) throw new Error("Ungültiger Absender für Offscreen-Status.");
        const speechTabId = Number(message.tabId);
        if (Number.isInteger(speechTabId) && speechTabId >= 0) {
          const state = await getState(speechTabId);
          state.speech = {
            ...state.speech,
            status: String(message.status || state.speech?.status || "").slice(0, 300),
            queueDepth: Math.max(0, Math.min(5, Number(message.queueDepth || 0)))
          };
          await setState(speechTabId, state);
        }
        sendResponse({ ok: true });
        break;
      }
      case "TLC_PAGE_STATE": {
        const state = await getState(tabId);
        const nextHandle = pageStateHandle(state, message);
        resetPageIdentityIfChanged(state, nextHandle);
        state.page = message.page || state.page;
        applyStreamIdentity(state, { handle: nextHandle || pageHandle(state.page) });
        const checkedAtUtc = new Date().toISOString();
        if (message.captionInfo) state.captionSources.metadata = {
          ...core.normalizeCaptionInfo(message.captionInfo), lastCheckedAtUtc: checkedAtUtc
        };
        state.captionSources.menu = { ...state.captionSources.menu, lastCheckedAtUtc: checkedAtUtc,
          available: Boolean(message.menuCaptionAvailable) };
        if (message.menuCaptionAvailable) Object.assign(state.captionSources.menu, {
          active: Boolean(message.menuCaptionActive), lastObservedAtUtc: checkedAtUtc
        });
        state.captionInfo = core.summarizeCaptionSources(state.captionSources);
        if (profileMatchesHandle(message.profileInfo, nextHandle)) state.profileInfo = mergeProfile(state.profileInfo, message.profileInfo);
        await cacheProfile(state.profileInfo);
        const cached = await cachedProfile(nextHandle || pageHandle(state.page));
        if (cached) state.profileInfo = mergeProfile(state.profileInfo, cached);
        if (state.profileInfo?.followerCount != null) state.liveStats.followerCount = state.profileInfo.followerCount;
        state.liveStats = mergeLiveStats(state.liveStats, message.liveStats);
        mergeStreamSnapshot(state, await cachedStreamSnapshot(nextHandle || pageHandle(state.page) || state.stream?.handle));
        state.aiSummaryInfo = message.aiSummaryInfo || state.aiSummaryInfo;
        state.menuCaptionAvailable = Boolean(message.menuCaptionAvailable);
        state.menuCaptionActive = Boolean(message.menuCaptionAvailable && message.menuCaptionActive);
        await setState(tabId, state);
        await addMedia(tabId, message.media || [], "metadata");
        await addDebug(tabId, "page-state", { profile: state.profileInfo, summary: state.aiSummaryInfo, mediaCount: message.media?.length || 0 });
        sendResponse({ ok: true });
        break;
      }
      case "TLC_MEDIA_FOUND":
        await addMedia(tabId, message.media || [], message.source || "page");
        sendResponse({ ok: true });
        break;
      case "TLC_CAPTION":
        await addCaption(tabId, message.caption);
        sendResponse({ ok: true });
        break;
      case "TLC_CHAT_MESSAGE":
        await addChatMessage(tabId, message.chatMessage || {});
        sendResponse({ ok: true });
        break;
      case "TLC_GIFT_MESSAGE":
        await addGiftMessage(tabId, message.giftMessage || {});
        sendResponse({ ok: true });
        break;
      case "TLC_LIVE_EVENT":
        await addLiveEvent(tabId, message.liveEvent);
        sendResponse({ ok: true });
        break;
      case "TLC_HOOK_STATUS": {
        const state = await getState(tabId);
        state.hook = { ...state.hook, ...message.hook };
        applyStreamIdentity(state, message.hook?.stream || {});
        await setState(tabId, state);
        await addDebug(tabId, "hook-status", message.hook || {});
        sendResponse({ ok: true });
        break;
      }
      case "TLC_SCAN":
      case "TLC_ENABLE_CAPTIONS": {
        const response = await chrome.tabs.sendMessage(tabId, { type: message.type });
        sendResponse({ ok: true, response });
        break;
      }
      case "TLC_REFRESH_PAGE_INFO": {
        const response = await chrome.tabs.sendMessage(tabId, { type: message.type });
        sendResponse({ ok: true, response });
        break;
      }
      case "TLC_SCAN_RECOMMENDATIONS": {
        if (!Number.isInteger(tabId) || tabId < 0) throw new Error("Kein TikTok-Tab ausgewählt.");
        const tab = await chrome.tabs.get(tabId);
        const sourceHandle = core.liveHandleFromUrl(tab.url);
        if (!sourceHandle) throw new Error("Der ausgewählte Tab zeigt keinen TikTok-Livestream.");
        const limit = Math.max(1, Math.min(50, Math.round(Number(message.limit) || 20)));
        const runId = newBrowserSessionId();
        const now = new Date().toISOString();
        const state = await getState(tabId);
        state.recommendationScan = {
          ...emptyRecommendationScan(),
          status: "running",
          runId,
          sourceUrl: String(tab.url || state.page?.url || "").slice(0, 500),
          sourceHandle,
          requested: limit,
          startedAtUtc: now,
          updatedAtUtc: now
        };
        await setState(tabId, state);
        chrome.tabs.sendMessage(tabId, { type: "TLC_SCAN_RECOMMENDATIONS", runId, limit }).catch(async (error) => {
          const latest = await getState(tabId);
          if (latest.recommendationScan?.runId !== runId) return;
          latest.recommendationScan = {
            ...latest.recommendationScan,
            status: "error",
            error: cleanRecommendationText(error?.message || error, 300),
            updatedAtUtc: new Date().toISOString(),
            completedAtUtc: new Date().toISOString()
          };
          await setState(tabId, latest);
        });
        sendResponse({ ok: true, started: true, runId });
        break;
      }
      case "TLC_CANCEL_RECOMMENDATION_SCAN": {
        const state = await getState(tabId);
        const runId = String(message.runId || state.recommendationScan?.runId || "");
        const response = await chrome.tabs.sendMessage(tabId, { type: "TLC_CANCEL_RECOMMENDATION_SCAN", runId }).catch(() => null);
        if (!response?.ok && state.recommendationScan?.status === "running" && state.recommendationScan?.runId === runId) {
          const now = new Date().toISOString();
          state.recommendationScan = { ...state.recommendationScan, status: "cancelled", updatedAtUtc: now, completedAtUtc: now };
          await setState(tabId, state);
        }
        sendResponse({ ok: true, cancelled: true });
        break;
      }
      case "TLC_RECOMMENDATION_SCAN_PROGRESS": {
        if (!Number.isInteger(sender.tab?.id) || sender.tab.id !== tabId) throw new Error("Ungültiger Absender für den Empfehlungs-Scan.");
        const state = await getState(tabId);
        const current = state.recommendationScan || emptyRecommendationScan();
        if (!message.runId || current.runId !== message.runId) {
          sendResponse({ ok: false, stale: true });
          break;
        }
        const status = ["running", "complete", "cancelled", "error"].includes(message.status) ? message.status : "running";
        const items = sanitizeRecommendationItems(message.items, current.requested);
        const now = new Date().toISOString();
        state.recommendationScan = {
          ...current,
          status,
          scanned: Math.max(0, Math.min(current.requested, Math.round(Number(message.scanned) || items.length))),
          found: items.length,
          items,
          updatedAtUtc: now,
          completedAtUtc: status === "running" ? null : now,
          error: status === "error" ? cleanRecommendationText(message.error, 300) : ""
        };
        await setState(tabId, state);
        sendResponse({ ok: true });
        break;
      }
      case "TLC_FORCE_PROFILE": {
        const response = await forceProfileRefresh(tabId);
        sendResponse({ ok: true, response, reloading: true });
        break;
      }
      case "TLC_OPEN_EMBED_LIVE": {
        const response = await enqueueLiveMode(tabId, "embed", () => openEmbedLive(tabId));
        sendResponse({ ok: true, response, reloading: response.reloading });
        break;
      }
      case "TLC_SET_HOOK_RECONNECT": {
        const state = await getState(tabId);
        state.hookReconnect = { enabled: Boolean(message.enabled), seconds: normalizeRecoveryDelay(message.seconds) };
        await setState(tabId, state);
        await chrome.tabs.sendMessage(tabId, { type: "TLC_HOOK_RECONNECT_CONFIG", ...state.hookReconnect,
          armed: Boolean(state.hook.armed) }).catch(() => {});
        sendResponse({ ok: true, state });
        break;
      }
      case "TLC_HOOK_RECOVERY": {
        const state = await getState(tabId);
        // Never persist arbitrary page strings or connection arguments.
        const incoming = exportPrivacy.hookRecovery(message.recovery);
        const previous = state.hookRecovery;
        if (previous?.contentDocumentStartedAtMs &&
            (!incoming.contentDocumentStartedAtMs || incoming.contentDocumentStartedAtMs < previous.contentDocumentStartedAtMs)) {
          sendResponse({ ok: true, ignored: "stale-document" }); break;
        }
        state.hookRecovery = incoming;
        await setState(tabId, state);
        await addDebug(tabId, "hook-recovery", { controller: "hook-reconnect", hookRecovery: state.hookRecovery,
          playerState: state.playerState });
        sendResponse({ ok: true });
        break;
      }
      case "TLC_EMBED_OBSERVATION": {
        const session = await enqueueLiveMode(tabId, "embed-observation", () => observeEmbedStartup(tabId, message.observation));
        sendResponse({ ok: true, phase: session?.phase || "idle" });
        break;
      }
      case "TLC_CANCEL_EMBED_STARTUP": {
        await enqueueLiveMode(tabId, "embed-cancel", () => cancelEmbedSession(tabId));
        sendResponse({ ok: true });
        break;
      }
      case "TLC_OPEN_NORMAL_LIVE": {
        const response = await enqueueLiveMode(tabId, "normal", () => openNormalLive(tabId));
        sendResponse({ ok: true, response, reloading: response.reloading });
        break;
      }
      case "TLC_SET_MUTE": {
        const key = String(message.participantKey || "");
        if (!key) throw new Error("Person konnte nicht zugeordnet werden.");
        const state = await getState(tabId);
        const settings = await getSettings();
        const aliases = participantAliases(state.participants?.[key], key);
        state.streamMutes = (state.streamMutes || []).filter((item) => !aliases.includes(item));
        settings.permanentMutes = (settings.permanentMutes || []).filter((item) => !aliases.includes(item));
        if (message.scope === "stream") state.streamMutes.push(key);
        if (message.scope === "permanent") settings.permanentMutes.push(...aliases);
        await setSettings({ permanentMutes: [...new Set(settings.permanentMutes)] });
        const nextSettings = await getSettings();
        state.chatMessages = (state.chatMessages || []).map((item) => ({
          ...item,
          muted: participantMuted(state, nextSettings, item.participantKey)
        }));
        await setState(tabId, state);
        sendResponse({ ok: true, state, settings: nextSettings });
        break;
      }
      case "TLC_GET_PLAYER_STATE": {
        const response = await chrome.tabs.sendMessage(tabId, { type: message.type });
        if (response?.playerState) await patchState(tabId, { playerState: normalizePlayerState(response.playerState) });
        sendResponse({ ok: true, response });
        break;
      }
      case "TLC_RECOVERY_MEDIA_OBSERVATION": {
        const state = await getState(tabId);
        const attempt = state.recovery?.attempt;
        const tab = await chrome.tabs.get(tabId).catch(() => null);
        if (attempt && sameLiveUrl(tab?.url, normalLiveUrl(attempt.handle))) {
          const next = core.observeRecoveryMedia(attempt, message.observation, Date.now());
          if (next !== attempt) {
            state.recovery.attempt = next;
            await setState(tabId, state);
            await addDebug(tabId, "reconnect-video-progress", { recoveryAttempt: next });
          }
        }
        sendResponse({ ok: true });
        break;
      }
      case "TLC_PLAYER_STATE_PUSH": {
        const playerState = normalizePlayerState(message.playerState || {});
        await patchState(tabId, { playerState });
        await addDebug(tabId, "player-state", { reason: message.reason || null, playerState });
        sendResponse({ ok: true });
        break;
      }
      case "TLC_PLAYER_ACTION": {
        let response;
        try {
          const playerMessage = {
            type: message.type,
            action: message.action,
            value: message.value,
            enabled: message.enabled,
            strength: message.strength,
            thresholdDbfs: message.thresholdDbfs
          };
          if (message.action === "play-vlc-source") {
            const state = await getState(tabId);
            playerMessage.media = state.media || [];
          }
          response = await chrome.tabs.sendMessage(tabId, playerMessage);
        } catch (error) {
          response = { activated: false, action: message.action, reason: String(error?.message || error).slice(0, 500) };
        }
        if (response?.playerState) await patchState(tabId, { playerState: normalizePlayerState(response.playerState) });
        if (message.action === "set-volume" && response?.activated) {
          await setSettings({ playerVolume: Math.max(0, Math.min(100, Math.round(Number(message.value) * 100))) });
        }
        if (message.action === "set-limiter" && response?.activated) {
          await setSettings({
            limiterEnabled: Boolean(message.enabled),
            limiterStrength: message.strength == null ? core.limiterDbfsToStrength(message.thresholdDbfs)
              : Math.max(0, Math.min(100, Number(message.strength) || 0))
          });
        }
        await addDebug(tabId, "player-action", { action: message.action, activated: response?.activated, reason: response?.reason || response?.error || null, playerState: response?.playerState || null });
        sendResponse({ ok: true, response });
        break;
      }
      case "TLC_FULLSCREEN_EXITED": {
        const state = await getState(tabId);
        state.enabled = true;
        await setState(tabId, state);
        await chrome.sidePanel.setOptions({ tabId, path: "sidepanel.html", enabled: true }).catch(() => {});
        if (chrome.sidePanel.open) await chrome.sidePanel.open({ tabId }).catch(() => {});
        sendResponse({ ok: true, state });
        break;
      }
      case "TLC_QUICK_RECOVER": {
        if (modePendingAtReceipt || pendingModeRequests.has(tabId)) {
          await addDebug(tabId, "reconnect-skipped", { reason: "stale-attempt" });
          sendResponse({ ok: true, skipped: true, reason: "stale-attempt" });
          break;
        }
        if (quickRecoverInFlight.has(tabId)) {
          sendResponse({ ok: true, skipped: true, reason: "in-flight" });
          break;
        }
        quickRecoverInFlight.add(tabId);
        try {
          const state = await getState(tabId);
          if (!state.quickRecoverEnabled) {
            sendResponse({ ok: true, skipped: true, reason: "disabled" });
            break;
          }
          const tab = await chrome.tabs.get(tabId).catch(() => null);
          if (!tab?.url?.startsWith("https://www.tiktok.com/")) {
            sendResponse({ ok: true, skipped: true, reason: "not-tiktok" });
            break;
          }
          if (/^\/embed\/live\//i.test(new URL(tab.url).pathname)) {
            sendResponse({ ok: true, skipped: true, reason: "embed-startup-controlled" });
            break;
          }
          const previousAttempt = state.recovery?.attempt;
          if (message.recoveryAttempt?.id && (message.recoveryAttempt.id === previousAttempt?.id ||
              (Number.isFinite(message.recoveryAttempt.requestedAtMs) &&
               message.recoveryAttempt.requestedAtMs < previousAttempt?.startedAtMs))) {
            sendResponse({ ok: true, skipped: true, reason: "stale-attempt" });
            break;
          }
          const preflight = await boundedRecoveryPreflight(tabId, message.reason);
          if (typeof preflight?.shouldReload !== "boolean") {
            await addDebug(tabId, "reconnect-skipped", { reason: "preflight-unavailable" });
            sendResponse({ ok: true, skipped: true, reason: "preflight-unavailable" });
            break;
          }
          const softRecovery = ["play-resumed", "play-unconfirmed"].includes(preflight?.softRecovery) ? preflight.softRecovery : null;
          const currentTab = await chrome.tabs.get(tabId).catch(() => null);
          const changedDocument = message.recoveryAttempt?.documentId && preflight?.documentId &&
            message.recoveryAttempt.documentId !== preflight.documentId;
          const modeChanged = modeGeneration !== (liveModeGenerations.get(tabId) || 0);
          if (modeChanged || !sameLiveUrl(currentTab?.url, tab.url) || changedDocument || preflight?.shouldReload === false) {
            const reason = modeChanged || !sameLiveUrl(currentTab?.url, tab.url) || changedDocument ? "stale-attempt" : "recovered-before-reload";
            if (softRecovery) await addDebug(tabId, "reconnect-soft-recovery", { reason: softRecovery });
            await addDebug(tabId, "reconnect-skipped", { reason });
            sendResponse({ ok: true, skipped: true, reason });
            break;
          }
          state.enabled = true;
          if (!state.browserSessionId) state.browserSessionId = newBrowserSessionId();
          state.hook = { ...state.hook, armed: true, lastError: null };
          state.recovery = { lastQuickRecoverAtUtc: new Date().toISOString(), lastReason: String(message.reason || "").slice(0, 80) };
          const now = Date.now();
          const input = message.recoveryAttempt || {};
          const validTiming = Number.isFinite(input.detectedAtMs) && Number.isFinite(input.scheduledAtMs) &&
            Number.isFinite(input.requestedAtMs) && input.detectedAtMs <= input.scheduledAtMs &&
            input.scheduledAtMs <= input.requestedAtMs && input.requestedAtMs <= now + 1000 &&
            now - input.detectedAtMs <= 120000 && input.configuredDelayMs >= 1000 && input.configuredDelayMs <= 59000 &&
            input.scheduledAtMs - input.detectedAtMs === input.configuredDelayMs;
          const attempt = {
            id: /^[a-f0-9-]{36}$/i.test(input.id || "") ? input.id : newBrowserSessionId(),
            documentId: /^[a-f0-9-]{36}$/i.test(input.documentId || "") ? input.documentId : null,
            detectedAtMs: validTiming ? input.detectedAtMs : null,
            scheduledAtMs: validTiming ? input.scheduledAtMs : null,
            requestedAtMs: validTiming ? input.requestedAtMs : null,
            configuredDelayMs: validTiming ? input.configuredDelayMs : state.quickRecoverSeconds * 1000,
            startedAtMs: now, actualWaitMs: validTiming ? Math.max(0, now - input.detectedAtMs) : null,
            scheduleOverrunMs: validTiming ? Math.max(0, now - input.scheduledAtMs) : null,
            mode: "normal", handle: core.liveHandleFromUrl(tab.url), trigger: state.recovery.lastReason, outcome: "started"
          };
          state.recovery.attempt = attempt;
          await setState(tabId, state);
          if (softRecovery) await addDebug(tabId, "reconnect-soft-recovery", { reason: softRecovery });
          if (previousAttempt && previousAttempt.completedAtMs == null && previousAttempt.endedAtMs == null && previousAttempt.outcome !== "reload-failed") {
            await addDebug(tabId, "reconnect-superseded", { recoveryAttempt: { ...previousAttempt, outcome: "superseded", endedAtMs: now } });
          }
          await addDebug(tabId, "reconnect-attempt-started", { recoveryAttempt: attempt });
          await addDebug(tabId, "quick-recover", { reason: state.recovery.lastReason, url: redactUrl(tab.url || "") });
          try {
            if (modeGeneration !== (liveModeGenerations.get(tabId) || 0)) {
              const cancelled = await getState(tabId);
              cancelled.recovery.attempt = { ...attempt, outcome: "cancelled", endedAtMs: Date.now() };
              await setState(tabId, cancelled);
              await addDebug(tabId, "reconnect-cancelled", { recoveryAttempt: cancelled.recovery.attempt });
              sendResponse({ ok: true, skipped: true, reason: "stale-attempt" });
              break;
            }
            await chrome.tabs.reload(tabId);
            await addDebug(tabId, "reconnect-reload-requested", { recoveryAttempt: { ...attempt, outcome: "reload-requested" } });
          } catch (error) {
            const failedState = await getState(tabId);
            failedState.recovery.attempt = { ...attempt, outcome: "reload-failed" };
            await setState(tabId, failedState);
            await addDebug(tabId, "reconnect-failed", { recoveryAttempt: { ...attempt, outcome: "reload-failed" } });
            throw error;
          }
          sendResponse({ ok: true, reloading: true });
        } finally {
          quickRecoverInFlight.delete(tabId);
        }
        break;
      }
      case "TLC_SET_QUALITY": {
        const response = await chrome.tabs.sendMessage(tabId, {
          type: message.type,
          quality: message.quality,
          sdkKey: message.sdkKey
        });
        if (response?.activated) await patchState(tabId, { selectedQuality: response.quality || message.quality });
        await addDebug(tabId, "quality", { requested: message.quality, sdkKey: message.sdkKey, result: response });
        sendResponse({ ok: true, response });
        break;
      }
      case "TLC_ENABLE_HOOK":
        {
          const result = await setHookFlag(tabId, true);
          sendResponse({ ok: true, reloading: Boolean(result.reloading), result });
        }
        break;
      case "TLC_DISABLE_HOOK":
        {
          const result = await setHookFlag(tabId, false);
          sendResponse({ ok: true, reloading: Boolean(result.reloading), result });
        }
        break;
      case "TLC_RESET_TAB":
        {
          const result = await resetTabWithHook(tabId);
          sendResponse({ ok: true, reloading: true, result });
        }
        break;
      case "TLC_CLEAR":
        {
          const state = await getState(tabId);
          state.media = [];
          state.captions = [];
          state.chatMessages = [];
          state.liveStats = emptyState().liveStats;
          await setState(tabId, state);
        }
        sendResponse({ ok: true });
        break;
      case "TLC_CLEAR_CHAT": {
        const state = await getState(tabId);
        state.chatMessages = [];
        await setState(tabId, state);
        sendResponse({ ok: true });
        break;
      }
      case "TLC_SET_DEBUG": {
        let state = null;
        if (Number.isInteger(tabId) && tabId >= 0) {
          const tab = await chrome.tabs.get(tabId).catch(() => null);
          if (tab?.url?.startsWith("https://www.tiktok.com/")) {
            state = await getState(tabId);
            state.debug = { enabled: Boolean(message.enabled), entries: state.debug?.entries || [] };
            await setState(tabId, state);
            await chrome.tabs.sendMessage(tabId, { type: "TLC_DEBUG_CONFIG", enabled: state.debug.enabled }).catch(() => {});
          }
        }
        sendResponse({ ok: true, state });
        break;
      }
      case "TLC_DEBUG_EVENT": {
        let detail = message.detail || {};
        if (message.event === "socket-telemetry") {
          // Correlation is assigned here, never trusted from a page message.
          const socket = { ...detail.socket, recoveryAttemptId: null };
          const state = await getState(tabId);
          const attempt = state.recovery?.attempt;
          const tab = await chrome.tabs.get(tabId).catch(() => null);
          const now = Date.now();
          if (attempt && attempt.endedAtMs == null && attempt.outcome !== "reload-failed" && socket.mode === "normal" &&
              /^[a-f0-9-]{36}$/i.test(socket.contentDocumentId || "") &&
              socket.contentDocumentId !== attempt.documentId &&
              Number.isFinite(socket.contentDocumentStartedAtMs) &&
              socket.contentDocumentStartedAtMs >= attempt.startedAtMs && socket.contentDocumentStartedAtMs <= now &&
              now - attempt.startedAtMs <= 120000 &&
              (!attempt.playbackDocumentId || attempt.playbackDocumentId === socket.contentDocumentId) &&
              sameLiveUrl(tab?.url, normalLiveUrl(attempt.handle))) {
            socket.recoveryAttemptId = attempt.id;
          }
          detail = { socket };
        }
        await addDebug(tabId, message.event || "content", detail);
        sendResponse({ ok: true });
        break;
      }
      case "TLC_CLEAR_DEBUG": {
        const state = await getState(tabId);
        state.debug.entries = [];
        await setState(tabId, state);
        sendResponse({ ok: true });
        break;
      }
      case "TLC_GET_DEBUG_REPORT": {
        const state = await getState(tabId);
        const settings = await getSettings();
        const pairingCode = String(settings.pairingCode || "");
        const serviceUrl = loopbackServiceUrl(settings.serviceUrl) || "http://127.0.0.1:43117";
        const storedInstall = await chrome.storage.session.get(SERVICE_INSTALL_KEY);
        const pendingInstall = storedInstall[SERVICE_INSTALL_KEY];
        const localService = {
          serviceUrl,
          pairingConfigured: Boolean(pairingCode),
          auddTokenConfigured: Boolean(settings.auddApiToken),
          expectedProtocolHandler: "cmd-primary-powershell-fallback",
          installationPending: Boolean(pendingInstall?.startedAt),
          installationAgeMs: pendingInstall?.startedAt ? Math.max(0, Date.now() - Number(pendingInstall.startedAt)) : null,
          reachable: false,
          healthStatus: null
        };
        if (pairingCode) {
          const healthResponse = await fetch(`${serviceUrl}/v1/health`, {
            headers: { Authorization: `Bearer ${pairingCode}` }
          }).catch(() => null);
          localService.reachable = Boolean(healthResponse?.ok);
          localService.healthStatus = healthResponse?.status || null;
          if (healthResponse?.ok) {
            const health = await healthResponse.json().catch(() => ({}));
            localService.runtime = {
              version: health.version || null,
              tts: health.tts || null,
              ttsAvailable: Boolean(health.ttsAvailable),
              sherpaConfigured: Boolean(health.sherpaConfigured),
              sherpaInstalling: Boolean(health.sherpaInstalling),
              auddConfigured: Boolean(health.auddConfigured),
              songProvider: health.songProvider || null,
              bootstrapPending: Boolean(health.bootstrapPending),
              extensionConfigured: Boolean(health.extensionConfigured)
            };
          }
        }
        const participants = Object.values(state.participants || {});
        const captionSources = [...new Set((state.captions || []).map((item) => String(item?.source || "")).filter(Boolean))].slice(0, 50);
        const captionLanguages = [...new Set((state.captions || []).map((item) => String(item?.language || item?.lang || "")).filter(Boolean))].slice(0, 50);
        sendResponse({ ok: true, report: exportPrivacy.diagnosticReport({
          generatedAtUtc: new Date().toISOString(), version: chrome.runtime.getManifest().version,
          browserSessionId: state.browserSessionId, captionSnapshot: state.captionSnapshot,
          page: state.page, captionInfo: state.captionInfo, captionSources: state.captionSources, profileInfo: state.profileInfo,
          embedStartup: await getEmbedSession(tabId),
          aiSummaryInfo: state.aiSummaryInfo, hook: state.hook, hookRecovery: state.hookRecovery, liveStats: state.liveStats,
          playerState: state.playerState, selectedQuality: state.selectedQuality,
          media: state.media.map((item) => ({ ...item, url: redactUrl(item.url) })),
          counts: { chat: state.chatMessages.length, captions: state.captions.length },
          localService,
          components: {
            layout: {
              liveInformationBeforePageInformation: true,
              recommendationsAfterWebSocketHook: true
            },
            vlcReplacement: {
              placement: "main-video-frame",
              engine: "mpegts.js-media-source-extensions",
              bundled: true,
              active: Boolean(state.playerState?.vlcReplacementActive),
              candidateCount: state.media.length
            },
            speechAndChatSettings: {
              settingsDialogAvailable: true,
              languageControlAvailable: true,
              voiceControlAvailable: true,
              auddTokenConfigured: Boolean(settings.auddApiToken),
              pairingConfigured: Boolean(settings.pairingCode),
              universalCaptionApiKeyConfigured: Boolean(settings.universalCaptionApiKey),
              speakNames: settings.speakNames !== false,
              shortenNames: Boolean(settings.shortenNames),
              gameModeEnabled: Boolean(settings.gameModeEnabled)
            },
            captions: {
              rawJsonExportAvailable: true,
              jsonLinesExportAvailable: true,
              protocolCount: state.captions.length,
              sources: captionSources,
              languages: captionLanguages
            },
            songRecognition: {
              path: "browser-local-service-audd",
              enabled: Boolean(settings.songRecognitionEnabled),
              providerConfigured: Boolean(settings.auddApiToken)
            },
            topChatters: {
              observedCount: participants.length,
              resetAvailable: true,
              mutedCount: (state.streamMutes || []).length,
              permanentMutedCount: (settings.permanentMutes || []).length
            },
            hookReconnect: {
              enabled: state.hookReconnect.enabled, delaySeconds: state.hookReconnect.seconds,
              controller: "hook-reconnect", delayMeaning: "attempt-start-delay", scope: "tab"
            },
            playerQuickRecovery: {
              enabled: Boolean(state.quickRecoverEnabled),
              delaySeconds: state.quickRecoverSeconds,
              controller: "player-quick-recovery",
              delayMeaning: "continuous-failure-confirmation",
              scope: "tab"
            }
          },
          debug: state.debug
        }) });
        break;
      }
      default:
        sendResponse({ ok: false, error: "Unbekannte Nachricht" });
    }
  };
  // Serialize incoming observations so each read-modify-write sees the preceding
  // caption/page update. Never hold this queue across commands awaiting content
  // scripts: they can send observations before responding to the command.
  const task = SERIAL_TAB_EVENTS.has(message.type)
    ? enqueueTabEvent(tabId, handleMessage)
    : (async () => { await tabEventTasks.get(tabId); return handleMessage(); })();
  if (isModeRequest) {
    task.then(releaseModeRequest, releaseModeRequest);
  }
  task.catch((error) => sendResponse({ ok: false, error: String(error?.message || error), code: error?.code || "UNKNOWN" }));
  return true;
});
