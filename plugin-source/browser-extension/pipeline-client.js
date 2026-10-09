/* Durable API publishing; UI storage limits do not apply to this outbox. */
globalThis.TLCPipelines = (() => {
  const pipelines = ['title','chat','speech-service','sherpa','top-chatters','profile','live','songs','media-links','live-logs','debug-logs','browser-tab'];
  const lastSnapshots = new Map();
  let database, flushing = false, serial = Promise.resolve();
  const run = fn => { const result = serial.then(fn); serial = result.catch(() => {}); return result; };
  const request = req => new Promise((resolve, reject) => { req.onsuccess = () => resolve(req.result); req.onerror = () => reject(req.error); });
  async function db() {
    if (!database) database = new Promise((resolve, reject) => {
      const open = indexedDB.open('tlc-pipeline-outbox', 1);
      open.onupgradeneeded = () => open.result.createObjectStore('events', { keyPath: 'eventId' });
      open.onsuccess = () => resolve(open.result); open.onerror = () => reject(open.error);
    });
    return database;
  }
  async function transaction(mode, action) {
    const tx = (await db()).transaction('events', mode);
    const done = new Promise((resolve, reject) => { tx.oncomplete = resolve; tx.onabort = () => reject(tx.error); tx.onerror = () => reject(tx.error); });
    const result = await action(tx.objectStore('events')); await done; return result;
  }
  async function identity(tabId, documentId, establish = false) {
    const local = await chrome.storage.local.get('pipelineClientId');
    const clientId = local.pipelineClientId || crypto.randomUUID();
    if (!local.pipelineClientId) await chrome.storage.local.set({ pipelineClientId: clientId });
    const session = await chrome.storage.session.get(['pipelineSessionId', `pipelineTab:${tabId}`]);
    const sessionId = session.pipelineSessionId || crypto.randomUUID();
    const existing = session[`pipelineTab:${tabId}`];
    const result = { clientId, sessionId, tabId: existing?.tabId || crypto.randomUUID(), documentId: documentId || existing?.documentId || crypto.randomUUID() };
    await chrome.storage.session.set({ pipelineSessionId: sessionId, [`pipelineTab:${tabId}`]: existing && !establish ? existing : result });
    return result;
  }
  function clean(value, secrets) {
    if (typeof value === 'string') return secrets.filter(Boolean).reduce((text, secret) => text.split(secret).join('[credential removed]'), value);
    if (Array.isArray(value)) return value.map(item => clean(item, secrets));
    if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, /^(authorization|cookie|set-cookie|pairingCode|universalCaptionApiKey|auddApiToken)$/i.test(key) ? '[credential removed]' : clean(item, secrets)]));
    return value;
  }
  async function enqueue(tabId, pipeline, structured, raw, source, documentId, availability = 'available') {
    const settings = (await chrome.storage.local.get('tlc-settings'))['tlc-settings'] || {};
    if (!settings.universalCaptionApiKey) return;
    const snapshotKey = `${tabId}:${pipeline}:${source}`;
    const snapshot = source === 'companion-state' ? JSON.stringify(structured) : undefined;
    if (snapshot !== undefined && lastSnapshots.get(snapshotKey) === snapshot) return;
    const original = { structured, raw };
    const sanitized = clean(original, [settings.universalCaptionApiKey, settings.pairingCode, settings.auddApiToken]);
    const sequenceState = await chrome.storage.local.get('pipelineSequence');
    const sourceSequence = (Number(sequenceState.pipelineSequence) || 0) + 1;
    await chrome.storage.local.set({ pipelineSequence: sourceSequence });
    const record = { eventId: crypto.randomUUID(), ...(await identity(tabId, documentId)), sourceSequence, pipeline, capturedAt: new Date().toISOString(), availability, source, ...sanitized, credentialsRedacted: JSON.stringify(original) !== JSON.stringify(sanitized) };
    try { await transaction('readwrite', store => request(store.put(record))); }
    catch (error) {
      const previous = (await chrome.storage.local.get('pipelineCaptureGap')).pipelineCaptureGap;
      await chrome.storage.local.set({ pipelineCaptureGap: {
        ...record, eventId: crypto.randomUUID(), pipeline: 'debug-logs', availability: 'gap', raw: null,
        structured: { reason: 'outbox-storage-failed', lostEvents: (previous?.structured?.lostEvents || 0) + 1, firstLostAt: previous?.structured?.firstLostAt || record.capturedAt }
      } });
      throw error;
    }
    if (snapshot !== undefined) lastSnapshots.set(snapshotKey, snapshot);
    void flush();
  }
  async function flush() {
    if (flushing) return; flushing = true;
    try {
      const settings = (await chrome.storage.local.get('tlc-settings'))['tlc-settings'] || {};
      if (!settings.universalCaptionApiKey || !settings.pairingCode) return;
      const base = String(settings.serviceUrl || 'http://127.0.0.1:43117').replace(/\/$/, '');
      const post = async (route, value) => {
        const response = await fetch(`${base}/v1/pipelines/${route}`, { method: 'POST', headers: { Authorization: `Bearer ${settings.pairingCode}`, 'Content-Type': 'application/json' }, body: JSON.stringify(value), signal: AbortSignal.timeout(10000) });
        if (!response.ok) throw new Error(`pipeline-http-${response.status}`);
        return response.json();
      };
      await post('key', { key: settings.universalCaptionApiKey });
      const gap = (await chrome.storage.local.get('pipelineCaptureGap')).pipelineCaptureGap;
      if (gap?.eventId) {
        await post('events', gap);
        if ((await chrome.storage.local.get('pipelineCaptureGap')).pipelineCaptureGap?.eventId === gap.eventId) await chrome.storage.local.remove('pipelineCaptureGap');
      }
      const rows = await transaction('readonly', store => request(store.getAll()));
      rows.sort((a,b) => a.sourceSequence - b.sourceSequence);
      for (const row of rows) { await post('events', row); await transaction('readwrite', store => request(store.delete(row.eventId))); }
      await chrome.storage.local.set({ pipelineConnection: { available: true, at: new Date().toISOString() } });
    } catch (error) {
      await chrome.storage.local.set({ pipelineConnection: { available: false, at: new Date().toISOString(), reason: String(error.message) } });
    } finally { flushing = false; }
  }
  const publish = (...args) => run(() => enqueue(...args));
  const messagePipelines = { TLC_CAPTION: ['title','live-logs'], TLC_CHAT_MESSAGE: ['chat','top-chatters'], TLC_MEDIA_FOUND: ['media-links'], TLC_LIVE_EVENT: ['live'], TLC_PAGE_STATE: ['profile','browser-tab'], TLC_DEBUG_EVENT: ['debug-logs'] };
  async function message(message, sender) {
    if (message.type === 'TLC_PIPELINE_SERVICE' && sender.id === chrome.runtime.id && Number.isInteger(message.tabId) && ['songs','speech-service','sherpa'].includes(message.pipeline)) {
      await publish(message.tabId, message.pipeline, message.data, message.data, 'companion-service'); return;
    }
    if (!Number.isInteger(sender.tab?.id)) return;
    for (const pipeline of messagePipelines[message.type] || []) await publish(sender.tab.id, pipeline, message, message, 'extension-message', sender.documentId);
  }
  async function start(tabId, documentId) {
    await run(async () => {
      await identity(tabId, documentId, true);
      for (const key of lastSnapshots.keys()) if (key.startsWith(`${tabId}:`)) lastSnapshots.delete(key);
      for (const pipeline of pipelines) await enqueue(tabId, pipeline, { reason: 'not-yet-observed' }, null, 'source-registration', documentId, 'unavailable');
    });
  }
  chrome.alarms.create('tlc-pipeline-flush', { periodInMinutes: 1 });
  chrome.alarms.onAlarm.addListener(alarm => { if (alarm.name === 'tlc-pipeline-flush') void flush(); });
  return { publish, message, start, flush };
})();
