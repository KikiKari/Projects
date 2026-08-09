#!/usr/bin/env python3
# generate-elevenlabs.mjs — portiert nach python
# Quelle: javascript, Onboarding@main:scripts/generate-elevenlabs.mjs
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import os
import json
import asyncio
import aiohttp
import aiofiles
from pathlib import Path

async def main():
    key = os.environ.get('ELEVENLABS_API_KEY')
    voice_id = os.environ.get('ELEVENLABS_VOICE_ID', 'JBFqnCBsd6RMkjVDRZzb')
    
    if not key:
        raise Exception('ELEVENLABS_API_KEY fehlt.')
    
    text = 'Neun Projekte. Zwei Plattformen. Ein Ort, an dem Ideen verbunden und weiterentwickelt werden.'
    
    url = f'https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format=mp3_44100_128'
    headers = {
        'xi-api-key': key,
        'Content-Type': 'application/json'
    }
    payload = {
        'text': text,
        'model_id': 'eleven_multilingual_v2',
        'voice_settings': {
            'stability': 0.58,
            'similarity_boost': 0.72,
            'style': 0.18,
            'use_speaker_boost': True
        }
    }
    
    async with aiohttp.ClientSession() as session:
        async with session.post(url, headers=headers, json=payload) as response:
            if response.status != 200:
                raise Exception(f'ElevenLabs fehlgeschlagen: {response.status}')
            
            audio_data = await response.read()
            
            # Create directories
            audio_dir = Path(__file__).parent.parent / 'public' / 'audio'
            audio_dir.mkdir(parents=True, exist_ok=True)
            
            # Write audio file
            audio_path = audio_dir / 'project-narration.mp3'
            async with aiofiles.open(audio_path, 'wb') as f:
                await f.write(audio_data)
            
            # Write JSON result
            result_data = {
                'model': 'eleven_multilingual_v2',
                'voiceId': voice_id,
                'characters': len(text),
                'text': text,
                'output': 'public/audio/project-narration.mp3'
            }
            
            media_production_dir = Path(__file__).parent.parent / 'media-production'
            media_production_dir.mkdir(parents=True, exist_ok=True)
            
            result_path = media_production_dir / 'elevenlabs-result.json'
            async with aiofiles.open(result_path, 'w') as f:
                await f.write(json.dumps(result_data, indent=2))
    
    print(f'ElevenLabs abgeschlossen: {len(text)} Zeichen.')

if __name__ == '__main__':
    asyncio.run(main())
