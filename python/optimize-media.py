#!/usr/bin/env python3
# optimize-media.mjs — portiert nach python
# Quelle: javascript, Onboarding@main:scripts/optimize-media.mjs
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import asyncio
import os
from pathlib import Path
from urllib.parse import urljoin
from urllib.request import url2pathname

import aiofiles
import aiohttp
from PIL import Image


async def main():
    # Verzeichnis bestimmen (relativ zum Skript)
    script_dir = Path(__file__).parent
    media_dir = script_dir.parent / "public" / "media"
    
    # Alle Dateien im Verzeichnis durchgehen
    for file in os.listdir(media_dir):
        if not file.endswith(".png"):
            continue
            
        source_path = media_dir / file
        stem = Path(file).stem
        
        # WebP-Version erzeugen
        webp_path = media_dir / f"{stem}.webp"
        with Image.open(source_path) as img:
            img.save(webp_path, "webp", quality=84)
        
        # AVIF-Version erzeugen
        avif_path = media_dir / f"{stem}.avif"
        with Image.open(source_path) as img:
            img.save(avif_path, "avif", quality=58)
    
    print("WebP- und AVIF-Derivate erzeugt.")


if __name__ == "__main__":
    asyncio.run(main())
