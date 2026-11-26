#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "12cd1bb8dba4516312c698e18ba77f9c31ade12ce6818b50930d6330332e757f", "source_sha256": "c10479f79ca5554fe399cf2f5d70fb5b32e837c1c7a846eb7dd7c9e9e5319c66", "target_language": "python"}
# index.html — portiert nach python
# Quelle: html, Projects@TikTok-Live-Companion:site/index.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/index.html
# auch in: Projects@vercel/install-and-configure-vercel-w-98sxlo:site/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import sys
from xml.etree.ElementTree import Element, SubElement, tostring
from xml.dom import minidom

def create_html_document():
    # Create the root element with doctype
    html = Element('html', {'lang': 'de'})
    
    # Create head section
    head = SubElement(html, 'head')
    
    # Meta tags
    meta_charset = SubElement(head, 'meta', {'charset': 'UTF-8'})
    meta_viewport = SubElement(head, 'meta', {
        'name': 'viewport',
        'content': 'width=device-width, initial-scale=1.0'
    })
    meta_description = SubElement(head, 'meta', {
        'name': 'description',
        'content': 'Dokumentation für TikTok LIVE Companion 0.8.2 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.'
    })
    meta_theme_color = SubElement(head, 'meta', {
        'name': 'theme-color',
        'content': '#ffffff'
    })
    
    # Link tags
    link_favicon = SubElement(head, 'link', {
        'rel': 'icon',
        'type': 'image/png',
        'href': '/branding/staenderglobus-ios.png'
    })
    link_apple_touch = SubElement(head, 'link', {
        'rel': 'apple-touch-icon',
        'href': '/branding/staenderglobus-ios.png'
    })
    
    # Title
    title = SubElement(head, 'title')
    title.text = 'TikTok LIVE Companion – Dokumentation'
    
    # Body section
    body = SubElement(html, 'body')
    
    # Root div
    root_div = SubElement(body, 'div', {'id': 'root'})
    
    # Script tag
    script = SubElement(body, 'script', {
        'type': 'module',
        'src': '/src/main.tsx'
    })
    
    return html

def prettify_xml(element):
    """Return a pretty-printed XML string for the Element."""
    rough_string = tostring(element, encoding='unicode')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="  ").strip()

def add_doctype(html_string):
    """Add DOCTYPE declaration to the beginning of the HTML string."""
    return "<!doctype html>\n" + html_string

def main(output_file=None):
    # Create the HTML document structure
    html_doc = create_html_document()
    
    # Convert to pretty formatted string
    html_string = prettify_xml(html_doc)
    
    # Add DOCTYPE
    final_html = add_doctype(html_string)
    
    if output_file:
        # Write to file
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(final_html)
        print(f"HTML document written to {output_file}")
    else:
        # Print to stdout
        print(final_html)

if __name__ == "__main__":
    # Get output file from command line argument or use None for stdout
    output_file = sys.argv[1] if len(sys.argv) > 1 else None
    main(output_file)
