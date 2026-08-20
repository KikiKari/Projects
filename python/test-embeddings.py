#!/usr/bin/env python3
# test-embeddings.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-embeddings.sh
# auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-embeddings.sh
# auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-embeddings.sh
# auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-embeddings.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import json
import tempfile
import requests

def main():
    # Check for required environment variable
    api_key = os.environ.get('PERPLEXITY_API_KEY')
    if not api_key:
        print("PERPLEXITY_API_KEY is required", file=sys.stderr)
        sys.exit(1)

    # Create temporary file path
    tmpdir = os.environ.get('TMPDIR', '/tmp')
    out_file = os.path.join(tmpdir, 'perplexity-embeddings-test.json')

    # Prepare payload
    payload = {
        "input": [
            "Scientists explore the universe driven by curiosity.",
            "Curiosity compels us to seek explanations, not just observations.",
            "Historical discoveries began with curious questions.",
            "The pursuit of knowledge distinguishes human curiosity from mere stimulus response.",
            "Philosophy examines the nature of curiosity."
        ],
        "model": "pplx-embed-v1-4b"
    }

    # Make API request
    try:
        response = requests.post(
            'https://api.perplexity.ai/v1/embeddings',
            headers={
                'Authorization': f'Bearer {api_key}',
                'Content-Type': 'application/json'
            },
            json=payload
        )
        
        # Save response to file
        with open(out_file, 'w') as f:
            f.write(response.text)
            
        code = response.status_code
        
    except Exception as e:
        print(f"Error making request: {e}", file=sys.stderr)
        sys.exit(1)

    # Output HTTP status code
    print(f"embeddings_http={code}")

    # Process and display response summary
    try:
        with open(out_file, 'r') as f:
            data = json.load(f)
            
        # Extract information similar to jq filter
        result = {
            'keys': list(data.keys()) if isinstance(data, dict) else [],
            'model': data.get('model', None),
            'item_count': len(data.get('data', [])),
            'first_dim': len(data.get('data', [{}])[0].get('embedding', [])) if data.get('data') else 0,
            'error': data.get('error', None)
        }
        
        print(json.dumps(result, indent=2))
        
    except Exception as e:
        print(f"Error processing response: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
