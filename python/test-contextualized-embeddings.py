#!/usr/bin/env python3
# test-contextualized-embeddings.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-contextualized-embeddings.sh
# auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-contextualized-embeddings.sh
# auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-contextualized-embeddings.sh
# auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-contextualized-embeddings.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import json
import tempfile
import requests

# Ensure PERPLEXITY_API_KEY is set
PERPLEXITY_API_KEY = os.environ.get('PERPLEXITY_API_KEY')
if not PERPLEXITY_API_KEY:
    print("PERPLEXITY_API_KEY is required", file=sys.stderr)
    sys.exit(1)

# Create temporary file path
out = os.path.join(tempfile.gettempdir(), 'perplexity-contextualized-embeddings-test.json')

# Prepare payload
payload = {
    "input": [
        [
            "OpenClaw can route web search through Perplexity.",
            "The Perplexity MCP server exposes search and reasoning tools.",
            "Contextualized embeddings improve document chunk retrieval."
        ]
    ],
    "model": "pplx-embed-context-v1-4b"
}

# Make API request
headers = {
    "Authorization": f"Bearer {PERPLEXITY_API_KEY}",
    "Content-Type": "application/json"
}

try:
    response = requests.post(
        "https://api.perplexity.ai/v1/contextualizedembeddings",
        headers=headers,
        json=payload
    )
    
    # Write response to file
    with open(out, 'w') as f:
        f.write(response.text)
    
    # Output HTTP status code
    print(f"contextualized_embeddings_http={response.status_code}")
    
    # Process and output JSON structure
    data = response.json()
    
    # Extract information similar to the jq command
    result = {
        "keys": list(data.keys()),
        "model": data.get("model", None),
        "document_count": len(data.get("data", [])),
        "first_chunk_count": len(data.get("data", [{}])[0].get("data", [])) if data.get("data") else 0,
        "error": data.get("error", None)
    }
    
    print(json.dumps(result, indent=2))
    
except requests.exceptions.RequestException as e:
    print(f"Error making request: {e}", file=sys.stderr)
    sys.exit(1)
except json.JSONDecodeError as e:
    print(f"Error parsing JSON response: {e}", file=sys.stderr)
    sys.exit(1)
