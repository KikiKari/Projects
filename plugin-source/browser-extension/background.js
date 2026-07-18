importScripts("content-core.js");

const STATE_PREFIX = "tlc-tab-";
const HOOK_SCRIPT_ID = "tiktok-live-companion-ws-hook";
const SETTINGS_KEY = "tlc-settings";
const PROFILE_PREFIX = "tlc-profile-";
const MAX_MEDIA = 60;
const MAX_CAPTIONS = 2000;
const MAX_CHAT = 50;
const MAX_EVENT_IDS = 500;
const MAX_DEBUG = 500;
const core = globalThis.TLC_CONTENT_CORE;

function stateKey(tabId) {
  return `${STATE_PREFIX}${tabId}`;
}

function emptyState() {
  return {
    page: { url: "", title: "", scannedAtUtc: null },
    captionInfo: { present: false, open: null, supportLang: [], location: null, showType: null },
    profileInfo: { ...core.EMPTY_PROFILE_INFO },
    aiSummaryInfo: { ...core.EMPTY_AI_SUMMARY_INFO },
    menuCaptionAvailable: false,
    menuCaptionActive: false,
    hook: { armed: false, installed: false, connected: false, lastError: null },
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
      limiterEnabled: false, limiterThresholdDbfs: -6, limiterReductionDb: 0,
      connectedStreams: 0, multiGuest: false
    },
    media: [],
    captions: [],
    chatMessages: [],
    debug: { enabled: false, entries: [] }
  };
}

async function getState(tabId) {
  const stored = await chrome.storage.session.get(stateKey(tabId));
  const defaults = emptyState();
  const state = stored[stateKey(tabId)];
  if (!state) return defaults;
  return {
    ...defaults,
    ...state,
    hook: { ...defaults.hook, ...(state.hook || {}) },
    liveStats: { ...defaults.liveStats, ...(state.liveStats || {}) },
    playerState: { ...defaults.playerState, ...(state.playerState || {}) },
    profileInfo: { ...defaults.profileInfo, ...(state.profileInfo || {}) },
    aiSummaryInfo: { ...defaults.aiSummaryInfo, ...(state.aiSummaryInfo || {}) },
    chatMessages: state.chatMessages || [],
    captions: state.captions || [],
    media: state.media || [],
    debug: { ...defaults.debug, ...(state.debug || {}), entries: state.debug?.entries || [] }
  };
}

function pageHandle(page) {
  try { return decodeURIComponent(new URL(page?.url || "").pathname.match(/^\/@([^/]+)/)?.[1] || "").toLocaleLowerCase(); }
  catch (_) { return ""; }
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
  const state = await getState(tabId);
  if (!state.debug?.enabled) return;
  state.debug.entries = [...(state.debug.entries || []), { atUtc: new Date().toISOString(), event, detail }].slice(-MAX_DEBUG);
  await setState(tabId, state);
}

function redactUrl(raw) {
  try {
    const url = new URL(raw);
    for (const key of [...url.searchParams.keys()]) url.searchParams.set(key, "REDACTED");
    return url.href;
  } catch (_) { return "ungültig"; }
}

async function setState(tabId, state) {
  await chrome.storage.session.set({ [stateKey(tabId)]: state });
  chrome.runtime.sendMessage({ type: "TLC_STATE_UPDATED", tabId, state }).catch(() => {});
  return state;
}

async function getSettings() {
  const stored = await chrome.storage.local.get(SETTINGS_KEY);
  return { autoHook: false, keepSpeechActive: false, speechVolume: 1, ...(stored[SETTINGS_KEY] || {}) };
}

async function setSettings(patch) {
  const settings = { ...(await getSettings()), ...patch };
  await chrome.storage.local.set({ [SETTINGS_KEY]: settings });
  return settings;
}

function profileCompleteness(profile) {
  return [profile?.uniqueId, profile?.nickname, profile?.signature, profile?.followingCount, profile?.followerCount, profile?.likeCount]
    .filter((value) => value != null && value !== "").length;
}

function mergeProfile(current, incoming) {
  if (!incoming?.present) return current;
  if (!current?.present || profileCompleteness(incoming) >= profileCompleteness(current)) return incoming;
  return { ...incoming, ...current, live: Boolean(current.live || incoming.live) };
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
  state.media = [...byUrl.values()].slice(-MAX_MEDIA);
  await setState(tabId, state);
}

async function addCaption(tabId, caption) {
  const state = await getState(tabId);
  state.captions.push({ ...caption, receivedAtUtc: caption.receivedAtUtc || new Date().toISOString() });
  state.captions = state.captions.slice(-MAX_CAPTIONS);
  await setState(tabId, state);
}

function chatKey(author, content) {
  return `${String(author || "").toLocaleLowerCase()}\n${String(content || "").toLocaleLowerCase()}`;
}

async function addChatMessage(tabId, rawMessage) {
  if (!Number.isInteger(tabId) || tabId < 0) return;
  const author = core.sanitizeChatText(rawMessage.nickname || rawMessage.displayId || rawMessage.author || "Chat");
  const content = core.sanitizeChatText(rawMessage.content);
  if (!content) return;
  const state = await getState(tabId);
  const receivedAtUtc = rawMessage.receivedAtUtc || new Date().toISOString();
  const dedupeKey = chatKey(author, content);
  const receivedAt = Date.parse(receivedAtUtc) || Date.now();
  const duplicate = (state.chatMessages || []).some((item) => {
    const existingKey = item.dedupeKey || chatKey(item.author, item.content);
    const existingAt = Date.parse(item.receivedAtUtc) || 0;
    return existingKey === dedupeKey && Math.abs(receivedAt - existingAt) <= 15000;
  });
  if (duplicate) return;
  state.chatMessages = [...(state.chatMessages || []), {
    messageId: rawMessage.messageId || null,
    author: author || "Chat",
    content,
    contentLanguage: rawMessage.contentLanguage || "",
    source: rawMessage.source || "unbekannt",
    receivedAtUtc,
    dedupeKey
  }].slice(-MAX_CHAT);
  await setState(tabId, state);
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
}

async function ensureHookRegistered(persistAcrossSessions = false) {
  const existing = await chrome.scripting.getRegisteredContentScripts({ ids: [HOOK_SCRIPT_ID] });
  if (existing.length && Boolean(existing[0].persistAcrossSessions) === Boolean(persistAcrossSessions)) return;
  if (existing.length) await chrome.scripting.unregisterContentScripts({ ids: [HOOK_SCRIPT_ID] });
  await chrome.scripting.registerContentScripts([{
    id: HOOK_SCRIPT_ID,
    matches: ["https://www.tiktok.com/*"],
    js: ["proto-main.js", "hook.js"],
    runAt: "document_start",
    world: "MAIN",
    persistAcrossSessions
  }]);
}

async function unregisterHook() {
  const existing = await chrome.scripting.getRegisteredContentScripts({ ids: [HOOK_SCRIPT_ID] });
  if (existing.length) await chrome.scripting.unregisterContentScripts({ ids: [HOOK_SCRIPT_ID] });
}

async function setHookFlag(tabId, enabled) {
  const tab = await chrome.tabs.get(tabId);
  if (!tab.url?.startsWith("https://www.tiktok.com/")) throw new Error("Der aktive Tab ist kein TikTok-Tab.");
  if (enabled) await ensureHookRegistered((await getSettings()).autoHook);
  else await unregisterHook();
  const state = await getState(tabId);
  state.hook = { armed: enabled, installed: false, connected: false, lastError: null };
  if (enabled) state.liveStats = emptyState().liveStats;
  await setState(tabId, state);
  await chrome.tabs.reload(tabId);
}

async function resetTabWithHook(tabId) {
  const tab = await chrome.tabs.get(tabId);
  if (!tab.url?.startsWith("https://www.tiktok.com/")) throw new Error("Der aktive Tab ist kein TikTok-Tab.");
  await ensureHookRegistered((await getSettings()).autoHook);
  const state = emptyState();
  state.page = { url: tab.url, title: tab.title || "", scannedAtUtc: null };
  state.hook.armed = true;
  await setState(tabId, state);
  await chrome.tabs.reload(tabId, { bypassCache: true });
}

chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: true }).catch(() => {});

chrome.runtime.onInstalled.addListener(() => {
  chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: true }).catch(() => {});
  getSettings().then((settings) => settings.autoHook && ensureHookRegistered(true)).catch(() => {});
});

chrome.runtime.onStartup.addListener(() => {
  getSettings().then((settings) => settings.autoHook && ensureHookRegistered(true)).catch(() => {});
});

chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (!tab.url) return;
  chrome.sidePanel.setOptions({
    tabId,
    path: "sidepanel.html",
    enabled: true
  }).catch(() => {});
  if (changeInfo.status === "loading" && tab.url.startsWith("https://www.tiktok.com/")) {
    getSettings().then(async (settings) => {
      if (!settings.autoHook) return;
      await ensureHookRegistered(true);
      const state = await getState(tabId);
      state.hook = { ...state.hook, armed: true, lastError: null };
      await setState(tabId, state);
    }).catch(() => {});
  }
  if (changeInfo.status === "loading") {
    patchState(tabId, { page: { url: tab.url, title: tab.title || "", scannedAtUtc: null } }).catch(() => {});
  }
  if (changeInfo.status === "complete" && tab.url.startsWith("https://www.tiktok.com/")) {
    getState(tabId).then((state) => chrome.tabs.sendMessage(tabId, { type: "TLC_DEBUG_CONFIG", enabled: Boolean(state.debug?.enabled) })).catch(() => {});
  }
});

chrome.tabs.onRemoved.addListener((tabId) => {
  chrome.storage.session.remove(stateKey(tabId)).catch(() => {});
});

chrome.webRequest.onBeforeRequest.addListener(
  (details) => {
    if (details.tabId >= 0) addMedia(details.tabId, [details.url], "network").catch(() => {});
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
  const tabId = message.tabId ?? sender.tab?.id;
  (async () => {
    switch (message.type) {
      case "TLC_GET_STATE":
        {
          const state = await getState(tabId);
          const cached = await cachedProfile(pageHandle(state.page));
          if (cached) {
            state.profileInfo = mergeProfile(state.profileInfo, cached);
            if (state.profileInfo?.followerCount != null) state.liveStats.followerCount = state.profileInfo.followerCount;
          }
          sendResponse({ ok: true, state });
        }
        break;
      case "TLC_GET_SETTINGS":
        sendResponse({ ok: true, settings: await getSettings() });
        break;
      case "TLC_SET_AUTOSTART": {
        const settings = await setSettings({ autoHook: Boolean(message.enabled) });
        if (settings.autoHook) await ensureHookRegistered(true);
        else await unregisterHook();
        sendResponse({ ok: true, settings });
        break;
      }
      case "TLC_SET_SPEECH_PREFERENCE": {
        const settings = await setSettings({
          ...(message.enabled == null ? {} : { keepSpeechActive: Boolean(message.enabled) }),
          ...(message.volume == null ? {} : { speechVolume: Math.max(0, Math.min(1, Number(message.volume))) })
        });
        sendResponse({ ok: true, settings });
        break;
      }
      case "TLC_PAGE_STATE": {
        const state = await getState(tabId);
        state.page = message.page || state.page;
        state.captionInfo = message.captionInfo || state.captionInfo;
        state.profileInfo = mergeProfile(state.profileInfo, message.profileInfo);
        await cacheProfile(state.profileInfo);
        const cached = await cachedProfile(pageHandle(state.page));
        if (cached) state.profileInfo = mergeProfile(state.profileInfo, cached);
        if (state.profileInfo?.followerCount != null) state.liveStats.followerCount = state.profileInfo.followerCount;
        state.aiSummaryInfo = message.aiSummaryInfo || state.aiSummaryInfo;
        state.menuCaptionAvailable = Boolean(message.menuCaptionAvailable);
        state.menuCaptionActive = Boolean(message.menuCaptionActive);
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
      case "TLC_LIVE_EVENT":
        await addLiveEvent(tabId, message.liveEvent);
        sendResponse({ ok: true });
        break;
      case "TLC_HOOK_STATUS": {
        const state = await getState(tabId);
        state.hook = { ...state.hook, ...message.hook };
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
      case "TLC_GET_PLAYER_STATE": {
        const response = await chrome.tabs.sendMessage(tabId, { type: message.type });
        if (response?.playerState) await patchState(tabId, { playerState: response.playerState });
        sendResponse({ ok: true, response });
        break;
      }
      case "TLC_PLAYER_ACTION": {
        const response = await chrome.tabs.sendMessage(tabId, {
          type: message.type,
          action: message.action,
          value: message.value,
          enabled: message.enabled,
          thresholdDbfs: message.thresholdDbfs
        });
        if (response?.playerState) await patchState(tabId, { playerState: response.playerState });
        await addDebug(tabId, "player-action", { action: message.action, activated: response?.activated, reason: response?.reason || response?.error || null, playerState: response?.playerState || null });
        sendResponse({ ok: true, response });
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
        await setHookFlag(tabId, true);
        sendResponse({ ok: true, reloading: true });
        break;
      case "TLC_DISABLE_HOOK":
        await setHookFlag(tabId, false);
        sendResponse({ ok: true, reloading: true });
        break;
      case "TLC_RESET_TAB":
        await resetTabWithHook(tabId);
        sendResponse({ ok: true, reloading: true });
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
        const state = await getState(tabId);
        state.debug = { enabled: Boolean(message.enabled), entries: state.debug?.entries || [] };
        await setState(tabId, state);
        await chrome.tabs.sendMessage(tabId, { type: "TLC_DEBUG_CONFIG", enabled: state.debug.enabled }).catch(() => {});
        sendResponse({ ok: true, state });
        break;
      }
      case "TLC_DEBUG_EVENT":
        await addDebug(tabId, message.event || "content", message.detail || {});
        sendResponse({ ok: true });
        break;
      case "TLC_CLEAR_DEBUG": {
        const state = await getState(tabId);
        state.debug.entries = [];
        await setState(tabId, state);
        sendResponse({ ok: true });
        break;
      }
      case "TLC_GET_DEBUG_REPORT": {
        const state = await getState(tabId);
        sendResponse({ ok: true, report: {
          generatedAtUtc: new Date().toISOString(), version: chrome.runtime.getManifest().version,
          page: state.page, captionInfo: state.captionInfo, profileInfo: state.profileInfo,
          aiSummaryInfo: state.aiSummaryInfo, hook: state.hook, liveStats: state.liveStats,
          playerState: state.playerState, selectedQuality: state.selectedQuality,
          media: state.media.map((item) => ({ ...item, url: redactUrl(item.url) })),
          counts: { chat: state.chatMessages.length, captions: state.captions.length },
          debug: state.debug
        } });
        break;
      }
      default:
        sendResponse({ ok: false, error: "Unbekannte Nachricht" });
    }
  })().catch((error) => sendResponse({ ok: false, error: String(error?.message || error) }));
  return true;
});
