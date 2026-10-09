import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { PipelineStore, PIPELINES, redactCredentials } from '../pipeline-store.mjs';
import { createServer } from '../server.mjs';
import { materializeFragments } from '../pipeline-api.mjs';

const event = (tabId, pipeline, eventId = `${tabId}-${pipeline}`) => ({ eventId, clientId: 'browser', sessionId: 'session', tabId, documentId: 'document', pipeline, capturedAt: new Date().toISOString(), availability: 'available', structured: { tabId }, raw: { text: '.Text', variants: ['360p','1080p60'] } });

test('mobile fragments reconstruct exact RAW values and missing pieces report gaps', () => {
  const original = { html: '<html>ä😃</html>', variants: ['SD','HD','1080p60'] };
  const encoded = JSON.stringify(original);
  const records = [encoded.slice(0,13), encoded.slice(13)].map((data, index) => ({ ...event('mobile','browser-tab', String(index)), cursor: index + 1, raw: { type: 'pipeline-record', payload: { recordId: 'group', chunkIndex: index, chunkCount: 2, encoding: 'json-string-fragments', data, source: 'dom-snapshot' } } }));
  assert.deepEqual(materializeFragments(records)[0].raw, original);
  assert.equal(materializeFragments(records.slice(1))[0].availability, 'gap');
  const otherTab = records.map(row => ({ ...row, tabId: 'other-tab' }));
  assert.equal(materializeFragments([...records, ...otherTab]).length, 2);
});

test('all twelve pipelines remain isolated and replay after restart', async t => {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), 'tlc-pipelines-'));
  t.after(() => fs.rm(directory, { recursive: true, force: true }));
  const store = new PipelineStore(directory);
  for (const pipeline of PIPELINES) await Promise.all(['tab1','tab2'].map(tab => store.append(event(tab, pipeline))));
  const restarted = new PipelineStore(directory); await restarted.ready;
  assert.equal(restarted.read().records.length, 24);
  assert.equal(restarted.read({ tabId: 'tab1' }).records.length, 12);
  assert.equal((await restarted.append(event('tab1','chat'))).duplicate, true);
  assert.deepEqual(restarted.read({ tabId: 'tab2', pipeline: 'chat' }).records[0].raw, event('tab2','chat').raw);
});

test('credentials are removed without filtering ordinary source fields', () => {
  const result = redactCredentials({ authorization: 'secret', text: 'nickname https://example.test/?sign=temporary', nested: ['keyvalue'] }, ['keyvalue']);
  assert.equal(result.redacted, true);
  assert.equal(result.data.text, 'nickname https://example.test/?sign=temporary');
  assert.equal(result.data.nested[0], '[credential removed]');
});

test('retention reports gaps and keeps its cursor across an empty restart', async t => {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), 'tlc-retention-'));
  t.after(() => fs.rm(directory, { recursive: true, force: true }));
  const store = new PipelineStore(directory, { maxBytes: 900 });
  await store.append(event('one','chat')); await store.append(event('two','chat')); await store.append(event('three','chat'));
  assert.equal(store.read({ after: 0 }).gap, true);
  const restarted = new PipelineStore(directory, { retentionDays: 0 }); await restarted.ready;
  assert.equal(restarted.read().lastCursor, 3);
});

test('external HTTP consumers authenticate, filter and parse exports', async t => {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), 'tlc-api-'));
  const store = new PipelineStore(directory);
  const server = createServer({ config: { pairingCode: 'paired', universalApiKey: 'reader' }, pipelineStore: store });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(async () => { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); await fs.rm(directory, { recursive: true, force: true }); });
  const base = `http://127.0.0.1:${server.address().port}/v1/pipelines`;
  assert.equal((await fetch(`${base}/sources`)).status, 401);
  for (const tab of ['a','b']) for (const pipeline of PIPELINES) {
    const response = await fetch(`${base}/events`, { method: 'POST', headers: { Authorization: 'Bearer paired', 'Content-Type': 'application/json' }, body: JSON.stringify(event(tab,pipeline)) });
    assert.equal(response.status, 200);
  }
  const response = await fetch(`${base}/export?tabId=a&format=jsonl`, { headers: { Authorization: 'Bearer reader' } });
  const rows = (await response.text()).trim().split('\n').map(JSON.parse);
  assert.equal(rows.length, 13); assert.equal(rows[0].type, 'metadata');
  assert.ok(rows.slice(1).every(row => row.tabId === 'a'));
  assert.equal((await fetch(`${base}/events`, { method: 'POST', headers: { Authorization: 'Bearer reader' }, body: JSON.stringify(event('c','chat')) })).status, 401);
});

test('SSE resumes after a cursor and state retains earlier source observations', async t => {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), 'tlc-sse-'));
  const store = new PipelineStore(directory);
  const server = createServer({ config: { pairingCode: 'paired', universalApiKey: 'reader' }, pipelineStore: store });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(async () => { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); await fs.rm(directory, { recursive: true, force: true }); });
  await store.append(event('a','browser-tab','original'));
  await store.append({ ...event('a','browser-tab','dom'), source: 'dom-snapshot' });
  const base = `http://127.0.0.1:${server.address().port}/v1/pipelines`;
  const control = new AbortController();
  const response = await fetch(`${base}/stream?tabId=a`, { headers: { Authorization: 'Bearer reader', 'Last-Event-ID': '1' }, signal: control.signal });
  const reader = response.body.getReader();
  let text = '';
  while (!text.includes('id: 2\n')) text += new TextDecoder().decode((await reader.read()).value);
  assert.ok(!text.includes('id: 1\n'));
  assert.ok(text.includes('"eventId":"dom"'));
  await store.append(event('a','chat','next'));
  while (!text.includes('id: 3\n')) text += new TextDecoder().decode((await reader.read()).value);
  control.abort();
  const state = await (await fetch(`${base}/state?pipeline=browser-tab`, { headers: { Authorization: 'Bearer reader' } })).json();
  assert.deepEqual(state.records[0].observations.map(row => row.eventId), ['original','dom']);
});
