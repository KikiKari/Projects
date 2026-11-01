#!/usr/bin/env python3
# status-overview.html — portiert nach python
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.html
# Erzeugt: 2026-11-01 durch ABSTRACTIONS_MANAGER.py

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
    main_content = '<main id="grid" aria-label="LIVE-Übersicht"></main>'
    script_mpegts = '<script src="vendor-mpegts.js"></script>'
    script_player = '<script src="status-overview-player.js"></script>'
    body_end = "</body>"
    html_end = "</html>"
    
    # Assemble all parts in correct order
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
        main_content,
        script_mpegts,
        script_player,
        body_end,
        html_end
    ]
    
    return "".join(document_parts)


def write_to_file(content, filename):
    """Write the HTML content to a file"""
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    except IOError as e:
        print(f"Error writing to file {filename}: {e}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(description="Generate STATUS-Overview HTML document")
    parser.add_argument("output_file", help="Output HTML file path")
    
    args = parser.parse_args()
    
    # Create the HTML document
    html_content = create_html_document()
    
    # Write to specified file
    if write_to_file(html_content, args.output_file):
        print(f"STATUS-Overview document successfully written to {args.output_file}")
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
