// Capture actual network document bodies separately from DOM snapshots.
(() => {
  const documents = new Map();
  const attached = new Set();
  const pending = new Map();
  const registered = new Set();
  async function attach(tabId) {
    const settings = (await chrome.storage.local.get('tlc-settings'))['tlc-settings'];
    if (!settings?.universalCaptionApiKey || attached.has(tabId)) return;
    try {
      await chrome.debugger.attach({ tabId }, '1.3');
      await chrome.debugger.sendCommand({ tabId }, 'Network.enable');
      attached.add(tabId);
    } catch {
      await TLCPipelines.publish(tabId, 'browser-tab', { reason: 'document-capture-unavailable' }, null, 'debugger', undefined, 'unavailable');
    }
  }
  chrome.tabs.onUpdated.addListener((tabId, change, tab) => {
    if (!tab.url?.startsWith('https://www.tiktok.com/')) return;
    if (change.status === 'loading') void attach(tabId);
  });
  chrome.tabs.onRemoved.addListener(tabId => {
    attached.delete(tabId); documents.delete(tabId);
    for (const [key, value] of pending) if (value.tabId === tabId) pending.delete(key);
  });
  chrome.debugger.onDetach.addListener(({ tabId }) => {
    attached.delete(tabId);
    void TLCPipelines.publish(tabId, 'browser-tab', { reason: 'debugger-detached' }, null, 'debugger', documents.get(tabId), 'unavailable');
  });
  chrome.debugger.onEvent.addListener((source, method, params) => {
    const tabId = source.tabId;
    if (!attached.has(tabId)) return;
    const key = `${tabId}:${params.requestId}`;
    if (method === 'Network.responseReceived' && params.type === 'Document') {
      pending.set(key, { tabId, loaderId: params.loaderId, frameId: params.frameId, url: params.response.url, mimeType: params.response.mimeType });
    }
    if (method === 'Network.loadingFinished' && pending.has(key)) {
      const record = pending.get(key); pending.delete(key);
      Promise.all([chrome.debugger.sendCommand(source, 'Network.getResponseBody', { requestId: params.requestId }), chrome.debugger.sendCommand(source, 'Page.getFrameTree')]).then(async ([body, before]) => {
        if (before.frameTree?.frame?.loaderId !== record.loaderId) throw new Error('superseded-document');
        const frames = await chrome.webNavigation.getAllFrames({ tabId });
        const after = await chrome.debugger.sendCommand(source, 'Page.getFrameTree');
        if (after.frameTree?.frame?.loaderId !== record.loaderId) throw new Error('superseded-document');
        const frame = frames?.find(frame => frame.url === record.url && frame.frameId === 0);
        if (!frame) return;
        return TLCPipelines.publish(tabId, 'browser-tab', { ...record, kind: 'original-document' }, body, 'network-response-body', frame.documentId);
      }).catch(() => TLCPipelines.publish(tabId, 'browser-tab', { ...record, reason: 'response-body-unavailable' }, null, 'network-response-body', documents.get(tabId), 'unavailable'));
    }
    if (method === 'Network.webSocketFrameReceived') {
      void TLCPipelines.publish(tabId, 'debug-logs', { kind: 'websocket-frame', requestId: params.requestId }, params.response, 'network-websocket', documents.get(tabId));
    }
  });
  chrome.alarms.create('tlc-pipeline-dom', { periodInMinutes: 1 });
  chrome.alarms.onAlarm.addListener(alarm => {
    if (alarm.name === 'tlc-pipeline-dom') for (const tabId of attached) {
      void chrome.tabs.sendMessage(tabId, { type: 'TLC_CAPTURE_PIPELINE_DOCUMENT' }, { frameId: 0 }).catch(() => {});
    }
  });
  chrome.runtime.onMessage.addListener((message, sender) => {
    if (message.type !== 'TLC_PIPELINE_DOCUMENT' || !sender.tab?.id) return;
    documents.set(sender.tab.id, sender.documentId);
    const register = registered.has(sender.documentId) ? Promise.resolve() : TLCPipelines.start(sender.tab.id, sender.documentId);
    registered.add(sender.documentId);
    void register.then(() => TLCPipelines.publish(sender.tab.id, 'browser-tab', { url: sender.url, title: message.title, kind: 'current-dom', metadata: message.metadata }, message.html, 'dom-snapshot', sender.documentId));
    void attach(sender.tab.id);
  });
  chrome.storage.onChanged.addListener((changes, area) => {
    if (area !== 'local' || !changes['tlc-settings']) return;
    if (changes['tlc-settings'].newValue?.universalCaptionApiKey) {
      chrome.tabs.query({ url: 'https://www.tiktok.com/*' }).then(tabs => tabs.forEach(tab => void attach(tab.id)));
    } else for (const tabId of attached) void chrome.debugger.detach({ tabId }).catch(() => {});
  });
})();
