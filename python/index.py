#!/usr/bin/env python3
# index.html — portiert nach python
# Quelle: html, Projects@TikTok-Live-Companion:site/index.html
# Erzeugt: 2026-10-12 durch ABSTRACTIONS_MANAGER.py

import sys
from xml.etree import ElementTree as ET
from xml.dom import minidom

def create_html_document():
    """Create the HTML document structure"""
    
    # Create root element with doctype
    html = ET.Element('html', {'lang': 'de'})
    
    # Create head section
    head = ET.SubElement(html, 'head')
    
    # Meta charset
    meta_charset = ET.SubElement(head, 'meta', {'charset': 'UTF-8'})
    
    # Viewport meta
    meta_viewport = ET.SubElement(head, 'meta', {
        'name': 'viewport',
        'content': 'width=device-width, initial-scale=1.0'
    })
    
    # Description meta
    meta_description = ET.SubElement(head, 'meta', {
        'name': 'description',
        'content': 'Dokumentation für TikTok LIVE Companion 0.8.2 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.'
    })
    
    # Theme color meta
    meta_theme_color = ET.SubElement(head, 'meta', {
        'name': 'theme-color',
        'content': '#ffffff'
    })
    
    # Icon link
    link_icon = ET.SubElement(head, 'link', {
        'rel': 'icon',
        'type': 'image/png',
        'href': '/branding/staenderglobus-ios.png'
    })
    
    # Apple touch icon link
    link_apple = ET.SubElement(head, 'link', {
        'rel': 'apple-touch-icon',
        'href': '/branding/staenderglobus-ios.png'
    })
    
    # Title
    title = ET.SubElement(head, 'title')
    title.text = 'TikTok LIVE Companion – Dokumentation'
    
    # Body section
    body = ET.SubElement(html, 'body')
    
    # Root div
    root_div = ET.SubElement(body, 'div', {'id': 'root'})
    
    # Script tag
    script = ET.SubElement(body, 'script', {
        'type': 'module',
        'src': '/src/main.tsx'
    })
    
    return html

def prettify_xml(element):
    """Return a pretty-printed XML string for the Element"""
    rough_string = ET.tostring(element, encoding='unicode')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="  ").strip()

def main():
    """Main function to generate HTML file"""
    if len(sys.argv) != 2:
        print("Usage: python3 script.py <output_file>")
        sys.exit(1)
    
    output_file = sys.argv[1]
    
    # Create HTML document
    html_doc = create_html_document()
    
    # Convert to string with proper formatting
    html_string = prettify_xml(html_doc)
    
    # Add doctype declaration
    full_html = '<!doctype html>\n' + html_string
    
    # Write to file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(full_html)

if __name__ == '__main__':
    main()
