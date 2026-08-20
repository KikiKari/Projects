#!/usr/bin/env node
// test-embeddings.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-embeddings.sh
// auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-embeddings.sh
// auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-embeddings.sh
// auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-embeddings.sh
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import os from 'os';
import https from 'https';
import { spawnSync } from 'child_process';

// Prüfe ob PERPLEXITY_API_KEY gesetzt ist
if (!process.env.PERPLEXITY_API_KEY) {
  console.error('PERPLEXITY_API_KEY is required');
  process.exit(1);
}

const out = `${os.tmpdir()}/perplexity-embeddings-test.json`;

const payload = JSON.stringify({
  input: [
    "Scientists explore the universe driven by curiosity.",
    "Curiosity compels us to seek explanations, not just observations.",
    "Historical discoveries began with curious questions.",
    "The pursuit of knowledge distinguishes human curiosity from mere stimulus response.",
    "Philosophy examines the nature of curiosity."
  ],
  model: "pplx-embed-v1-4b"
});

const options = {
  hostname: 'api.perplexity.ai',
  port: 443,
  path: '/v1/embeddings',
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${process.env.PERPLEXITY_API_KEY}`,
    'Content-Type': 'application/json',
    'Content-Length': payload.length
  }
};

let responseData = '';

const req = https.request(options, (res) => {
  res.on('data', (chunk) => {
    responseData += chunk;
  });

  res.on('end', () => {
    // Schreibe Antwort in temporäre Datei
    fs.writeFileSync(out, responseData);
    
    // Gebe HTTP Status Code aus
    console.log(`embeddings_http=${res.statusCode}`);
    
    // Parse und formatiere die Antwort
    try {
      const data = JSON.parse(responseData);
      const result = {
        keys: Object.keys(data),
        model: data.model || null,
        item_count: (data.data || []).length,
        first_dim: ((data.data || [])[0]?.embedding || []).length,
        error: data.error || null
      };
      console.log(JSON.stringify(result, null, 2));
    } catch (parseError) {
      console.error('Fehler beim Parsen der Antwort:', parseError.message);
    }
  });
});

req.on('error', (error) => {
  console.error('Request Fehler:', error.message);
  process.exit(1);
});

req.write(payload);
req.end();
