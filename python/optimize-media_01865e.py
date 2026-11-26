#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "df5fcb0f1e325b3cdb1c1fa9ae01e9ebea5e9c4d2b4c51ab48b4b6b90fa514a7", "source_sha256": "01865e120d0e52b50fea21a5f976ac63af413e6829f861a5d31d7898bd4dbaf4", "target_language": "python"}
# optimize-media.mjs — portiert nach python
# Quelle: javascript, Onboarding@main:scripts/optimize-media.mjs
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import asyncio
import os
from pathlib import Path
from PIL import Image

async def optimize_media():
    # Bestimme das Verzeichnis relativ zum Skript
    script_dir = Path(__file__).resolve().parent
    media_dir = script_dir.parent / "public" / "media"
    
    # Liste alle Dateien im Verzeichnis auf
    files = os.listdir(media_dir)
    
    for file in files:
        if not file.endswith(".png"):
            continue
            
        source_path = media_dir / file
        stem = file[:-4]  # Entferne .png
        
        # Konvertiere zu WebP
        webp_path = media_dir / f"{stem}.webp"
        with Image.open(source_path) as img:
            # Konvertiere RGBA zu RGB falls nötig für WebP
            if img.mode == 'RGBA':
                background = Image.new('RGB', img.size, (255, 255, 255))
                background.paste(img, mask=img.split()[-1])
                img = background
            img.save(webp_path, 'WEBP', quality=84)
        
        # Konvertiere zu AVIF (über PILLOWAVIF Plugin)
        try:
            avif_path = media_dir / f"{stem}.avif"
            with Image.open(source_path) as img:
                img.save(avif_path, 'AVIF', quality=58)
        except Exception:
            # Fallback: AVIF nicht unterstützt, überspringe
            pass
    
    print("WebP- und AVIF-Derivate erzeugt.")

# Führe die async Funktion aus
asyncio.run(optimize_media())
