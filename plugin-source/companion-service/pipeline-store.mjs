import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';

export const PIPELINES = Object.freeze(['title', 'chat', 'speech-service', 'sherpa', 'top-chatters', 'profile', 'live', 'songs', 'media-links', 'live-logs', 'debug-logs', 'browser-tab']);
export function authenticate(actual, expected) {
  if (!expected || !actual) return false;
  const a = Buffer.from(actual), b = Buffer.from(`Bearer ${expected}`);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

// Redact only credentials, retaining all other source fields and recording edits.
export function redactCredentials(value, secrets = []) {
  let changed = false;
  const visit = (item) => {
    if (typeof item === 'string') {
      let result = item;
      for (const secret of secrets.filter(Boolean)) result = result.split(secret).join('[credential removed]');
      changed ||= result !== item;
      return result;
    }
    if (Array.isArray(item)) return item.map(visit);
    if (item && typeof item === 'object') return Object.fromEntries(Object.entries(item).map(([key, val]) => {
      if (/^(authorization|cookie|set-cookie|pairingCode|universalCaptionApiKey|universalApiKey|auddApiToken|api[_-]?key|access[_-]?token)$/i.test(key)) {
        changed = true; return [key, '[credential removed]'];
      }
      return [key, visit(val)];
    }));
    return item;
  };
  const data = visit(value);
  return { data, redacted: changed };
}

export class PipelineStore {
  constructor(directory, { retentionDays = 7, maxBytes = 2 * 1024 ** 3 } = {}) {
    this.directory = directory;
    this.retentionMs = retentionDays * 86400000;
    this.maxBytes = maxBytes;
    this.records = [];
    this.bytes = 0;
    this.ids = new Map();
    this.listeners = new Set();
    this.sequence = 0;
    this.queue = Promise.resolve();
    this.ready = this.load();
  }
  async load() {
    await fs.mkdir(this.directory, { recursive: true, mode: 0o700 });
    const names = (await fs.readdir(this.directory)).filter(name => /^\d{16}\.json$/.test(name)).sort();
    for (const name of names) {
      const record = JSON.parse(await fs.readFile(path.join(this.directory, name), 'utf8'));
      this.records.push(record); this.ids.set(this.identity(record), record.cursor);
      this.bytes += Buffer.byteLength(JSON.stringify(record));
      this.sequence = Math.max(this.sequence, record.cursor);
    }
    try { this.sequence = Math.max(this.sequence, Number(await fs.readFile(path.join(this.directory, 'sequence'), 'utf8'))); }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
    await this.prune();
  }
  filename(cursor) { return path.join(this.directory, `${String(cursor).padStart(16, '0')}.json`); }
  identity(record) { return JSON.stringify([record.clientId, record.sessionId, record.eventId]); }
  refresh() {
    const operation = this.queue.then(async () => { await this.ready; await this.prune(); });
    this.queue = operation.catch(() => {});
    return operation;
  }
  async prune() {
    const cutoff = Date.now() - this.retentionMs;
    while (this.records.length && (this.bytes > this.maxBytes || Date.parse(this.records[0].receivedAt) < cutoff)) {
      const row = this.records[0];
      await fs.unlink(this.filename(row.cursor));
      this.records.shift(); this.ids.delete(this.identity(row));
      this.bytes -= Buffer.byteLength(JSON.stringify(row));
    }
  }
  append(input, secrets = []) {
    const operation = this.queue.then(async () => {
      await this.ready;
      for (const field of ['eventId', 'clientId', 'sessionId', 'tabId', 'documentId', 'capturedAt']) {
        if (typeof input[field] !== 'string' || !input[field] || input[field].length > 256) throw Object.assign(new Error(`Invalid ${field}`), { statusCode: 400 });
      }
      if (!PIPELINES.includes(input.pipeline) || !['available', 'unavailable', 'gap'].includes(input.availability) || !Number.isFinite(Date.parse(input.capturedAt))) {
        throw Object.assign(new Error('Invalid pipeline event'), { statusCode: 400 });
      }
      if (this.ids.has(this.identity(input))) return { cursor: this.ids.get(this.identity(input)), duplicate: true };
      const clean = redactCredentials(input, secrets);
      const record = { ...clean.data, schemaVersion: 1, cursor: this.sequence + 1, receivedAt: new Date().toISOString(), credentialsRedacted: clean.redacted || Boolean(input.credentialsRedacted) };
      const json = JSON.stringify(record);
      if (Buffer.byteLength(json) > this.maxBytes) throw Object.assign(new Error('Event exceeds journal capacity'), { statusCode: 413 });
      const target = this.filename(record.cursor);
      await fs.writeFile(`${target}.tmp`, json, { mode: 0o600 });
      await fs.rename(`${target}.tmp`, target);
      this.sequence = record.cursor;
      this.records.push(record); this.ids.set(this.identity(record), record.cursor);
      this.bytes += Buffer.byteLength(json);
      await fs.writeFile(path.join(this.directory, 'sequence'), String(this.sequence), { mode: 0o600 });
      await this.prune();
      for (const listener of this.listeners) listener(record);
      return { cursor: record.cursor, duplicate: false };
    });
    this.queue = operation.catch(() => {});
    return operation;
  }
  read({ after = 0, clientId, sessionId, tabId, documentId, pipeline } = {}) {
    const firstAvailableCursor = this.records[0]?.cursor ?? this.sequence + 1;
    const matches = row => row.cursor > after && Object.entries({ clientId, sessionId, tabId, documentId, pipeline }).every(([key, value]) => !value || row[key] === value);
    return { schemaVersion: 1, firstAvailableCursor, lastCursor: this.sequence, gap: after < firstAvailableCursor - 1, retentionDays: this.retentionMs / 86400000, maxBytes: this.maxBytes, records: this.records.filter(matches) };
  }
}
