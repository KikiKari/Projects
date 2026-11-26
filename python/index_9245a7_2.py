#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "d1972d59baeaefa9329e5d05566ecafa0af11295b6c0162d7937cf596b7045f3", "source_sha256": "9245a78489adb3949ae2a56f5e0987a465142b9a8ee97bddaca453f5011daef8", "target_language": "python"}
# index.html — portiert nach python
# Quelle: html, Projects@Program-Derivation:public/index.html
# auch in: Projects@Vision-Check:public/index.html
# auch in: Projects@Weather-Check:public/index.html
# auch in: Projects@abstractions:public/index.html
# auch in: 5 weiteren Fundstellen
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import sys
import os
from html import escape
from xml.etree.ElementTree import Element, SubElement, tostring
from xml.dom import minidom

def create_redirect_html(output_file):
    """Erstellt eine HTML-Weiterleitungsseite und speichert sie in einer Datei."""
    
    # Erstellen des HTML-Dokuments
    html = Element('html', {'lang': 'de'})
    
    # HEAD-Bereich
    head = SubElement(html, 'head')
    
    # Meta-Tags
    meta_charset = SubElement(head, 'meta', {'charset': 'utf-8'})
    meta_viewport = SubElement(head, 'meta', {
        'name': 'viewport',
        'content': 'width=device-width, initial-scale=1'
    })
    meta_refresh = SubElement(head, 'meta', {
        'http-equiv': 'refresh',
        'content': '0; url=3d.html'
    })
    
    # Title
    title = SubElement(head, 'title')
    title.text = 'Weiterleitung zur 3D-Ansicht'
    
    # Canonical Link
    link_canonical = SubElement(head, 'link', {
        'rel': 'canonical',
        'href': '3d.html'
    })
    
    # Script für JavaScript-Redirect
    script = SubElement(head, 'script')
    script.text = "location.replace('3d.html');"
    
    # BODY-Bereich
    body = SubElement(html, 'body')
    p = SubElement(body, 'p')
    a = SubElement(p, 'a', {'href': '3d.html'})
    a.text = '3D-Ansicht öffnen'
    
    # Pretty-Print des HTML
    rough_string = tostring(html, encoding='unicode')
    reparsed = minidom.parseString(rough_string)
    pretty_html = reparsed.toprettyxml(indent="  ")
    
    # Entferne leere Zeilen und XML-Declaration
    lines = [line for line in pretty_html.split('\n') if line.strip()]
    if lines[0].startswith('<?xml'):
        lines.pop(0)
    final_html = '\n'.join(lines)
    
    # DOCTYPE hinzufügen
    html_content = '<!DOCTYPE html>\n' + final_html
    
    # In Datei schreiben
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html_content)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Verwendung: python script.py <ausgabedatei>")
        sys.exit(1)
    
    output_file = sys.argv[1]
    create_redirect_html(output_file)
    print(f"HTML-Datei wurde erfolgreich erstellt: {output_file}")
