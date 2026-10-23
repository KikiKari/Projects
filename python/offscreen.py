#!/usr/bin/env python3
# offscreen.html — portiert nach python
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

import sys
import argparse
from xml.etree.ElementTree import Element, SubElement, tostring
from xml.dom import minidom

def create_offscreen_html():
    """Erstellt die HTML-Struktur fuer TikTok LIVE Companion Sprachausgabe"""
    
    # Erstelle das root Element
    html = Element('html')
    html.set('lang', 'de')
    
    # Erstelle head
    head = SubElement(html, 'head')
    
    # Fuege meta charset hinzu
    meta = SubElement(head, 'meta')
    meta.set('charset', 'utf-8')
    
    # Fuege title hinzu
    title = SubElement(head, 'title')
    title.text = 'TikTok LIVE Companion Sprachausgabe'
    
    # Erstelle body
    body = SubElement(html, 'body')
    
    # Fuege script hinzu
    script = SubElement(body, 'script')
    script.set('src', 'offscreen.js')
    
    return html

def prettify_xml(element):
    """Formatiert das XML schoen"""
    rough_string = tostring(element, encoding='unicode')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="  ")[23:]  # Entferne XML-Deklaration

def main():
    parser = argparse.ArgumentParser(description='Erzeuge offscreen.html')
    parser.add_argument('output_file', help='Ausgabedatei')
    
    args = parser.parse_args()
    
    # Erstelle HTML-Struktur
    html_doc = create_offscreen_html()
    
    # Formatieren und DOCTYPE hinzufuegen
    pretty_xml = prettify_xml(html_doc)
    full_html = '<!doctype html>\n' + pretty_xml
    
    # Schreibe in Datei
    with open(args.output_file, 'w', encoding='utf-8') as f:
        f.write(full_html)

if __name__ == '__main__':
    main()
