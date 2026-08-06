#!/usr/bin/env python3
"""Baut aus web/artifact_template.html + data/latest.json die fertige
Uebersichtsseite telegram-monitor-uebersicht.html (eine Datei, offline nutzbar).

  python cli.py scan --json > /tmp/scan.json     # optional: frische Daten
  python build_artifact.py
"""
from __future__ import annotations

import json
import os
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = os.path.join(ROOT, "web", "artifact_template.html")
DATA = os.path.join(ROOT, "data", "latest.json")
OUT = os.path.join(os.path.dirname(ROOT), "telegram-monitor-uebersicht.html")


def build(data_path: str = DATA, out_path: str = OUT) -> str:
    with open(TEMPLATE, "r", encoding="utf-8") as fh:
        tpl = fh.read()
    with open(data_path, "r", encoding="utf-8") as fh:
        data = json.load(fh)
    payload = json.dumps(data, ensure_ascii=False).replace("</", "<\\/")
    html = tpl.replace("/*__DATA__*/{}", payload)
    with open(out_path, "w", encoding="utf-8") as fh:
        fh.write(html)
    return out_path


if __name__ == "__main__":
    path = build(sys.argv[1] if len(sys.argv) > 1 else DATA)
    print(f"geschrieben: {path} ({os.path.getsize(path)} Bytes)")
