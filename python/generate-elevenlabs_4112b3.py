#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "3247e2561ffa9edee0c8b882f756cb288e3d68b6a6231f52769e0be1bd2f94ba", "source_sha256": "4112b3dbe78c8a495b73f6feaebe05ada553911d2e25f6bd1e2e4d704a6ac1b6", "target_language": "python"}
# generate-elevenlabs.mjs — portiert nach python
# Quelle: javascript, Onboarding@main:scripts/generate-elevenlabs.mjs
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

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
    data = {
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
        async with session.post(url, headers=headers, json=data) as response:
            if response.status != 200:
                raise Exception(f'ElevenLabs fehlgeschlagen: {response.status}')
            
            audio_data = await response.read()
            
            # Create directory
            audio_dir = Path(__file__).parent.parent / 'public' / 'audio'
            audio_dir.mkdir(parents=True, exist_ok=True)
            
            # Write audio file
            audio_file = audio_dir / 'project-narration.mp3'
            async with aiofiles.open(audio_file, 'wb') as f:
                await f.write(audio_data)
            
            # Write metadata
            metadata = {
                'model': 'eleven_multilingual_v2',
                'voiceId': voice_id,
                'characters': len(text),
                'text': text,
                'output': 'public/audio/project-narration.mp3'
            }
            
            metadata_file = Path(__file__).parent / 'media-production' / 'elevenlabs-result.json'
            metadata_file.parent.mkdir(parents=True, exist_ok=True)
            
            async with aiofiles.open(metadata_file, 'w') as f:
                await f.write(json.dumps(metadata, indent=2))
    
    print(f'ElevenLabs abgeschlossen: {len(text)} Zeichen.')

if __name__ == '__main__':
    asyncio.run(main())
