#!/usr/bin/env node
// gateway_transport.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/gateway_transport.py
// Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

/** Gateway-authenticated transport with manager-owned attempt records.

An attempt is saved before submission. If its outcome is uncertain, subsequent
calls only query the same node and attempt; they do not submit it again.
*/

class TransportUnresolved extends Error {
  constructor(message) {
    super(message);
    this.name = 'TransportUnresolved';
  }
}

function gatewayToken() {
  /** Use the local Gateway credential without changing its configuration. */
  const token = (process.env.OPENCLAW_GATEWAY_TOKEN || '').trim();
  if (token) {
    return token;
  }
  
  const configPath = process.env.OPENCLAW_CONFIG_PATH || 
    require('path').join(require('os').homedir(), '.openclaw', 'openclaw.json');
  
  try {
    const fs = require('fs');
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    const token = config?.gateway?.auth?.token;
    return (typeof token === 'string' && !token.startsWith('${')) ? token.trim() : '';
  } catch (error) {
    return '';
  }
}

class GatewayTransport {
  constructor(state, save, url, token, { timeout = 3900, interval = 3, opener = null, clock = null, sleep = null } = {}) {
    const { URL } = require('url');
    let parsed;
    try {
      parsed = new URL(url);
    } catch (error) {
      throw new Error('invalid Gateway URL');
    }
    
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
    this.clock = clock || (() => process.hrtime.bigint() / BigInt(1e6));
    this.sleep = sleep || ((ms) => new Promise(resolve => setTimeout(resolve, ms)));
  }
  
  async _defaultOpener(request, timeoutMs) {
    const https = require('https');
    const http = require('http');
    
    return new Promise((resolve, reject) => {
      const protocol = request.url.startsWith('https:') ? https : http;
      const req = protocol.request(request, (res) => {
        let data = Buffer.alloc(0);
        
        res.on('data', (chunk) => {
          data = Buffer.concat([data, chunk]);
          if (data.length > 4_000_000) {
            res.destroy();
            reject(new Error('response too large'));
          }
        });
        
        res.on('end', () => {
          resolve({ statusCode: res.statusCode, headers: res.headers, data });
        });
      });
      
      req.on('error', reject);
      req.setTimeout(timeoutMs, () => {
        req.destroy();
        reject(new Error('Request timeout'));
      });
      
      if (request.method === 'POST') {
        req.write(request.body);
      }
      req.end();
    });
  }
  
  async _request(node, request, deviceId = null) {
    const payload = JSON.stringify({ node, device_id: deviceId, request });
    
    const httpRequest = {
      url: this.url,
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json'
        // Note: Content-Length will be set automatically by Node.js
      },
      body: payload
    };
    
    const timeoutMs = node === 'node4' ? 150000 : 40000;
    
    try {
      const result = await this.opener(httpRequest, timeoutMs);
      
      if (result.data.length > 4_000_000) {
        throw new Error('response too large');
      }
      
      const data = JSON.parse(result.data.toString());
      
      if (typeof data !== 'object' || data === null || !('result' in data)) {
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
    if (typeof result !== 'object' || result === null) {
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
      
      if (typeof result === 'object' && result.status === 'released' &&
          ['job_id', 'attempt_id', 'selected_node', 'target_language'].every(
            key => result[key] === original[key]
          )) {
        entry.released = true;
        this.save(this.state);
      }
    } catch (error) {
      // Retry cleanup later; the result is durable in manager state.
      return;
    }
  }
  
  releasePending() {
    const auftraege = this.state.auftraege || {};
    for (const [key, entry] of Object.entries(auftraege)) {
      if (typeof entry === 'object' && entry !== null && 
          ['completed', 'failed', 'unknown'].includes(entry.status) &&
          typeof entry.job === 'object' && entry.job !== null) {
        this._release(entry.job, entry);
      }
    }
  }
  
  async __call__(job) {
    if (!job.source_sha256 || !job.target_language || !job.selected_device_id) {
      throw new Error('missing source identity');
    }
    
    const key = `${job.source_sha256}:${job.target_language}`;
    this.state.auftraege = this.state.auftraege || {};
    const entries = this.state.auftraege;
    let entry = entries[key];
    const fresh = entry === undefined;
    
    let original;
    if (fresh) {
      original = {
        ...job,
        attempt_id: require('crypto').randomUUID()
      };
      entry = { job: original, status: 'submitted' };
      entries[key] = entry;
      // If this write fails there must be no remote submission.
      this.save(this.state);
    } else {
      original = entry.job;
    }
    
    // The dispatcher verifies the job object after transport returns.
    Object.assign(job, original);
    
    if (entry.response !== undefined && entry.response !== null) {
      await this._release(original, entry);
      return entry.response;
    }
    
    if (['failed', 'unknown'].includes(entry.status)) {
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
        if (error instanceof TransportUnresolved) {
          // The request may have been accepted. Query, never resend.
        } else {
          throw error;
        }
      }
    }
    
    const deadline = this.clock() + this.timeout * 1000; // Convert to milliseconds
    
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
      
      if (typeof status !== 'object' || status === null) {
        throw new TransportUnresolved('attempt is not known by the node');
      }
      
      if (['job_id', 'attempt_id', 'selected_node', 'target_language'].some(
        k => status[k] !== original[k]
      )) {
        throw new TransportUnresolved('status identity mismatch');
      }
      
      const state = status.status;
      
      if (state === 'completed') {
        const response = status.response;
        
        if (typeof response !== 'object' || response === null ||
            response.status !== 'ok' ||
            ['job_id', 'selected_node', 'target_language'].some(
              k => response[k] !== original[k]
            ) ||
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
      
      if (['failed', 'unknown'].includes(state)) {
        entry.status = state;
        this.save(this.state);
        await this._release(original, entry);
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

module.exports = { TransportUnresolved, gatewayToken, GatewayTransport };
