#!/usr/bin/env python3
# generate-wavespeed.mjs — portiert nach python
# Quelle: javascript, Onboarding@main:scripts/generate-wavespeed.mjs
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import os
import json
import base64
import asyncio
import aiohttp
import aiofiles
from urllib.parse import urljoin
import time

async def main():
    key = os.environ.get("WAVESPEED_API_KEY")
    if not key:
        raise Exception("WAVESPEED_API_KEY fehlt.")

    script_dir = os.path.dirname(os.path.abspath(__file__))
    jobs_path = os.path.join(script_dir, "..", "media-production", "wavespeed-jobs.json")
    raw_dir = os.path.join(script_dir, "..", "media-production", "raw")
    public_dir = os.path.join(script_dir, "..", "public", "media")
    result_url = os.path.join(script_dir, "..", "media-production", "wavespeed-results.json")

    os.makedirs(raw_dir, exist_ok=True)
    os.makedirs(public_dir, exist_ok=True)

    async with aiofiles.open(jobs_path, "r", encoding="utf-8") as f:
        jobs = json.loads(await f.read())

    try:
        async with aiofiles.open(result_url, "r", encoding="utf-8") as f:
            log = json.loads(await f.read())
    except:
        log = []

    async with aiohttp.ClientSession() as session:
        for job in jobs:
            raw_path = os.path.join(raw_dir, f"{job['id']}.png")
            target_path = os.path.join(public_dir, f"{job['output']}.png")

            if os.path.exists(raw_path):
                if not any(entry.get("id") == job["id"] for entry in log):
                    log.append({
                        "id": job["id"],
                        "requestId": "completed-before-resume",
                        "model": "google/nano-banana-2/edit",
                        "resolution": "4k",
                        "plannedCostUsd": 0.14,
                        "output": os.path.basename(target_path)
                    })
                    async with aiofiles.open(result_url, "w") as f:
                        await f.write(json.dumps(log, indent=2))
                print(f"Übersprungen: {job['id']} ist bereits vorhanden.")
                continue

            images = []
            for image in job["images"]:
                if image.startswith("http:") or image.startswith("https:") or image.startswith("data:"):
                    images.append(image)
                else:
                    full_image_path = os.path.join(script_dir, "..", image)
                    async with aiofiles.open(full_image_path, "rb") as f:
                        bytes_data = await f.read()
                        images.append(f"data:image/png;base64,{base64.b64encode(bytes_data).decode('utf-8')}")

            headers = {
                "Authorization": f"Bearer {key}",
                "Content-Type": "application/json"
            }
            payload = {
                "prompt": job["prompt"],
                "images": images,
                "aspect_ratio": job["aspectRatio"],
                "resolution": "4k",
                "output_format": "png",
                "enable_web_search": False,
                "enable_image_search": False,
                "enable_sync_mode": False,
                "enable_base64_output": False,
            }

            async with session.post("https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit", headers=headers, json=payload) as response:
                if response.status != 200:
                    detail = await response.text()
                    raise Exception(f"WaveSpeed submit fehlgeschlagen: {response.status} {detail}")
                submitted = await response.json()

            request_id = submitted.get("data", {}).get("id") or submitted.get("id")

            result = None
            for attempt in range(90):
                await asyncio.sleep(4)
                async with session.get(f"https://api.wavespeed.ai/api/v3/predictions/{request_id}/result", headers={"Authorization": f"Bearer {key}"}) as poll_response:
                    result = await poll_response.json()
                    if result.get("data", {}).get("status") == "completed":
                        break
                    if result.get("data", {}).get("status") == "failed":
                        raise Exception(f"WaveSpeed job fehlgeschlagen: {job['id']}")

            url = result.get("data", {}).get("outputs", [None])[0]
            if not url:
                raise Exception(f"Kein Output für {job['id']}")

            async with session.get(url) as img_response:
                bytes_data = await img_response.read()

            async with aiofiles.open(raw_path, "wb") as f:
                await f.write(bytes_data)
            async with aiofiles.open(target_path, "wb") as f:
                await f.write(bytes_data)

            log.append({
                "id": job["id"],
                "requestId": request_id,
                "model": "google/nano-banana-2/edit",
                "resolution": "4k",
                "plannedCostUsd": 0.14,
                "output": os.path.basename(target_path)
            })
            async with aiofiles.open(result_url, "w") as f:
                await f.write(json.dumps(log, indent=2))
            print(f"Abgeschlossen: {job['id']}")

        async with aiofiles.open(result_url, "w") as f:
            await f.write(json.dumps(log, indent=2))
        print(f"WaveSpeed abgeschlossen: {len(log)} Assets, geplante Basiskosten ${len(log) * 0.14:.2f}.")

if __name__ == "__main__":
    asyncio.run(main())
