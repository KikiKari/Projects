#!/usr/bin/env python3
# gateway-dashboard.html — portiert nach python
# Quelle: html, OpenClaw@main:examples/gateway-dashboard.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import sys
from xml.etree.ElementTree import Element, SubElement, tostring
from xml.dom import minidom


def create_html_document():
    # Create the root element
    html = Element('html', {'lang': 'en'})

    # Head section
    head = SubElement(html, 'head')
    meta_charset = SubElement(head, 'meta', {'charset': 'UTF-8'})
    meta_viewport = SubElement(head, 'meta', {
        'name': 'viewport',
        'content': 'width=device-width, initial-scale=1.0'
    })
    title = SubElement(head, 'title')
    title.text = 'OpenClaw — Gateway Dashboard'
    link = SubElement(head, 'link', {
        'rel': 'stylesheet',
        'href': 'gateway-styles.css'
    })

    # Body section
    body = SubElement(html, 'body')

    # Header
    header = SubElement(body, 'header')
    h1 = SubElement(header, 'h1')
    h1.text = 'OpenClaw Cluster'
    span = SubElement(header, 'span', {
        'id': 'cluster-status',
        'class': 'badge'
    })
    span.text = 'Checking...'

    # Main content
    main = SubElement(body, 'main')

    # Grid section
    grid_section = SubElement(main, 'section', {'class': 'grid'})

    # Gateway 1 card
    gw1_card = SubElement(grid_section, 'div', {'class': 'card', 'id': 'gw1'})
    gw1_h2 = SubElement(gw1_card, 'h2')
    gw1_h2.text = 'Gateway 1'
    gw1_p = SubElement(gw1_card, 'p', {'class': 'endpoint'})
    gw1_p.text = 'gateway1.openclaw.internal'
    gw1_status = SubElement(gw1_card, 'div', {'class': 'status-dot'})

    # Gateway 2 card
    gw2_card = SubElement(grid_section, 'div', {'class': 'card', 'id': 'gw2'})
    gw2_h2 = SubElement(gw2_card, 'h2')
    gw2_h2.text = 'Gateway 2'
    gw2_p = SubElement(gw2_card, 'p', {'class': 'endpoint'})
    gw2_p.text = 'gateway2.openclaw.internal'
    gw2_status = SubElement(gw2_card, 'div', {'class': 'status-dot'})

    # Metrics section
    metrics_section = SubElement(main, 'section', {'class': 'metrics'})
    metrics_h2 = SubElement(metrics_section, 'h2')
    metrics_h2.text = 'Node Metrics'

    table = SubElement(metrics_section, 'table')
    thead = SubElement(table, 'thead')
    tr_head = SubElement(thead, 'tr')
    
    for header_text in ['Node', 'Latency', 'Requests', 'Status']:
        th = SubElement(tr_head, 'th')
        th.text = header_text

    tbody = SubElement(table, 'tbody', {'id': 'metrics-body'})
    tr_body = SubElement(tbody, 'tr')
    td_colspan = SubElement(tr_body, 'td', {'colspan': '4'})
    td_colspan.text = 'Loading...'

    # Script section
    script = SubElement(body, 'script')
    script.text = '''
    const GATEWAY_URL = window.OPENCLAW_URL || "http://localhost:8080";

    async function pollStatus() {
      try {
        const res = await fetch(`${GATEWAY_URL}/health`);
        const ok = res.ok;
        document.getElementById("cluster-status").textContent = ok ? "Online" : "Degraded";
        document.getElementById("cluster-status").className = `badge ${ok ? "ok" : "warn"}`;
        document.querySelectorAll(".status-dot").forEach(d => d.className = `status-dot ${ok ? "green" : "red"}`);
      } catch {
        document.getElementById("cluster-status").textContent = "Offline";
        document.getElementById("cluster-status").className = "badge error";
      }
    }

    pollStatus();
    setInterval(pollStatus, 5000);
    '''

    return html


def prettify(elem):
    """Return a pretty-printed XML string for the Element."""
    rough_string = tostring(elem, encoding='unicode')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="  ")


def main():
    if len(sys.argv) != 2:
        print("Usage: python3 gateway-dashboard.py <output-file>")
        sys.exit(1)

    output_file = sys.argv[1]
    html_doc = create_html_document()
    pretty_html = prettify(html_doc)

    # Fix the DOCTYPE declaration
    final_html = '<!DOCTYPE html>\n' + pretty_html.split('\n', 1)[1]

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(final_html)


if __name__ == '__main__':
    main()
