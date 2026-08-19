#!/usr/bin/env python3
# secret-scan.mjs — portiert nach python
# Quelle: javascript, Onboarding@main:scripts/secret-scan.mjs
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import os
import re
import sys
from pathlib import Path

root = Path(__file__).parent.parent
skipped = {
    "node_modules",
    ".next",
    ".git",
    ".pytest_cache",
    "__pycache__",
    "media-production/raw",
    "media-production/private",
}
patterns = [
    re.compile(r"sk-(?:proj|svcacct|ant|or-v1|admin)-[A-Za-z0-9_-]{20,}"),
    re.compile(r"(?:nvapi|lin_api|ntn|vcp)_[A-Za-z0-9_-]{20,}"),
    re.compile(r"ELEVENLABS_API_KEY\s*=\s*['\"]?[A-Za-z0-9]{20,}"),
    re.compile(r"WAVESPEED_API_KEY\s*=\s*['\"]?[A-Za-z0-9]{20,}"),
]
findings = []

def walk(directory, relative=""):
    try:
        entries = os.listdir(directory)
    except (OSError, PermissionError):
        return

    for entry in entries:
        rel = os.path.join(relative, entry)
        entry_path = os.path.join(directory, entry)

        # Skip .env files and directories in the skipped set
        if (
            entry == ".env"
            or (entry.startswith(".env.") and entry != ".env.example")
            or any(
                rel == item
                or rel.startswith(f"{item}{os.sep}")
                or item in rel.split(os.sep)
                for item in skipped
            )
        ):
            continue

        try:
            if os.path.isdir(entry_path):
                walk(entry_path, rel)
            elif os.path.getsize(entry_path) < 2_000_000:
                try:
                    with open(entry_path, "r", encoding="utf-8", errors="ignore") as f:
                        content = f.read()
                except (OSError, PermissionError):
                    content = ""

                for pattern in patterns:
                    if pattern.search(content):
                        findings.append(rel)
                        break
        except (OSError, PermissionError):
            continue

walk(root)

unique_findings = list(set(findings))
if unique_findings:
    print(f"Secret-Scan fehlgeschlagen: {', '.join(unique_findings)}", file=sys.stderr)
    sys.exit(1)

print("Secret-Scan bestanden.")
