/* Monitor settings persist locally; signed media URLs stay in session storage. */
const TLCOverview = (() => {
  const CONFIG = 'tlc-overview-config', PREFIX = 'tlc-overview-row-', PLAYING = 'tlc-overview-playing-', SLOTS = 20, ALARM = 'tlc-overview-check';
  const normalize = value => String(value || '').trim().replace(/^@/, '').toLowerCase();
  const valid = handle => !handle || /^[a-z0-9._]{1,24}$/.test(handle);
  const blank = handle => ({ handle, status: 'unknown', media: [], checkedAt: null });
  async function config() {
    const data = (await chrome.storage.local.get(CONFIG))[CONFIG] || {};
    return { handles: Array.from({length: SLOTS}, (_, i) => normalize(data.handles?.[i])), interval: Math.max(1, Math.min(60, Math.round(Number(data.interval) || 5))), enabled: data.enabled !== false, maxLinks: Math.max(5, Math.min(30, Math.round(Number(data.maxLinks) || 5))), showLinks: data.showLinks === true, autoSort: data.autoSort === true, skipOnline: data.skipOnline === true, top: ['monitor','connection'].includes(data.top) ? data.top : '', expanded: data.expanded === true, reverse: data.reverse === true, grid2: data.grid2 === true };
  }
  async function rows() {
    const cfg = await config();
    const data = await chrome.storage.session.get(cfg.handles.map((_, i) => PREFIX + i));
    return cfg.handles.map((handle, i) => data[PREFIX + i]?.handle === handle ? { ...data[PREFIX + i], media: (data[PREFIX + i].media || []).slice(0, cfg.maxLinks) } : blank(handle));
  }
  async function configure(value) {
    const previous = await config();
    const handles = Array.from({length: SLOTS}, (_, i) => normalize((value.handles ?? previous.handles)?.[i]));
    if (handles.some(h => !valid(h))) throw new Error('Ungültiger Handle: nur Buchstaben, Zahlen, Punkt und Unterstrich verwenden.');
    const nonempty = handles.filter(Boolean);
    if (new Set(nonempty).size !== nonempty.length) throw new Error('Jeder Stream darf nur einmal eingetragen werden.');
    const interval = Math.max(1, Math.min(60, Math.round(Number(value.interval ?? previous.interval) || 5)));
    const enabled = value.enabled === undefined ? previous.enabled : Boolean(value.enabled);
    const maxLinks = Math.max(5, Math.min(30, Math.round(Number(value.maxLinks ?? previous.maxLinks) || 5)));
    const showLinks = value.showLinks === undefined ? previous.showLinks : Boolean(value.showLinks);
    const autoSort = value.autoSort === undefined ? previous.autoSort : Boolean(value.autoSort);
    const skipOnline = value.skipOnline === undefined ? previous.skipOnline : Boolean(value.skipOnline);
    const top = value.top === undefined ? previous.top : (['monitor','connection'].includes(value.top) ? value.top : '');
    const expanded = value.expanded === undefined ? previous.expanded : Boolean(value.expanded);
    const reverse = value.reverse === undefined ? previous.reverse : Boolean(value.reverse);
    const grid2 = value.grid2 === undefined ? previous.grid2 : Boolean(value.grid2);
    const updated = { handles, interval, enabled, maxLinks, showLinks, autoSort, skipOnline, top, expanded, reverse, grid2 };
    await chrome.storage.local.set({ [CONFIG]: updated });
    for (let i = 0; i < SLOTS; i++) if (previous.handles[i] !== handles[i]) await chrome.storage.session.remove(PREFIX + i);
    if (enabled) await chrome.alarms.create(ALARM, { periodInMinutes: interval });
    else await chrome.alarms.clear(ALARM);
    return { ok: true, config: updated, rows: await rows() };
  }
  async function probe(handle, maxLinks) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);
    try {
      const response = await fetch(`https://www.tiktok.com/@${encodeURIComponent(handle)}/live`, { credentials: 'omit', cache: 'no-store', signal: controller.signal });
      if (!response.ok) throw new Error('TikTok nicht erreichbar');
      const html = await response.text();
      const match = html.match(/<script\b[^>]*\bid=["']SIGI_STATE["'][^>]*>([\s\S]*?)<\/script>/i);
      if (!match) throw new Error('Statusdaten fehlen');
      const data = JSON.parse(match[1]);
      const info = data?.LiveRoom?.liveRoomUserInfo;
      if (normalize(info?.user?.uniqueId) !== handle) throw new Error('Account nicht eindeutig');
      const room = info?.liveRoom;
      const status = Number(room?.status);
      if (status === 4) return { handle, status: 'offline', media: [], checkedAt: Date.now() };
      if (status !== 2) throw new Error('Status nicht eindeutig');
      const sources = core.inspectMetadata(room, { profileUniqueId: handle }).media.filter(item => item?.url).slice(0, maxLinks);
      return { handle, status: 'online', media: sources, checkedAt: Date.now() };
    } finally { clearTimeout(timeout); controller.abort(); }
  }
  async function capturedSources(handle, maxLinks) {
    if (!chrome.tabs?.query || typeof getState !== 'function') return [];
    const tabs = await chrome.tabs.query({url: 'https://www.tiktok.com/*'});
    const sources = new Map();
    for (const tab of tabs) {
      if (!Number.isInteger(tab.id) || normalize(core.liveHandleFromUrl(tab.url)) !== handle) continue;
      if (typeof chrome.extension?.inIncognitoContext === 'boolean' && Boolean(tab.incognito) !== chrome.extension.inIncognitoContext) continue;
      try { await chrome.tabs.sendMessage(tab.id, {type:'TLC_SCAN'}); } catch (_) { /* Existing network capture can still contain sources. */ }
      const state = await getState(tab.id);
      for (const item of state.media || []) {
        try {
          const url = new URL(item.url), expires = Number(url.searchParams.get('expire'));
          if (url.protocol !== 'https:' || (expires && expires * 1000 <= Date.now())) continue;
          sources.set(item.url, item);
        } catch (_) { /* Ignore malformed media URLs. */ }
      }
    }
    return [...sources.values()].slice(0, maxLinks);
  }
  async function playing(handle, index) {
    const data = await chrome.storage.session.get(null);
    for (const [key, item] of Object.entries(data)) {
      if (!key.startsWith(PLAYING) || item?.handle !== handle || item?.index !== index) continue;
      if (Date.now() - Number(item.updatedAt || 0) > 45000) { await chrome.storage.session.remove(key); continue; }
      const tab = await chrome.tabs.get(item.tabId).catch(() => null);
      if (tab?.url?.startsWith(chrome.runtime.getURL('status-overview.html'))) return true;
      await chrome.storage.session.remove(key);
    }
    return false;
  }
  let checking = null;
  const checkingSlots = new Map();
  function checkSlot(index, forced = false) {
    if (checkingSlots.has(index)) return forced ? checkingSlots.get(index).then(() => checkSlot(index, true)) : checkingSlots.get(index);
    const task = (async () => {
      const cfg = await config(), previous = (await rows())[index], handle = cfg.handles[index];
      if (!handle) return;
      const hasLinks = previous.media?.some(item => item?.url);
      if (!forced && ((cfg.skipOnline && previous.status === 'online' && hasLinks) || ((previous.status !== 'online' || hasLinks) && await playing(handle, index)))) return;
      const key = PREFIX + index;
      await chrome.storage.session.set({ [key]: previous.status === 'online' ? { ...previous, checking: true } : { ...blank(handle), status: 'checking' } });
      let result;
      try {
        result = await probe(handle, cfg.maxLinks);
        if (result.status === 'online' && !result.media.length) {
          try { result.media = await capturedSources(handle, cfg.maxLinks); } catch (_) { /* Keep the direct status result. */ }
        }
      }
      catch (_) { result = { handle, status: 'error', media: [], checkedAt: Date.now() }; }
      if ((await config()).handles[index] !== handle) return;
      if (!forced && hasLinks && await playing(handle, index)) {
        const current = (await chrome.storage.session.get(key))[key];
        if (current?.handle === handle && current.checking) await chrome.storage.session.set({ [key]: { ...current, checking: false } });
      } else await chrome.storage.session.set({ [key]: result });
    })().finally(() => { checkingSlots.delete(index); });
    checkingSlots.set(index, task);
    return task;
  }
  function start() {
    if (checking) return checking;
    checking = Promise.all(Array.from({length: SLOTS}, (_, index) => checkSlot(index))).finally(() => { checking = null; });
    return checking;
  }
  chrome.alarms.onAlarm.addListener(alarm => { if (alarm.name === ALARM) config().then(c => c.enabled && start()).catch(() => {}); });
  chrome.runtime.onStartup.addListener(() => config().then(c => c.enabled && chrome.alarms.create(ALARM, { periodInMinutes: c.interval })).catch(() => {}));
  async function message(msg, sender = {}) {
    if (msg.type === 'TLC_OVERVIEW_PLAYBACK') {
      const tabId = sender.tab?.id, index = msg.index;
      if (!Number.isInteger(tabId) || !Number.isInteger(index) || index < 0 || index >= SLOTS || !String(sender.url || '').startsWith(chrome.runtime.getURL('status-overview.html'))) throw new Error('Ungültiger Player.');
      const key = `${PLAYING}${tabId}-${index}`;
      if (!msg.playing) await chrome.storage.session.remove(key);
      else { const cfg = await config(); const handle = normalize(msg.handle); if (handle && cfg.handles[index] === handle) await chrome.storage.session.set({ [key]: { tabId, index, handle, updatedAt: Date.now() } }); }
      return { ok: true };
    }
    if (msg.type === 'TLC_OVERVIEW_GET') return { ok: true, config: await config(), rows: await rows() };
    if (msg.type === 'TLC_OVERVIEW_SET') return configure(msg.config || {});
    if (msg.type === 'TLC_OVERVIEW_RETRY') {
      const index = msg.index, cfg = await config();
      if (!Number.isInteger(index) || index < 0 || index >= SLOTS || !cfg.handles[index] || cfg.handles[index] !== normalize(msg.handle)) throw new Error('Stream nicht gefunden.');
      const row = (await rows())[index];
      if (row.status !== 'online') throw new Error('Stream ist nicht online.');
      if (!cfg.skipOnline || !row.media?.some(item => item.url)) {
        await checkSlot(index, true);
        const current = (await rows())[index];
        if (current.handle !== cfg.handles[index] || current.status !== 'online' || !current.media?.some(item => item.url)) return { ok: true };
      }
      await chrome.storage.session.set({ ['tlc-overview-retry-' + index]: { handle: cfg.handles[index], nonce: Math.random() } });
      return { ok: true };
    }
    if (msg.type === 'TLC_OVERVIEW_RESET') return configure({ ...(await config()), handles: Array(SLOTS).fill('') });
    if (msg.type === 'TLC_OVERVIEW_CHECK') { await start(); return { ok: true }; }
    if (msg.type === 'TLC_OVERVIEW_OPEN') {
      if (!Number.isInteger(msg.windowId)) throw new Error('Browserfenster konnte nicht bestimmt werden.');
      await chrome.tabs.create({ windowId: msg.windowId, url: chrome.runtime.getURL('status-overview.html') });
      return { ok: true };
    }
    return { ok: false, error: 'Unbekannte Aktion' };
  }
  return { message };
})();
