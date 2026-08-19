#!/usr/bin/env python3
# index.html — portiert nach python
# Quelle: html, Projects@Program-Derivation:public/index.html
# auch in: Projects@Vision-Check:public/index.html
# auch in: Projects@Weather-Check:public/index.html
# auch in: Projects@abstractions:public/index.html
# auch in: 5 weiteren Fundstellen
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import sys
import os

def create_html_file(output_path):
    """Erstellt eine HTML-Datei mit Weiterleitung zur 3D-Ansicht"""
    
    # HTML-Struktur erstellen
    html_content = '''<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="refresh" content="0; url=3d.html">
<title>Weiterleitung zur 3D-Ansicht</title>
<link rel="canonical" href="3d.html">
<script>location.replace('3d.html');</script>
</head>
<body>
<p><a href="3d.html">3D-Ansicht öffnen</a></p>
</body>
</html>'''
    
    # In Datei schreiben
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
        print(f"HTML-Datei erfolgreich erstellt: {output_path}")
        return True
    except Exception as e:
        print(f"Fehler beim Erstellen der Datei: {e}")
        return False

def main():
    """Hauptfunktion - prüft Parameter und erstellt HTML-Datei"""
    
    # Parameter prüfen
    if len(sys.argv) != 2:
        print("Verwendung: python script.py <ausgabedatei>")
        print("Beispiel: python script.py index.html")
        sys.exit(1)
    
    output_file = sys.argv[1]
    
    # HTML-Datei erstellen
    if not create_html_file(output_file):
        sys.exit(1)

if __name__ == "__main__":
    main()
