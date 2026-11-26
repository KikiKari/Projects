#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "b071c81612c23bd8b195c6f85f5fe2ef2ef6e3818c6c2b85f303a0dacbd09237", "source_sha256": "3fed8b6be2b9b8639b55bcaf18c09c0395ac005ab02c27f2dff26ca20b5d5825", "target_language": "python"}
# generate-wavespeed.mjs — portiert nach python
# Quelle: javascript, Onboarding@main:scripts/generate-wavespeed.mjs
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import json
import base64
import asyncio
import aiohttp
from pathlib import Path
from urllib.parse import urlparse

async def main():
    key = os.environ.get('WAVESPEED_API_KEY')
    if not key:
        raise Exception("WAVESPEED_API_KEY fehlt.")

    script_dir = Path(__file__).parent
    jobs_path = script_dir / "../media-production/wavespeed-jobs.json"
    raw_dir = script_dir / "../media-production/raw/"
    public_dir = script_dir / "../public/media/"
    result_url = script_dir / "../media-production/wavespeed-results.json"

    raw_dir.mkdir(parents=True, exist_ok=True)
    public_dir.mkdir(parents=True, exist_ok=True)

    with open(jobs_path, 'r', encoding='utf-8') as f:
        jobs = json.load(f)

    if result_url.exists():
        with open(result_url, 'r', encoding='utf-8') as f:
            log = json.load(f)
    else:
        log = []

    async with aiohttp.ClientSession() as session:
        for job in jobs:
            raw_path = raw_dir / f"{job['id']}.png"
            target_path = public_dir / f"{job['output']}.png"
            
            if raw_path.exists():
                if not any(entry.get('id') == job['id'] for entry in log):
                    log.append({
                        "id": job['id'],
                        "requestId": "completed-before-resume",
                        "model": "google/nano-banana-2/edit",
                        "resolution": "4k",
                        "plannedCostUsd": 0.14,
                        "output": target_path.name
                    })
                    with open(result_url, 'w', encoding='utf-8') as f:
                        json.dump(log, f, indent=2, ensure_ascii=False)
                
                print(f"Übersprungen: {job['id']} ist bereits vorhanden.")
                continue

            images_data = []
            for image in job['images']:
                if image.startswith(('http:', 'https:', 'data:')):
                    images_data.append(image)
                else:
                    image_path = script_dir / f"../{image}"
                    with open(image_path, 'rb') as img_file:
                        image_bytes = img_file.read()
                        encoded = base64.b64encode(image_bytes).decode('utf-8')
                        images_data.append(f"data:image/png;base64,{encoded}")

            payload = {
                "prompt": job['prompt'],
                "images": images_data,
                "aspect_ratio": job['aspectRatio'],
                "resolution": "4k",
                "output_format": "png",
                "enable_web_search": False,
                "enable_image_search": False,
                "enable_sync_mode": False,
                "enable_base64_output": False,
            }

            headers = {
                "Authorization": f"Bearer {key}",
                "Content-Type": "application/json"
            }

            async with session.post(
                "https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit",
                headers=headers,
                json=payload
            ) as response:
                if not response.ok:
                    detail = await response.text()
                    raise Exception(f"WaveSpeed submit fehlgeschlagen: {response.status} {detail}")
                
                submitted = await response.json()
                request_id = submitted.get('data', {}).get('id') or submitted.get('id')

                result = None
                for attempt in range(90):
                    await asyncio.sleep(4)
                    async with session.get(
                        f"https://api.wavespeed.ai/api/v3/predictions/{request_id}/result",
                        headers={"Authorization": f"Bearer {key}"}
                    ) as poll_response:
                        result = await poll_response.json()
                        if result.get('data', {}).get('status') == "completed":
                            break
                        if result.get('data', {}).get('status') == "failed":
                            raise Exception(f"WaveSpeed job fehlgeschlagen: {job['id']}")

                url = result.get('data', {}).get('outputs', [None])[0]
                if not url:
                    raise Exception(f"Kein Output für {job['id']}")

                async with session.get(url) as img_response:
                    bytes_data = await img_response.read()
                    
                with open(raw_path, 'wb') as f:
                    f.write(bytes_data)
                    
                with open(target_path, 'wb') as f:
                    f.write(bytes_data)

                log.append({
                    "id": job['id'],
                    "requestId": request_id,
                    "model": "google/nano-banana-2/edit",
                    "resolution": "4k",
                    "plannedCostUsd": 0.14,
                    "output": target_path.name
                })
                
                with open(result_url, 'w', encoding='utf-8') as f:
                    json.dump(log, f, indent=2, ensure_ascii=False)
                    
                print(f"Abgeschlossen: {job['id']}")

        with open(result_url, 'w', encoding='utf-8') as f:
            json.dump(log, f, indent=2, ensure_ascii=False)
            
        print(f"WaveSpeed abgeschlossen: {len(log)} Assets, geplante Basiskosten ${(len(log) * 0.14):.2f}.")

if __name__ == "__main__":
    asyncio.run(main())
