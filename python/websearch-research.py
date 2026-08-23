#!/usr/bin/env python3
# websearch-research.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/websearch-research.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

# Web Search Script: Deep Research für Incidents
# Verwendung: ./websearch-research.py "Beschreibung des Problems"

import os
import sys
import json
import requests
from datetime import datetime

def main():
    QUERY = sys.argv[1] if len(sys.argv) > 1 else None
    OUTPUT_DIR = sys.argv[2] if len(sys.argv) > 2 else "./research"

    if not QUERY:
        print("Verwendung: {} \"Problem Beschreibung\" [OUTPUT_DIR]".format(sys.argv[0]))
        sys.exit(1)

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    OUTPUT_FILE = os.path.join(OUTPUT_DIR, f"incident_{timestamp}.md")

    with open(OUTPUT_FILE, "w") as f:
        f.write("# Incident Research\n")
        f.write(f"Datum: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Query: {QUERY}\n\n")

        # 1. EXA für schnelle Recherche
        f.write("## 1. Schnelle Recherche (EXA)\n")
        try:
            response = requests.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {os.environ['OPENROUTER_API_KEY']}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "openai/gpt-5.6-terra",
                    "messages": [{"role": "user", "content": QUERY}],
                    "plugins": [{"id": "web", "engine": "exa", "max_results": 5}]
                },
                timeout=30
            )
            response.raise_for_status()
            data = response.json()
            content = data.get("choices", [{}])[0].get("message", {}).get("content", "Keine Ergebnisse")
            f.write(content + "\n")
        except Exception as e:
            f.write(f"Fehler bei der Abfrage: {str(e)}\n")

        f.write("\n---\n")

        # 2. Verifizierte Quellen (Perplexity) falls verfügbar
        f.write("## 2. Verifizierte Fakten (Perplexity)\n")
        try:
            response = requests.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {os.environ['OPENROUTER_API_KEY']}"
                },
                json={
                    "model": "perplexity/sonar:online",
                    "messages": [{"role": "user", "content": f"{QUERY} troubleshooting"}]
                },
                timeout=30
            )
            response.raise_for_status()
            data = response.json()
            content = data.get("choices", [{}])[0].get("message", {}).get("content", "Keine Ergebnisse")
            f.write(content + "\n")
        except Exception as e:
            f.write(f"Fehler bei der Abfrage: {str(e)}\n")

    print(f"Gespeichert in: {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
