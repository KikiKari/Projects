#!/usr/bin/env python3
# index.html — portiert nach python
# Quelle: html, Projects@TikTok-Live-Companion:site/index.html
# auch in: Projects@TikTok-Live-Companion-Android:site/index.html
# auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import sys
from html import escape

def generate_html():
    """Generates the HTML document structure."""
    # Define metadata content
    description = "Dokumentation für TikTok LIVE Companion 0.7.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser."
    title = "TikTok LIVE Companion – Dokumentation"
    
    # Build HTML structure
    html_parts = [
        '<!doctype html>',
        '<html lang="de">',
        '  <head>',
        '    <meta charset="UTF-8" />',
        '    <meta name="viewport" content="width=device-width, initial-scale=1.0" />',
        f'    <meta name="description" content="{escape(description)}" />',
        '    <meta name="theme-color" content="#ffffff" />',
        f'    <title>{escape(title)}</title>',
        '  </head>',
        '  <body>',
        '    <div id="root"></div>',
        '    <script type="module" src="/src/main.tsx"></script>',
        '  </body>',
        '</html>'
    ]
    
    return '\n'.join(html_parts) + '\n'

def main():
    """Main function to write HTML to file or stdout."""
    output_file = sys.argv[1] if len(sys.argv) > 1 else None
    
    html_content = generate_html()
    
    if output_file:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(html_content)
    else:
        print(html_content, end='')

if __name__ == "__main__":
    main()
