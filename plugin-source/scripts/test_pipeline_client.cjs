const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { webcrypto } = require('node:crypto');

function client() {
  const local = { 'tlc-settings': { universalCaptionApiKey: 'universal-secret', pairingCode: 'pair-secret' } };
  const session = {}, rows = new Map(), received = [];
  const storage = data => ({ get: async keys => Object.fromEntries((Array.isArray(keys) ? keys : [keys]).map(key => [key, data[key]])), set: async values => Object.assign(data, structuredClone(values)) });
  const database = { transaction() {
    const tx = {};
    const operation = fn => { const req = {}; setImmediate(() => { req.result = fn(); req.onsuccess?.(); setImmediate(() => tx.oncomplete?.()); }); return req; };
    tx.objectStore = () => ({ put: row => operation(() => rows.set(row.eventId, structuredClone(row))), delete: id => operation(() => rows.delete(id)), getAll: () => operation(() => [...rows.values()].map(row => structuredClone(row))) });
    return tx;
  } };
  const indexedDB = { open() { const req = {}; setImmediate(() => { req.result = database; req.onsuccess(); }); return req; } };
  const context = vm.createContext({ crypto: webcrypto, indexedDB, AbortSignal, console,
    chrome: { storage: { local: storage(local), session: storage(session) }, runtime: { id: 'self' }, alarms: { create() {}, onAlarm: { addListener() {} } } },
    fetch: async (url, options) => { if (url.endsWith('/events')) received.push(JSON.parse(options.body)); return { ok: true, json: async () => ({ cursor: received.length }) }; }
  });
  vm.runInContext(fs.readFileSync(path.join(__dirname, '../browser-extension/pipeline-client.js'), 'utf8'), context);
  return { api: context.TLCPipelines, local, session, received, rows };
}
test('one key, two tabs, reload and delayed old-document events stay separate', async () => {
  const c = client();
  await c.api.start(1, 'doc-a'); await c.api.start(2, 'doc-b');
  await c.api.publish(1, 'chat', { text: 'first' }, 'pair-secret', 'chat', 'doc-a');
  await c.api.start(1, 'doc-c');
  await c.api.publish(1, 'chat', { text: 'late' }, 'late', 'chat', 'doc-a');
  await c.api.publish(1, 'chat', { text: 'current' }, 'current', 'chat');
  for (let i = 0; i < 30; i++) { await new Promise(setImmediate); await c.api.flush(); }
  assert.equal(c.rows.size, 0);
  const chats = c.received.filter(row => row.pipeline === 'chat' && row.availability === 'available');
  assert.deepEqual(chats.map(row => row.documentId), ['doc-a', 'doc-a', 'doc-c']);
  assert.equal(chats[0].raw, '[credential removed]');
  assert.equal(chats[0].credentialsRedacted, true);
  const b = c.received.find(row => row.documentId === 'doc-b');
  assert.notEqual(chats[0].tabId, b.tabId);
  assert.equal(chats[0].clientId, b.clientId);
  assert.equal(new Set(c.received.map(row => row.eventId)).size, c.received.length);
});
