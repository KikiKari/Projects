#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "ba0f434bf8c19f8ee14958194bfabc2f40511f1de36e8b9a3a6b52d7028d1f58", "source_sha256": "12c3ea0e67b1e873ac253df6f3f06d5ed42b603005d56186c531d8a5b0d7f377", "target_language": "javascript"}
// gateway_transport.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/gateway_transport.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/** Gateway-authenticated transport with manager-owned attempt records.

An attempt is saved before submission. If its outcome is uncertain, subsequent
calls only query the same node and attempt; they do not submit it again.
*/

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');
const crypto = require('crypto');
const { URL } = require('url');

class TransportUnresolved extends Error {
  constructor(message) {
    super(message);
    this.name = 'TransportUnresolved';
  }
}

function gatewayToken() {
  /** Use the local Gateway credential without changing its configuration. */
  let token = process.env.OPENCLAW_GATEWAY_TOKEN || '';
  token = token.trim();
  if (token) {
    return token;
  }
  
  let configPath = process.env.OPENCLAW_CONFIG_PATH;
  if (!configPath) {
    configPath = path.join(require('os').homedir(), '.openclaw', 'openclaw.json');
  }
  
  try {
    const configContent = fs.readFileSync(configPath, 'utf8');
    const config = JSON.parse(configContent);
    token = config.gateway?.auth?.token || '';
  } catch (error) {
    return '';
  }
  
  if (typeof token === 'string' && !token.startsWith('${')) {
    return token.trim();
  }
  return '';
}

class GatewayTransport {
  constructor(state, save, url, token, { timeout = 3900, interval = 3, opener = null, clock = null, sleep = null } = {}) {
    const parsed = new URL(url);
    if (!['http:', 'https:'].includes(parsed.protocol) || !parsed.hostname) {
      throw new Error('invalid Gateway URL');
    }
    if (parsed.protocol === 'http:' && !['127.0.0.1', 'localhost', '::1'].includes(parsed.hostname)) {
      throw new Error('unencrypted Gateway must use loopback');
    }
    if (!token.trim() || timeout <= 0 || interval <= 0) {
      throw new Error('Gateway token and positive timeouts required');
    }
    
    this.state = state;
    this.save = save;
    this.url = url;
    this.token = token.trim();
    this.timeout = timeout;
    this.interval = interval;
    this.opener = opener || this._defaultOpener.bind(this);
    this.clock = clock || (() => process.hrtime.bigint() / BigInt(1000000)); // milliseconds
    this.sleep = sleep || ((ms) => new Promise(resolve => setTimeout(resolve, ms)));
  }

  _defaultOpener(requestOptions, postData) {
    return new Promise((resolve, reject) => {
      const lib = requestOptions.protocol === 'https:' ? https : http;
      
      const req = lib.request(requestOptions, (res) => {
        let data = [];
        let totalLength = 0;
        
        res.on('data', (chunk) => {
          totalLength += chunk.length;
          if (totalLength > 4000000) {
            res.destroy();
            reject(new Error('response too large'));
            return;
          }
          data.push(chunk);
        });
        
        res.on('end', () => {
          try {
            const buffer = Buffer.concat(data);
            resolve({ statusCode: res.statusCode, headers: res.headers, body: buffer.toString('utf8') });
          } catch (error) {
            reject(error);
          }
        });
      });
      
      req.on('error', reject);
      req.on('timeout', () => {
        req.destroy();
        reject(new Error('Request timeout'));
      });
      
      if (postData) {
        req.write(postData);
      }
      
      req.end();
    });
  }

  async _request(node, request, deviceId = null) {
    const payload = JSON.stringify({ node, device_id: deviceId, request });
    const parsedUrl = new URL(this.url);
    
    const requestOptions = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port,
      path: parsedUrl.pathname + parsedUrl.search,
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + this.token,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      },
      timeout: node === 'node4' ? 150000 : 40000 // 150s or 40s in milliseconds
    };
    
    if (parsedUrl.protocol === 'https:') {
      requestOptions.rejectUnauthorized = false; // Equivalent to Python's behavior
    }
    
    try {
      const result = await this.opener(requestOptions, payload);
      if (result.statusCode !== 200) {
        throw new Error(`HTTP ${result.statusCode}`);
      }
      
      const data = JSON.parse(result.body);
      if (typeof data !== 'object' || !('result' in data)) {
        throw new Error('invalid gateway response');
      }
      
      if (deviceId !== null && data.device_id !== deviceId) {
        throw new Error('gateway device identity mismatch');
      }
      
      return data.result;
    } catch (error) {
      throw new TransportUnresolved('Gateway request failed', { cause: error });
    }
  }

  async available() {
    const result = await this._request('node1', { operation: 'availability' });
    if (typeof result !== 'object') {
      throw new TransportUnresolved('invalid node availability');
    }
    return result;
  }

  async _release(original, entry) {
    if (entry.released) {
      return;
    }
    
    try {
      const result = await this._request(
        original.selected_node,
        {
          operation: 'release',
          job_id: original.job_id,
          attempt_id: original.attempt_id
        },
        original.selected_device_id
      );
      
      if (typeof result === 'object' && 
          result.status === 'released' &&
          result.job_id === original.job_id &&
          result.attempt_id === original.attempt_id &&
          result.selected_node === original.selected_node &&
          result.target_language === original.target_language) {
        entry.released = true;
        this.save(this.state);
      }
    } catch (error) {
      // Retry cleanup later; the result is durable in manager state.
      return;
    }
  }

  async releasePending() {
    const auftraege = this.state.auftraege || {};
    for (const key of Object.keys(auftraege)) {
      const entry = auftraege[key];
      if (typeof entry === 'object' && 
          ['completed', 'rejected', 'failed'].includes(entry.status) &&
          typeof entry.job === 'object') {
        await this._release(entry.job, entry);
      }
    }
  }

  reject(job, reason) {
    /** Record a completed response rejected by validation, before retrying it. */
    if (!job.source_sha256 || !job.target_language) {
      return;
    }
    
    const key = job.source_sha256 + ':' + job.target_language;
    const auftraege = this.state.auftraege || {};
    const entry = auftraege[key];
    
    if (typeof entry !== 'object' || entry.status !== 'completed') {
      return;
    }
    
    if (entry.job?.attempt_id !== job.attempt_id) {
      throw new TransportUnresolved('rejected attempt identity mismatch');
    }
    
    entry.status = 'rejected';
    entry.validation_error = String(reason).substring(0, 500);
    this.save(this.state);
  }

  async call(job) {
    if (!job.source_sha256 || !job.target_language || !job.selected_device_id) {
      throw new Error('missing source identity');
    }
    
    const key = job.source_sha256 + ':' + job.target_language;
    const auftraege = this.state.auftraege || {};
    this.state.auftraege = auftraege;
    
    let entry = auftraege[key];
    let fresh = false;
    
    if (typeof entry === 'object' && entry.status === 'rejected') {
      await this._release(entry.job, entry);
      
      if (!entry.released) {
        throw new TransportUnresolved('rejected attempt release is unresolved');
      }
      
      const previous = entry;
      const original = { ...job, attempt_id: crypto.randomUUID() };
      entry = {
        job: original,
        status: 'submitted',
        previous_attempts: [
          ...(previous.previous_attempts || []),
          {
            job_id: previous.job?.job_id,
            attempt_id: previous.job?.attempt_id,
            selected_node: previous.job?.selected_node,
            validation_error: previous.validation_error
          }
        ]
      };
      auftraege[key] = entry;
      this.save(this.state);
      fresh = true;
    } else {
      fresh = entry === undefined;
    }
    
    if (entry === undefined) {
      const original = { ...job, attempt_id: crypto.randomUUID() };
      entry = { job: original, status: 'submitted' };
      auftraege[key] = entry;
      // If this write fails there must be no remote submission.
      this.save(this.state);
    }
    
    const original = entry.job;
    // The dispatcher verifies the job object after transport returns.
    Object.assign(job, original);
    
    if (entry.response !== undefined) {
      await this._release(original, entry);
      return entry.response;
    }
    
    if (entry.status === 'failed') {
      throw new TransportUnresolved('attempt requires reconciliation');
    }
    
    let status = null;
    
    if (fresh) {
      try {
        status = await this._request(
          original.selected_node,
          { operation: 'execute', job: original },
          original.selected_device_id
        );
      } catch (error) {
        // The request may have been accepted. Query, never resend.
      }
    }
    
    const deadline = this.clock() + (this.timeout * 1000); // Convert to milliseconds
    
    while (true) {
      if (status === null) {
        status = await this._request(
          original.selected_node,
          {
            operation: 'status',
            job_id: original.job_id,
            attempt_id: original.attempt_id
          },
          original.selected_device_id
        );
      }
      
      if (typeof status !== 'object') {
        throw new TransportUnresolved('attempt is not known by the node');
      }
      
      if (status.job_id !== original.job_id ||
          status.attempt_id !== original.attempt_id ||
          status.selected_node !== original.selected_node ||
          status.target_language !== original.target_language) {
        throw new TransportUnresolved('status identity mismatch');
      }
      
      const state = status.status;
      
      if (state === 'completed') {
        const response = status.response;
        
        if (typeof response !== 'object' ||
            response.status !== 'ok' ||
            response.job_id !== original.job_id ||
            response.selected_node !== original.selected_node ||
            response.target_language !== original.target_language ||
            typeof response.code !== 'string' ||
            !response.code.trim()) {
          throw new TransportUnresolved('invalid translation result');
        }
        
        entry.response = response;
        entry.status = 'completed';
        this.save(this.state);
        await this._release(original, entry);
        return response;
      }
      
      if (state === 'failed' || state === 'unknown') {
        entry.status = state;
        this.save(this.state);
        if (state === 'failed') {
          await this._release(original, entry);
        }
        throw new TransportUnresolved('attempt requires reconciliation');
      }
      
      if (state !== 'running' || this.clock() >= deadline) {
        throw new TransportUnresolved('attempt is unresolved');
      }
      
      await this.sleep(this.interval * 1000); // Convert to milliseconds
      status = null;
    }
  }
}

module.exports = { GatewayTransport, TransportUnresolved, gatewayToken };
