#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "331e69276e5e5a60e1a6ab01ac6efce1ae5a360b93c55b8254b1fe5bde70e6cf", "source_sha256": "7fc810e8bcb817cb81407c2ad604d4bd70dce9f3ff8cb2bbfbcacfec00febd1c", "target_language": "python"}
# status-overview.html — portiert nach python
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import argparse
import sys
from pathlib import Path


def create_html_document():
    """Create the STATUS-Overview HTML document structure"""
    
    # Document type declaration
    doctype = "<!DOCTYPE html>"
    
    # HTML structure
    html_start = '<html lang="de">'
    head_start = "<head>"
    meta_charset = '<meta charset="utf-8">'
    meta_viewport = '<meta name="viewport" content="width=device-width,initial-scale=1">'
    title = "<title>STATUS-Overview</title>"
    link_css = '<link rel="stylesheet" href="status-overview.css">'
    head_end = "</head>"
    
    body_start = "<body>"
    main = '<main id="grid" aria-label="LIVE-Übersicht"></main>'
    script_mpegts = '<script src="vendor-mpegts.js"></script>'
    script_player = '<script src="status-overview-player.js"></script>'
    body_end = "</body>"
    html_end = "</html>"
    
    # Combine all parts in correct order
    document_parts = [
        doctype,
        html_start,
        head_start,
        meta_charset,
        meta_viewport,
        title,
        link_css,
        head_end,
        body_start,
        main,
        script_mpegts,
        script_player,
        body_end,
        html_end
    ]
    
    return "\n".join(document_parts) + "\n"


def write_to_file(content, filepath):
    """Write content to specified file path"""
    try:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    except IOError as e:
        print(f"Error writing to file: {e}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(description="Generate STATUS-Overview HTML document")
    parser.add_argument("output_file", help="Path to output HTML file")
    
    args = parser.parse_args()
    
    # Create the HTML document
    html_content = create_html_document()
    
    # Write to specified file
    if write_to_file(html_content, args.output_file):
        print(f"Successfully generated {args.output_file}")
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
