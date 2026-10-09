import { authenticate, PIPELINES } from './pipeline-store.mjs';

export function materializeFragments(records) {
  const result = [], fragments = new Map();
  for (const row of records) {
    const part = row.raw?.payload;
    if (row.raw?.type !== 'pipeline-record' || part?.encoding !== 'json-string-fragments') { result.push(row); continue; }
    const key = JSON.stringify([row.clientId, row.sessionId, row.tabId, row.documentId, row.pipeline, part.recordId]);
    const group = fragments.get(key) || { row, count: part.chunkCount, parts: new Map() };
    group.parts.set(part.chunkIndex, part.data); group.row = row; fragments.set(key, group);
  }
  for (const { row, count, parts } of fragments.values()) {
    let value;
    if (Number.isInteger(count) && count > 0 && parts.size === count) {
      try { value = JSON.parse(Array.from({ length: count }, (_, index) => { if (!parts.has(index)) throw new Error('missing fragment'); return parts.get(index); }).join('')); }
      catch { /* Incomplete or invalid fragments remain explicitly unavailable. */ }
    }
    result.push(value === undefined ? { ...row, availability: 'gap', structured: { reason: 'incomplete-fragments', expected: count, received: parts.size } } : { ...row, structured: value, raw: value, source: row.raw.payload.source, reassembled: true });
  }
  return result.sort((a, b) => a.cursor - b.cursor);
}

export async function handlePipelineRequest(request, response, { store, config, saveConfig, readBody, origin = '' }) {
  const url = new URL(request.url, 'http://localhost');
  if (!url.pathname.startsWith('/v1/pipelines')) return false;
  const headers = { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', 'Access-Control-Allow-Origin': origin, Vary: 'Origin' };
  const send = (status, value) => { response.writeHead(status, headers); response.end(JSON.stringify(value)); return true; };
  try {
    const paired = authenticate(request.headers.authorization, config.pairingCode);
    const reader = authenticate(request.headers.authorization, config.universalApiKey);
    if (request.method === 'OPTIONS') return send(204, null);
    if (url.pathname === '/v1/pipelines/key' && request.method === 'POST') {
      if (!paired) return send(401, { error: 'Pairing required' });
      const body = JSON.parse((await readBody(request, 8192)).toString('utf8'));
      if (typeof body.key !== 'string' || body.key.length > 4096) return send(400, { error: 'Invalid key' });
      if (body.key !== config.universalApiKey) await saveConfig({ ...config, universalApiKey: body.key });
      config.universalApiKey = body.key;
      return send(200, { configured: Boolean(body.key) });
    }
    if (url.pathname === '/v1/pipelines/events' && request.method === 'POST') {
      if (!paired) return send(401, { error: 'Pairing required' });
      const event = JSON.parse((await readBody(request, 32 * 1024 ** 2)).toString('utf8'));
      const result = await store.append(event, [config.pairingCode, config.universalApiKey, config.auddApiToken]);
      return send(200, result);
    }
    if (!reader) return send(401, { error: 'Universal API-Key required' });
    if (request.method !== 'GET') return send(405, { error: 'Read-only access' });
    await store.ready;
    await store.refresh();
    const filter = Object.fromEntries(['clientId', 'sessionId', 'tabId', 'documentId', 'pipeline'].map(key => [key, url.searchParams.get(key) || undefined]));
    const cursor = url.searchParams.get('after') ?? request.headers['last-event-id'] ?? '0';
    if (!/^\d+$/.test(String(cursor)) || !Number.isSafeInteger(Number(cursor))) return send(400, { error: 'Invalid cursor' });
    filter.after = Number(cursor);
    const result = store.read(filter);
    if (url.pathname === '/v1/pipelines') return send(200, { ...result, records: undefined, pipelines: PIPELINES });
    if (url.pathname === '/v1/pipelines/sources') {
      const sources = new Map();
      for (const row of result.records) {
        const identity = [row.clientId, row.sessionId, row.tabId, row.documentId];
        const key = JSON.stringify(identity);
        const source = sources.get(key) || { clientId: row.clientId, sessionId: row.sessionId, tabId: row.tabId, documentId: row.documentId, pipelines: {} };
        source.pipelines[row.pipeline] = { availability: row.availability, capturedAt: row.capturedAt, cursor: row.cursor };
        sources.set(key, source);
      }
      return send(200, { ...result, records: undefined, sources: [...sources.values()] });
    }
    if (url.pathname === '/v1/pipelines/state') {
      const latest = new Map();
      for (const row of materializeFragments(result.records)) {
        const key = JSON.stringify([row.clientId, row.sessionId, row.tabId, row.documentId, row.pipeline]);
        const group = latest.get(key) || { observations: [] };
        group.observations.push(row);
        group.latest = row;
        latest.set(key, group);
      }
      return send(200, { ...result, records: [...latest.values()].map(group => ({ ...group.latest, observations: group.observations })) });
    }
    if (url.pathname === '/v1/pipelines/events' || url.pathname === '/v1/pipelines/export') {
      if (url.searchParams.get('format') === 'jsonl') {
        response.writeHead(200, { ...headers, 'Content-Type': 'application/x-ndjson' });
        response.write(JSON.stringify({ type: 'metadata', ...result, records: undefined }) + '\n');
        for (const row of result.records) response.write(JSON.stringify(row) + '\n');
        response.end(); return true;
      }
      return send(200, result);
    }
    if (url.pathname === '/v1/pipelines/stream') {
      response.writeHead(200, { ...headers, 'Content-Type': 'text/event-stream', Connection: 'keep-alive' });
      response.write(`event: metadata\ndata: ${JSON.stringify({ ...result, records: undefined })}\n\n`);
      const write = row => {
        if (row.cursor <= filter.after || Object.entries(filter).some(([key, value]) => key !== 'after' && value && row[key] !== value)) return;
        if (!response.write(`id: ${row.cursor}\nevent: pipeline\ndata: ${JSON.stringify(row)}\n\n`)) response.end();
      };
      for (const row of result.records) write(row);
      store.listeners.add(write);
      const heartbeat = setInterval(() => response.write(': heartbeat\n\n'), 15000);
      response.on('close', () => { clearInterval(heartbeat); store.listeners.delete(write); });
      return true;
    }
    return send(404, { error: 'Unknown pipeline endpoint' });
  } catch (error) { return send(error.statusCode || 500, { error: error.statusCode ? error.message : 'Pipeline request failed' }); }
}
