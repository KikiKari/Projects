#!/usr/bin/env python3
# websearch-crawl.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/websearch-crawl.sh
# auch in: OpenClaw@gateway2:scripts/websearch-crawl.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

# Web Search Script: Website Crawling mit Firecrawl
# Verwendung: ./websearch-crawl.py <URL> [OUTPUT_DIR]

import os
import sys
import json
import time
import subprocess
from datetime import datetime
import urllib.request
import urllib.error

def get_firecrawl_api_key():
    """API-Schlüssel aus Umgebungsvariable oder openclaw-Konfiguration"""
    key = os.environ.get('FIRECRAWL_API_KEY')
    if key:
        return key
    
    # Fallback auf openclaw.env Konfiguration
    try:
        config_path = os.path.expanduser('~/.openclaw/openclaw.env')
        with open(config_path, 'r') as f:
            for line in f:
                if line.startswith('OPENROUTER'):
                    # Extrahiere Wert zwischen Anführungszeichen
                    parts = line.split('"')
                    if len(parts) >= 2:
                        return parts[1]
    except FileNotFoundError:
        pass
    
    return None

def curl_post(url, headers, data):
    """Führt HTTP POST-Anfrage aus"""
    req = urllib.request.Request(url, data=data.encode('utf-8'), headers=headers)
    try:
        with urllib.request.urlopen(req) as response:
            return response.read().decode('utf-8')
    except urllib.error.HTTPError as e:
        return e.read().decode('utf-8')

def curl_get(url, headers):
    """Führt HTTP GET-Anfrage aus"""
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req) as response:
            return response.read().decode('utf-8')
    except urllib.error.HTTPError as e:
        return e.read().decode('utf-8')

def main():
    if len(sys.argv) < 2:
        print("Verwendung: {} <URL> [OUTPUT_DIR]".format(sys.argv[0]))
        sys.exit(1)
    
    website_url = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else './crawled'
    firecrawl_api_key = get_firecrawl_api_key()
    
    if not firecrawl_api_key:
        print("FIRECRAWL_API_KEY muss gesetzt sein")
        sys.exit(1)
    
    os.makedirs(output_dir, exist_ok=True)
    print(f"Crawling {website_url}...")
    
    # Crawl starten
    headers = {
        "Authorization": f"Bearer {firecrawl_api_key}",
        "Content-Type": "application/json"
    }
    
    crawl_data = {
        "url": website_url,
        "limit": 100,
        "scrapeOptions": {"formats": ["markdown"]}
    }
    
    crawl_response_text = curl_post(
        "https://api.firecrawl.dev/v1/crawl",
        headers,
        json.dumps(crawl_data)
    )
    
    try:
        crawl_response = json.loads(crawl_response_text)
    except json.JSONDecodeError:
        print("Ungültige Antwort vom Server")
        print(crawl_response_text)
        sys.exit(1)
    
    crawl_id = crawl_response.get('id')
    if not crawl_id:
        print("Fehler: Crawl konnte nicht gestartet werden")
        print(json.dumps(crawl_response, indent=2))
        sys.exit(1)
    
    print(f"Crawl ID: {crawl_id}")
    
    # Status prüfen
    while True:
        status_response_text = curl_get(
            f"https://api.firecrawl.dev/v1/crawl/{crawl_id}",
            headers
        )
        
        try:
            status_response = json.loads(status_response_text)
        except json.JSONDecodeError:
            print("Ungültige Statusantwort vom Server")
            continue
        
        status = status_response.get('status', 'unknown')
        print(f"Status: {status}")
        
        if status == 'completed':
            timestamp = datetime.now().strftime('%Y%m%d')
            output_file = os.path.join(output_dir, f"{timestamp}_crawl.json")
            with open(output_file, 'w') as f:
                json.dump(status_response, f, indent=2)
            print(f"Gespeichert in {output_dir}")
            break
        elif status == 'failed':
            print("Crawl fehlgeschlagen")
            sys.exit(1)
        
        time.sleep(5)

if __name__ == '__main__':
    main()
