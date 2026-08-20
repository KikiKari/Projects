#!/usr/bin/env node
// test-search.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-search.sh
// auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-search.sh
// auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-search.sh
// auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-search.sh
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import https from 'https';
import os from 'os';
import path from 'path';
import { URL } from 'url';

const apiKey = process.env.PERPLEXITY_API_KEY;
if (!apiKey) {
  console.error('PERPLEXITY_API_KEY is required');
  process.exit(1);
}

const query = process.argv[2] || 'Perplexity API Platform';
const maxResults = parseInt(process.env.PERPLEXITY_MAX_RESULTS || '3', 10);
const maxTokensPerPage = parseInt(process.env.PERPLEXITY_MAX_TOKENS_PER_PAGE || '256', 10);
const tmpDir = process.env.TMPDIR || os.tmpdir();
const outFile = path.join(tmpDir, 'perplexity-search-test.json');

const postData = JSON.stringify({
  query: query,
  max_results: maxResults,
  max_tokens_per_page: maxTokensPerPage
});

const options = {
  hostname: 'api.perplexity.ai',
  port: 443,
  path: '/search',
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${apiKey}`,
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(postData)
  }
};

const req = https.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    fs.writeFileSync(outFile, data);
    
    console.log(`search_http=${res.statusCode}`);
    
    try {
      const jsonData = JSON.parse(data);
      const results = jsonData.results || jsonData.data || [];
      
      const output = {
        keys: Object.keys(jsonData),
        result_count: results.length,
        first: results.length > 0 ? results[0] : null
      };
      
      console.log(JSON.stringify(output, null, 2));
    } catch (parseError) {
      console.error('Failed to parse JSON response');
      process.exit(1);
    }
  });
});

req.on('error', (e) => {
  console.error(`Request error: ${e.message}`);
  process.exit(1);
});

req.write(postData);
req.end();
