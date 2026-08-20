#!/usr/bin/env python3
# test-agent.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-agent.sh
# auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-agent.sh
# auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-agent.sh
# auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-agent.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import json
import tempfile
import requests

# Ensure PERPLEXITY_API_KEY is set
PERPLEXITY_API_KEY = os.environ.get('PERPLEXITY_API_KEY')
if not PERPLEXITY_API_KEY:
    raise ValueError("PERPLEXITY_API_KEY is required")

# Get prompt from command line or use default
prompt = sys.argv[1] if len(sys.argv) > 1 else "Compare recent open-source LLMs in terms of performance, licensing, and practical use."

# Create temporary file path
tmpdir = os.environ.get('TMPDIR', '/tmp')
out_file = os.path.join(tmpdir, 'perplexity-agent-test.json')

# Prepare request data
data = {
    "preset": "fast-search",
    "input": prompt
}

# Make API request
headers = {
    "Authorization": f"Bearer {PERPLEXITY_API_KEY}",
    "Content-Type": "application/json"
}

try:
    response = requests.post(
        "https://api.perplexity.ai/v1/agent",
        headers=headers,
        json=data
    )
    
    # Write response to file
    with open(out_file, 'w') as f:
        f.write(response.text)
    
    # Print HTTP status code
    print(f"agent_http={response.status_code}")
    
    # Process and print JSON response
    response_data = response.json()
    
    # Extract relevant fields
    result = {
        "keys": list(response_data.keys()),
        "id": response_data.get("id"),
        "status": response_data.get("status"),
        "output_count": len(response_data.get("output", [])),
        "error": response_data.get("error")
    }
    
    print(json.dumps(result, indent=2))
    
except requests.exceptions.RequestException as e:
    print(f"Error making request: {e}", file=sys.stderr)
    sys.exit(1)
except json.JSONDecodeError as e:
    print(f"Error parsing JSON response: {e}", file=sys.stderr)
    sys.exit(1)
