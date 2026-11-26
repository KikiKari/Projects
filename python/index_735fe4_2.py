#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "fb5cbd687578df5753ff2d81774f25ee53c458b89638b3f339124f76b72bf085", "source_sha256": "735fe4b2c74b10f265f715cd4e85d574f46a7132d2e592703b5e712888470105", "target_language": "python"}
# index.html — portiert nach python
# Quelle: html, OpenClaw@main:index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import sys
from xml.etree.ElementTree import Element, SubElement, tostring
from xml.dom import minidom

def create_html_document():
    """Create the HTML document structure"""
    
    # Create root element
    html = Element('html')
    html.set('lang', 'de')
    
    # Create head section
    head = SubElement(html, 'head')
    
    # Meta charset
    meta_charset = SubElement(head, 'meta')
    meta_charset.set('charset', 'utf-8')
    
    # Link icon
    link_icon = SubElement(head, 'link')
    link_icon.set('rel', 'icon')
    link_icon.set('href', '/favicon.ico')
    
    # Viewport meta
    meta_viewport = SubElement(head, 'meta')
    meta_viewport.set('name', 'viewport')
    meta_viewport.set('content', 'width=device-width, initial-scale=1')
    
    # Theme color meta
    meta_theme = SubElement(head, 'meta')
    meta_theme.set('name', 'theme-color')
    meta_theme.set('content', '#0b1020')
    
    # Description meta
    meta_description = SubElement(head, 'meta')
    meta_description.set('name', 'description')
    meta_description.set('content', 'OpenClaw Startseite für Repository, Dokumentation und Frontend-Branch.')
    
    # Apple touch icon
    link_apple = SubElement(head, 'link')
    link_apple.set('rel', 'apple-touch-icon')
    link_apple.set('href', '/logo192.png')
    
    # Comment for manifest
    comment_manifest = Element(None)
    comment_manifest.text = """
      manifest.json provides metadata used when your web app is installed on a
      user's mobile device or desktop. See https://developers.google.com/web/fundamentals/web-app-manifest/
    """
    head.append(comment_manifest)
    
    # Manifest link
    link_manifest = SubElement(head, 'link')
    link_manifest.set('rel', 'manifest')
    link_manifest.set('href', '/manifest.json')
    
    # Title
    title = SubElement(head, 'title')
    title.text = 'OpenClaw'
    
    # Create body section
    body = SubElement(html, 'body')
    
    # Noscript message
    noscript = SubElement(body, 'noscript')
    noscript.text = 'You need to enable JavaScript to run this app.'
    
    # Root div
    root_div = SubElement(body, 'div')
    root_div.set('id', 'root')
    
    # Comment for template info
    comment_template = Element(None)
    comment_template.text = """
      This HTML file is a template.
      If you open it directly in the browser, you will see an empty page.

      You can add webfonts, meta tags, or analytics to this file.
      The build step will place the bundled scripts into the <body> tag.

      To begin the development, run `npm start` or `yarn start`.
      To create a production bundle, use `npm run build` or `yarn build`.
    """
    body.append(comment_template)
    
    # Script tag
    script = SubElement(body, 'script')
    script.set('type', 'module')
    script.set('src', '/src/index.jsx')
    
    return html

def prettify_xml(elem):
    """Return a pretty-printed XML string for the Element."""
    rough_string = tostring(elem, encoding='unicode')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="  ")

def main():
    # Add DOCTYPE declaration manually
    doctype = '<!DOCTYPE html>\n'
    
    # Create the HTML structure
    html_elem = create_html_document()
    
    # Convert to string and format
    html_string = prettify_xml(html_elem)
    
    # Remove the XML declaration that minidom adds
    if html_string.startswith('<?xml'):
        html_string = html_string.split('\n', 1)[1]
    
    # Combine DOCTYPE with formatted HTML
    full_html = doctype + html_string
    
    # Handle output - either to stdout or file
    if len(sys.argv) > 1:
        filename = sys.argv[1]
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(full_html)
    else:
        print(full_html)

if __name__ == '__main__':
    main()
