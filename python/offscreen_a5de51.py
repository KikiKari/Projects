#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "6d05b4cd06b490cf84ea917686ae7186976e66f01bfd535154f2773ec24da370", "source_sha256": "a5de51b02b40bbdeafb7fb0f4da19091ec351b10a9160307085ebcef403cdd67", "target_language": "python"}
# offscreen.html — portiert nach python
# Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import sys
import os

def create_offscreen_html(output_file):
    """Create the offscreen.html file with proper DOCTYPE and structure"""
    
    # Define the HTML content
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
    
    # Write to the specified output file
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(html_content)
        print(f"Successfully created {output_file}")
    except IOError as e:
        print(f"Error writing to file {output_file}: {e}", file=sys.stderr)
        sys.exit(1)

def main():
    """Main function to handle command line arguments"""
    if len(sys.argv) != 2:
        print("Usage: python3 script.py <output_file>", file=sys.stderr)
        sys.exit(1)
    
    output_file = sys.argv[1]
    create_offscreen_html(output_file)

if __name__ == "__main__":
    main()
