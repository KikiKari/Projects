#!/usr/bin/env python3
# index.html — portiert nach python
# Quelle: html, Projects@TikTok-Live-Companion:site/index.html
# auch in: Projects@TikTok-Live-Companion-Android:site/index.html
# auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import sys
import argparse
from xml.etree.ElementTree import Element, SubElement, tostring
from xml.dom import minidom


def create_html_document():
    """Erstellt das HTML-Dokument gemäß der Vorlage."""
    
    # Root-Element mit DOCTYPE
    html = Element('html', attrib={'lang': 'de'})
    
    # HEAD-Bereich
    head = SubElement(html, 'head')
    
    # Meta-Tags
    meta_charset = SubElement(head, 'meta', attrib={'charset': 'UTF-8'})
    meta_viewport = SubElement(head, 'meta', attrib={
        'name': 'viewport',
        'content': 'width=device-width, initial-scale=1.0'
    })
    meta_description = SubElement(head, 'meta', attrib={
        'name': 'description',
        'content': 'Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.'
    })
    meta_theme_color = SubElement(head, 'meta', attrib={
        'name': 'theme-color',
        'content': '#ffffff'
    })
    
    # Links
    link_icon = SubElement(head, 'link', attrib={
        'rel': 'icon',
        'type': 'image/png',
        'href': '/branding/staenderglobus-ios.png'
    })
    link_apple = SubElement(head, 'link', attrib={
        'rel': 'apple-touch-icon',
        'href': '/branding/staenderglobus-ios.png'
    })
    
    # Title
    title = SubElement(head, 'title')
    title.text = 'TikTok LIVE Companion – Dokumentation'
    
    # BODY-Bereich
    body = SubElement(html, 'body')
    
    # Div-Container
    div_root = SubElement(body, 'div', attrib={'id': 'root'})
    
    # Script-Tag
    script = SubElement(body, 'script', attrib={
        'type': 'module',
        'src': '/src/main.tsx'
    })
    
    return html


def prettify_element_tree(elem):
    """Formatiert den XML/HTML-Baum lesbar."""
    rough_string = tostring(elem, encoding='unicode')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="  ").strip()


def generate_html_output(file_path=None):
    """Generiert das HTML und gibt es auf stdout aus oder speichert es in eine Datei."""
    html_elem = create_html_document()
    doctype = "<!doctype html>"
    formatted_html = prettify_element_tree(html_elem).replace('<?xml version="1.0" ?>', '')
    full_output = f"{doctype}\n{formatted_html}"
    
    if file_path:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(full_output)
    else:
        print(full_output)


def main():
    parser = argparse.ArgumentParser(description='Generiere die index.html für TikTok LIVE Companion')
    parser.add_argument('-o', '--output', help='Ausgabedatei (optional, Standard: stdout)')
    args = parser.parse_args()
    
    try:
        generate_html_output(args.output)
    except Exception as e:
        print(f"Fehler beim Generieren der HTML-Datei: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
