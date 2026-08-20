#!/usr/bin/env python3
# test-search.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-search.sh
# auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-search.sh
# auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-search.sh
# auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-search.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import json
import tempfile
import requests

# Ensure required environment variable is set
PERPLEXITY_API_KEY = os.environ.get('PERPLEXITY_API_KEY')
if not PERPLEXITY_API_KEY:
    raise ValueError("PERPLEXITY_API_KEY is required")

# Get command line arguments or defaults
query = sys.argv[1] if len(sys.argv) > 1 else "Perplexity API Platform"
max_results = int(os.environ.get('PERPLEXITY_MAX_RESULTS', '3'))
max_tokens_per_page = int(os.environ.get('PERPLEXITY_MAX_TOKENS_PER_PAGE', '256'))

# Create temporary output file
out = os.path.join(tempfile.gettempdir(), 'perplexity-search-test.json')

# Prepare request data
data = {
    'query': query,
    'max_results': max_results,
    'max_tokens_per_page': max_tokens_per_page
}

# Make API request
headers = {
    'Authorization': f'Bearer {PERPLEXITY_API_KEY}',
    'Content-Type': 'application/json'
}

try:
    response = requests.post(
        'https://api.perplexity.ai/search',
        headers=headers,
        json=data
    )
    
    # Write response to file
    with open(out, 'w') as f:
        f.write(response.text)
    
    # Output HTTP status code
    print(f"search_http={response.status_code}")
    
    # Parse and process response
    response_data = response.json()
    
    # Extract results or data array, handle missing cases
    results = response_data.get('results') or response_data.get('data') or []
    
    # Get first result or None
    first_result = results[0] if results else None
    
    # Output processed data
    output = {
        'keys': list(response_data.keys()),
        'result_count': len(results),
        'first': first_result
    }
    
    print(json.dumps(output, indent=2))
    
except requests.exceptions.RequestException as e:
    print(f"Error making request: {e}", file=sys.stderr)
    sys.exit(1)
except json.JSONDecodeError as e:
    print(f"Error parsing JSON response: {e}", file=sys.stderr)
    sys.exit(1)
