#!/usr/bin/env python3
# websearch-monitor.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/websearch-monitor.sh
# auch in: OpenClaw@gateway2:scripts/websearch-monitor.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

# Web Search Script: Server-Monitoring mit Tavily
# Verwendung: ./websearch-monitor.py [TOPIC]

import sys
import subprocess
import json
import urllib.request
import urllib.parse

def main():
    topic = sys.argv[1] if len(sys.argv) > 1 else "Linux kernel security updates"
    
    # Security-News prüfen
    print(f"Prüfe: {topic}")
    
    # Versuche zuerst Tavily CLI
    try:
        # Prüfe ob tvly Kommando existiert
        subprocess.run(["which", "tvly"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        # Führe Tavily Suche aus
        result = subprocess.run([
            "tvly", "search", topic,
            "--topic", "news",
            "--time-range", "week",
            "--max-results", "5",
            "--include-answer", "advanced"
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            data = json.loads(result.stdout)
            answer = data.get('answer')
            if answer:
                print(answer)
            else:
                print("Keine Zusammenfassung verfügbar")
        else:
            print("Keine Zusammenfassung verfügbar")
            
    except (subprocess.CalledProcessError, FileNotFoundError):
        # Fallback zu einfacher Web-Suche
        try:
            encoded_topic = urllib.parse.quote_plus(topic)
            url = f"http://localhost:8888/search?q={encoded_topic}&format=json"
            
            with urllib.request.urlopen(url) as response:
                data = json.loads(response.read().decode())
                
            results = data.get('results', [])[:3]
            output_lines = []
            for item in results:
                output_lines.append(item.get('title', ''))
                output_lines.append(item.get('url', ''))
            
            if output_lines:
                print('\n'.join(output_lines))
            else:
                print("SearXNG nicht verfügbar")
                
        except Exception:
            print("SearXNG nicht verfügbar")

if __name__ == "__main__":
    main()
