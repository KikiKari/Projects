#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "a99bdcf24e162fab588d55ddc084611f7937477baed02ea3a01f7f2d172ae74e", "source_sha256": "a243d1fdcbd0c82c97b2771c181438428885fd9c2feaed782f7e9eb8066fed59", "target_language": "python"}
# offscreen.html — portiert nach python
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import sys
import os

def create_offscreen_html(output_path):
    """Erstellt die offscreen.html Datei mit der angegebenen Struktur"""
    
    # HTML-Inhalt als Template
    html_content = '''<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>TikTok LIVE Companion Sprachausgabe</title>
</head>
<body>
  <script src="offscreen.js"></script>
</body>
</html>'''
    
    # Schreibe den Inhalt in die Datei
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
        print(f"Datei erfolgreich erstellt: {output_path}")
        return True
    except Exception as e:
        print(f"Fehler beim Erstellen der Datei: {e}", file=sys.stderr)
        return False

def main():
    """Hauptfunktion - verarbeitet Kommandozeilenargumente"""
    if len(sys.argv) != 2:
        print("Verwendung: python script.py <ausgabedatei>", file=sys.stderr)
        sys.exit(1)
    
    output_file = sys.argv[1]
    
    # Stelle sicher, dass das Ausgabeverzeichnis existiert
    output_dir = os.path.dirname(output_file) if os.path.dirname(output_file) else '.'
    if output_dir != '.' and not os.path.exists(output_dir):
        try:
            os.makedirs(output_dir)
        except Exception as e:
            print(f"Fehler beim Erstellen des Verzeichnisses {output_dir}: {e}", file=sys.stderr)
            sys.exit(1)
    
    # Erstelle die HTML-Datei
    if not create_offscreen_html(output_file):
        sys.exit(1)

if __name__ == "__main__":
    main()
