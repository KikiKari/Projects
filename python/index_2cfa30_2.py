#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "aa9401465cd81365c0d2cea80244fdc21f7001461d4332916cf237d054592470", "source_sha256": "2cfa301efe20d60c29e0e9f0746e5a99d405ea44a5d03839c72e6b525451fe07", "target_language": "python"}
# index.html — portiert nach python
# Quelle: html, Projects@TikTok-Live-Companion-Android:site/index.html
# auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

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
        'content': 'Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.'
    })
    meta_theme_color = SubElement(head, 'meta', {
        'name': 'theme-color',
        'content': '#ffffff'
    })
    
    # Link tags
    link_icon = SubElement(head, 'link', {
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

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 script.py <output_file>")
        sys.exit(1)
    
    output_file = sys.argv[1]
    
    # Create HTML structure
    html_doc = create_html_document()
    
    # Convert to pretty XML/HTML
    html_string = prettify_xml(html_doc)
    
    # Add DOCTYPE declaration
    full_html = '<!doctype html>\n' + html_string
    
    # Write to file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(full_html)
    
    print(f"HTML document written to {output_file}")

if __name__ == "__main__":
    main()
