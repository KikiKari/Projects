#!/usr/bin/env node
// test-contextualized-embeddings.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-contextualized-embeddings.sh
// auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-contextualized-embeddings.sh
// auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-contextualized-embeddings.sh
// auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-contextualized-embeddings.sh
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import os from 'os';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

if (!process.env.PERPLEXITY_API_KEY) {
  console.error('PERPLEXITY_API_KEY is required');
  process.exit(1);
}

const out = path.join(os.tmpdir(), 'perplexity-contextualized-embeddings-test.json');

const payload = {
  input: [[
    "OpenClaw can route web search through Perplexity.",
    "The Perplexity MCP server exposes search and reasoning tools.",
    "Contextualized embeddings improve document chunk retrieval."
  ]],
  model: "pplx-embed-context-v1-4b"
};

try {
  const response = await fetch("https://api.perplexity.ai/v1/contextualizedembeddings", {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.PERPLEXITY_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(payload)
  });

  const code = response.status;
  const responseData = await response.json();
  
  fs.writeFileSync(out, JSON.stringify(responseData, null, 2));
  
  console.log(`contextualized_embeddings_http=${code}`);
  
  const result = {
    keys: responseData ? Object.keys(responseData) : [],
    model: responseData?.model || null,
    document_count: (responseData?.data || []).length,
    first_chunk_count: (((responseData?.data || [])[0]?.data || [])),
    error: responseData?.error || null
  };
  
  console.log(JSON.stringify(result, null, 2));
  
} catch (error) {
  console.error('Error:', error.message);
  process.exit(1);
}
