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
const MAX_PARTICIPANTS = 5000;
const NATIVE_HOST = "de.kikikari.tiktok_live_companion";
const INSTALLER_URL = "https://tiktok-live-companion.vercel.app/de/installation#sprachdienst";
const core = globalThis.TLC_CONTENT_CORE;

function stateKey(tabId) {
  return `${STATE_PREFIX}${tabId}`;
}

function emptyState() {
  return {
    page: { url: "", title: "", scannedAtUtc: null },
    captionInfo: { present: false, open: null, supportLang: [], location: null, showType: null, observed: false, source: null },
    profileInfo: { ...core.EMPTY_PROFILE_INFO },
    aiSummaryInfo: { ...core.EMPTY_AI_SUMMARY_INFO },
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
    participants: {},
    participantsTruncated: false,
    streamMutes: [],
    recentGiftIds: [],
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
    stream: { ...defaults.stream, ...(state.stream || {}), teamEvidence: state.stream?.teamEvidence || {} },
    liveStats: { ...defaults.liveStats, ...(state.liveStats || {}) },
    playerState: { ...defaults.playerState, ...(state.playerState || {}) },
    profileInfo: { ...defaults.profileInfo, ...(state.profileInfo || {}) },
    aiSummaryInfo: { ...defaults.aiSummaryInfo, ...(state.aiSummaryInfo || {}) },
    chatMessages: state.chatMessages || [],
    participants: state.participants || {},
    participantsTruncated: Boolean(state.participantsTruncated),
    streamMutes: state.streamMutes || [],
    recentGiftIds: state.recentGiftIds || [],
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
  return {
    autoHook: false,
    keepSpeechActive: false,
    speechVolume: 0.5,
    speechLanguage: "auto",
    speakNames: true,
    shortenNames: false,
    serviceUrl: "http://127.0.0.1:43117",
    pairingCode: "",
    playerVolume: 100,
    limiterStrength: 30,
    limiterEnabled: false,
    nativeHostVersion: "",
    auddConfigured: false,
    songRecognitionEnabled: false,
    permanentMutes: [],
    ...(stored[SETTINGS_KEY] || {})
  };
}

async function setSettings(patch) {
  const settings = { ...(await getSettings()), ...patch };
  await chrome.storage.local.set({ [SETTINGS_KEY]: settings });
  return settings;
}

function publicTikTokLiveUrl(value) {
  try {
    const url = new URL(String(value || ""));
    return url.protocol === "https:" && url.hostname === "www.tiktok.com" && /^\/@[^/]+\/live\/?$/.test(url.pathname);
  } catch (_) {
    return false;
  }
}

function nativeMessage(payload) {
  return new Promise((resolve, reject) => {
    chrome.runtime.sendNativeMessage(NATIVE_HOST, payload, (response) => {
      const error = chrome.runtime.lastError;
      if (error) {
        const message = String(error.message || error);
        const code = /native messaging host.*(?:not found|not registered)|specified native messaging host/i.test(message)
          ? "NATIVE_HOST_NOT_INSTALLED"
          : "NATIVE_HOST_ERROR";
        reject(Object.assign(new Error(message), { code }));
        return;
      }
      if (!response?.ok) reject(Object.assign(new Error(response?.error || "Native Host meldet einen Fehler."), { code: response?.code || "NATIVE_HOST_ERROR" }));
      else resolve(response);
    });
  });
}

async function bootstrapNativeHost(action = "bootstrap", extra = {}) {
  const response = await nativeMessage({ action, clientVersion: chrome.runtime.getManifest().version, ...extra });
  const patch = {
    nativeHostVersion: String(response.hostVersion || ""),
    auddConfigured: Boolean(response.auddConfigured)
  };
  if (response.pairingCode) patch.pairingCode = String(response.pairingCode);
  await setSettings(patch);
  return response;
}

async function getLiveCaptureTarget(tabId) {
  const [active] = await chrome.tabs.query({ active: true, currentWindow: true });
  const target = Number.isInteger(tabId) ? await chrome.tabs.get(tabId).catch(() => null) : active;
  if (!target || target.id !== active?.id || !publicTikTokLiveUrl(target.url)) {
    throw Object.assign(new Error("Kein aktiver öffentlicher TikTok-LIVE-Tab gefunden."), { code: "NO_TIKTOK_LIVE_TAB" });
  }
  return target;
}

async function getTabAudioStreamId(tabId) {
  const target = await getLiveCaptureTarget(tabId);
  try {
    const streamId = await chrome.tabCapture.getMediaStreamId({ targetTabId: target.id });
    if (!streamId) throw new Error("Keine Stream-ID erhalten.");
    return { streamId, tabId: target.id };
  } catch (error) {
    throw Object.assign(new Error("Die Tab-Audiofreigabe fehlt oder wurde abgelehnt."), { code: "TAB_CAPTURE_PERMISSION", cause: error });
  }
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
  const receivedAtUtc = caption.receivedAtUtc || new Date().toISOString();
  const timestamp = Date.parse(receivedAtUtc) || Date.now();
  if (caption.source === "dom") {
    const recentWebSocket = [...state.captions].reverse().find((item) => item.method === "WebcastCaptionMessage");
    if (recentWebSocket
      && Math.abs(timestamp - (Date.parse(recentWebSocket.receivedAtUtc || 0) || 0)) < 8_000
      && core.captionsOverlap(caption, recentWebSocket)) return;
    const last = state.captions.at(-1);
    if (last?.source === "dom"
      && timestamp - (Date.parse(last.receivedAtUtc || 0) || 0) < 2_500
      && core.captionsOverlap(last, caption)) {
      const replacement = core.captionText(caption).length >= core.captionText(last).length
        ? { ...caption, receivedAtUtc }
        : { ...last, receivedAtUtc };
      state.captions[state.captions.length - 1] = replacement;
      state.captionInfo = core.mergeObservedCaptionInfo(state.captionInfo, replacement);
      await setState(tabId, state);
      return;
    }
  }
  const entry = { ...caption, receivedAtUtc };
  const key = entry.sentenceId || entry.sequenceId || (entry.contents || []).map((content) => `${content.lang || ""}:${content.text || ""}`).join("\n");
  const duplicate = key && state.captions.slice(-20).some((item) => {
    const itemKey = item.sentenceId || item.sequenceId || (item.contents || []).map((content) => `${content.lang || ""}:${content.text || ""}`).join("\n");
    return itemKey === key;
  });
  if (duplicate) return;
  if (entry.method === "WebcastCaptionMessage") {
    state.captions = state.captions.filter((item) => !(
      item.source === "dom"
      && Math.abs(timestamp - (Date.parse(item.receivedAtUtc || 0) || 0)) < 8_000
      && core.captionsOverlap(item, entry)
    ));
  }
  state.captions.push(entry);
  state.captions = state.captions.slice(-MAX_CAPTIONS);
  state.captionInfo = core.mergeObservedCaptionInfo(state.captionInfo, entry);
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

function participantAliases(participant, fallbackKey = "") {
  return [...new Set([
    fallbackKey,
    participant?.userId ? `id:${participant.userId}` : "",
    participant?.displayId ? `handle:${core.normalizedIdentity(participant.displayId)}` : "",
    participant?.name ? `name:${core.normalizedIdentity(participant.name)}` : ""
  ].filter(Boolean))];
}

function updateParticipant(state, raw, author, patch = {}) {
  const requestedKey = participantKey(raw, author);
  const matchedEntry = Object.entries(state.participants).find(([, participant]) =>
    core.sameParticipant(participant, { ...raw, name: author })
  );
  const key = state.participants[requestedKey] ? requestedKey : (matchedEntry?.[0] || requestedKey);
  const existing = state.participants[key];
  if (!existing && Object.keys(state.participants).length >= MAX_PARTICIPANTS) {
    state.participantsTruncated = true;
    return { key, participant: null };
  }
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
  const duplicate = (state.chatMessages || []).some((item) => {
    const existingKey = item.dedupeKey || chatKey(item.author, item.content);
    const existingAt = Date.parse(item.receivedAtUtc) || 0;
    return existingKey === dedupeKey && Math.abs(receivedAt - existingAt) <= 15000;
  });
  if (duplicate) return;
  const participantResult = updateParticipant(state, rawMessage, author);
  if (participantResult.participant) {
    participantResult.participant.messageCount += 1;
    participantResult.participant.wordCount += core.wordCount(content);
  }
  const settings = await getSettings();
  state.chatMessages = [...(state.chatMessages || []), {
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
  }].slice(-MAX_CHAT);
  await setState(tabId, state);
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
  const match = liveUrl.match(/^https:\/\/www\.tiktok\.com\/@([^/?#]+)\/live\/?/i);
  if (!match) throw new Error("Force ist nur auf einer TikTok-LIVE-URL verfügbar.");
  const profileUrl = `https://www.tiktok.com/@${match[1]}`;
  let profileResult = null;
  try {
    const profileLoaded = waitForTabComplete(tabId, profileUrl);
    await chrome.tabs.update(tabId, { url: profileUrl });
    await profileLoaded;
    profileResult = await chrome.tabs.sendMessage(tabId, { type: "TLC_SCAN" });
    if (!profileResult?.profileInfo?.present) throw new Error("Die vollständig geladene Profilseite lieferte keine Profilwerte.");
    return { activated: true, profileInfo: profileResult.profileInfo };
  } finally {
    await chrome.tabs.update(tabId, { url: liveUrl }).catch(() => {});
  }
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
        {
          const { pairingCode: _pairingCode, ...settings } = await getSettings();
          sendResponse({ ok: true, settings });
        }
        break;
      case "TLC_NATIVE_BOOTSTRAP": {
        const response = await bootstrapNativeHost(message.action || "bootstrap");
        sendResponse({ ok: true, native: response });
        break;
      }
      case "TLC_CONFIGURE_AUDD": {
        const token = String(message.token || "").trim();
        if (!token) throw Object.assign(new Error("Kein AudD API-Token eingegeben."), { code: "AUDD_NOT_CONFIGURED" });
        const response = await bootstrapNativeHost("configureAudd", { token });
        sendResponse({ ok: true, native: response });
        break;
      }
      case "TLC_GET_TAB_AUDIO_STREAM_ID": {
        const settings = await getSettings();
        if (!settings.nativeHostVersion) throw Object.assign(new Error("Native Host ist nicht installiert."), { code: "NATIVE_HOST_NOT_INSTALLED" });
        const native = await bootstrapNativeHost("health");
        if (!native.serviceRunning) throw Object.assign(new Error("Der lokale Sprachdienst ist nicht gestartet."), { code: "SERVICE_NOT_RUNNING" });
        if (!native.auddConfigured) throw Object.assign(new Error("AudD ist im lokalen Dienst nicht konfiguriert."), { code: "AUDD_NOT_CONFIGURED" });
        const capture = await getTabAudioStreamId(tabId);
        sendResponse({ ok: true, ...capture });
        break;
      }
      case "TLC_OPEN_SERVICE_INSTALLER":
        await chrome.tabs.create({ url: INSTALLER_URL });
        sendResponse({ ok: true });
        break;
      case "TLC_AUDIO_PIPELINE_CONFLICT": {
        const key = `tlc-audio-reload-${tabId}`;
        const stored = await chrome.storage.session.get(key);
        if (!stored[key]) {
          await chrome.storage.session.set({ [key]: true });
          await chrome.tabs.reload(tabId);
          sendResponse({ ok: true, reloading: true });
        } else {
          sendResponse({ ok: false, error: "Die bestehende Audio-Pipeline konnte auch nach dem kontrollierten Reload nicht übernommen werden." });
        }
        break;
      }
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
          ...(message.volume == null ? {} : { speechVolume: Math.max(0, Math.min(1, Number(message.volume))) }),
          ...(message.language == null ? {} : { speechLanguage: ["auto", "de-DE", "en-US"].includes(message.language) ? message.language : "auto" }),
          ...(message.speakNames == null ? {} : { speakNames: Boolean(message.speakNames) }),
          ...(message.shortenNames == null ? {} : { shortenNames: Boolean(message.shortenNames) }),
          ...(message.serviceUrl == null ? {} : { serviceUrl: loopbackServiceUrl(message.serviceUrl) || "http://127.0.0.1:43117" }),
          ...(message.songRecognitionEnabled == null ? {} : { songRecognitionEnabled: Boolean(message.songRecognitionEnabled) })
        });
        sendResponse({ ok: true, settings });
        break;
      }
      case "TLC_PAGE_STATE": {
        const state = await getState(tabId);
        state.page = message.page || state.page;
        applyStreamIdentity(state, { handle: pageHandle(state.page) });
        state.captionInfo = message.captionInfo || state.captionInfo;
        state.profileInfo = mergeProfile(state.profileInfo, message.profileInfo);
        await cacheProfile(state.profileInfo);
        const cached = await cachedProfile(pageHandle(state.page));
        if (cached) state.profileInfo = mergeProfile(state.profileInfo, cached);
        if (state.profileInfo?.followerCount != null) state.liveStats.followerCount = state.profileInfo.followerCount;
        state.aiSummaryInfo = message.aiSummaryInfo || state.aiSummaryInfo;
        state.menuCaptionAvailable = Boolean(state.menuCaptionAvailable || message.menuCaptionAvailable);
        state.menuCaptionActive = Boolean(state.menuCaptionActive || message.menuCaptionActive);
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
      case "TLC_FORCE_PROFILE": {
        const response = await forceProfileRefresh(tabId);
        sendResponse({ ok: true, response, reloading: true });
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
          strength: message.strength
        });
        if (response?.playerState) await patchState(tabId, { playerState: response.playerState });
        if (message.action === "set-volume" && response?.activated) {
          await setSettings({ playerVolume: Math.max(0, Math.min(100, Math.round(Number(message.value) * 100))) });
        }
        if (message.action === "set-limiter" && response?.activated) {
          await setSettings({
            limiterEnabled: Boolean(message.enabled),
            limiterStrength: Math.max(0, Math.min(100, Math.round(Number(message.strength) || 0)))
          });
        }
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
  })().catch((error) => sendResponse({ ok: false, error: String(error?.message || error), code: error?.code || "UNKNOWN" }));
  return true;
});
