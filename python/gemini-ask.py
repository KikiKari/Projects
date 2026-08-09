#!/usr/bin/env python3
# gemini-ask.js — portiert nach python
# Quelle: javascript, OpenClaw@gateway1:scripts/gemini-ask.js
# auch in: OpenClaw@gateway2:scripts/gemini-ask.js
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

"""
gemini-ask.py - CLI tool for Google Gemini API

Usage:
  python gemini-ask.py "Your question here"
  echo "Your question" | python gemini-ask.py
  python gemini-ask.py --file prompt.txt
  python gemini-ask.py --model gemini-pro "Your question"

Environment:
  GEMINI_API_KEY - Required API key
  GEMINI_MODEL   - Optional default model (default: gemini-pro)
"""

import os
import sys
import argparse
import asyncio
import aiohttp
import json

DEFAULT_MODEL = os.environ.get('GEMINI_MODEL', 'gemini-pro')

async def main():
    # Check API key
    api_key = os.environ.get('GEMINI_API_KEY')
    if not api_key:
        print('Error: GEMINI_API_KEY environment variable is required', file=sys.stderr)
        sys.exit(1)

    # Parse arguments
    parser = argparse.ArgumentParser(description='CLI tool for Google Gemini API', add_help=False)
    parser.add_argument('--model', '-m', default=DEFAULT_MODEL, help='Model name')
    parser.add_argument('--system', '-s', default='', help='System prompt')
    parser.add_argument('--file', '-f', help='Read prompt from file')
    parser.add_argument('--help', '-h', action='help', help='Show this help message')
    parser.add_argument('prompt', nargs='*', help='Prompt text')

    args, unknown = parser.parse_known_args()

    # Handle unknown arguments as part of prompt
    prompt_parts = args.prompt + unknown
    prompt = ''

    if args.file:
        try:
            with open(args.file, 'r', encoding='utf-8') as f:
                prompt = f.read()
        except FileNotFoundError:
            print(f'Error: File not found: {args.file}', file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f'Error reading file: {e}', file=sys.stderr)
            sys.exit(1)
    elif prompt_parts:
        prompt = ' '.join(prompt_parts)
    elif not sys.stdin.isatty():
        # Read from stdin
        prompt = sys.stdin.read()
    
    if not prompt.strip():
        print('Error: No prompt provided', file=sys.stderr)
        print('Usage: gemini-ask "your question"', file=sys.stderr)
        print('       gemini-ask --model gemini-pro "your question"', file=sys.stderr)
        print('       echo "your question" | gemini-ask', file=sys.stderr)
        sys.exit(1)

    try:
        # Prepare generation config
        generation_config = {
            'maxOutputTokens': 8192,
            'temperature': 0.7,
            'topP': 0.95,
        }

        # Prepare the API request
        url = f'https://generativelanguage.googleapis.com/v1beta/models/{args.model}:generateContent'
        headers = {
            'Content-Type': 'application/json'
        }
        params = {
            'key': api_key
        }

        if args.system:
            # Use chat with system prompt
            data = {
                'contents': [
                    {'role': 'user', 'parts': [{'text': args.system}]},
                    {'role': 'model', 'parts': [{'text': 'Understood. I will follow that instruction.'}]},
                    {'role': 'user', 'parts': [{'text': prompt}]}
                ],
                'generationConfig': generation_config
            }
        else:
            # Direct generation
            data = {
                'contents': [
                    {'role': 'user', 'parts': [{'text': prompt}]}
                ],
                'generationConfig': generation_config
            }

        async with aiohttp.ClientSession() as session:
            async with session.post(url, headers=headers, params=params, json=data) as response:
                if response.status != 200:
                    error_text = await response.text()
                    print(f'Error: HTTP {response.status} - {error_text}', file=sys.stderr)
                    sys.exit(1)
                
                result = await response.json()
                
                # Extract and print the response text
                try:
                    text = result['candidates'][0]['content']['parts'][0]['text']
                    print(text)
                except (KeyError, IndexError):
                    print('Error: Unexpected response format', file=sys.stderr)
                    print(json.dumps(result, indent=2), file=sys.stderr)
                    sys.exit(1)

    except Exception as error:
        print(f'Error: {error}', file=sys.stderr)
        if 'API key' in str(error):
            print('Make sure GEMINI_API_KEY is set correctly', file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    asyncio.run(main())
