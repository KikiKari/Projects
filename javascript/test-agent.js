#!/usr/bin/env node
// test-agent.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-agent.sh
// auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-agent.sh
// auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-agent.sh
// auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-agent.sh
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import os from 'os';
import path from 'path';
import { fileURLToPath } from 'url';
import process from 'process';

// Get the directory name in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Check for required environment variable
if (!process.env.PERPLEXITY_API_KEY) {
  console.error('PERPLEXITY_API_KEY is required');
  process.exit(1);
}

// Get prompt from command line argument or use default
const prompt = process.argv[2] || 'Compare recent open-source LLMs in terms of performance, licensing, and practical use.';
const out = process.env.TMPDIR || os.tmpdir();
const outFile = path.join(out, 'perplexity-agent-test.json');

try {
  // Create the JSON payload
  const postData = JSON.stringify({
    preset: 'fast-search',
    input: prompt
  });

  // Make the API request using fetch
  const response = await fetch('https://api.perplexity.ai/v1/agent', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.PERPLEXITY_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: postData
  });

  // Read response body as text first
  const responseBody = await response.text();
  
  // Write response to file
  fs.writeFileSync(outFile, responseBody);
  
  // Parse the JSON for processing
  const jsonData = JSON.parse(responseBody);
  
  // Output HTTP status code
  console.log(`agent_http=${response.status}`);
  
  // Process and output the JSON data similar to the original jq command
  const result = {
    keys: Object.keys(jsonData),
    id: jsonData.id || null,
    status: jsonData.status || null,
    output_count: (jsonData.output || []).length,
    error: jsonData.error || null
  };
  
  console.log(JSON.stringify(result, null, 2));
  
} catch (error) {
  console.error('Error:', error.message);
  process.exit(1);
}
