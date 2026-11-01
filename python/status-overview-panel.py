#!/usr/bin/env python3
# status-overview-panel.css — portiert nach python
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview-panel.css
# Erzeugt: 2026-11-01 durch ABSTRACTIONS_MANAGER.py

import sys
from pathlib import Path

def generate_css():
    """Generate the CSS content for status-overview-panel"""
    
    # Define CSS rules as a list of tuples (selector, properties_dict)
    css_rules = [
        ('.overview-row', {
            'display': 'grid',
            'grid-template-columns': '24px minmax(0,1fr) 11px 22px auto',
            'gap': '7px',
            'align-items': 'center',
            'margin': '6px 0'
        }),
        ('.overview-row input', {
            'min-width': '0',
            'width': '100%'
        }),
        ('.overview-state', {
            'width': '11px',
            'height': '11px',
            'border-radius': '50%',
            'background': '#888'
        }),
        ('.overview-state.online', {
            'background': 'var(--good)',
            'box-shadow': '0 0 0 3px color-mix(in srgb, var(--good) 15%, transparent)'
        }),
        ('.overview-state.offline', {
            'background': 'var(--bad)',
            'box-shadow': '0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent)'
        }),
        ('.overview-state.checking, .overview-state.error', {
            'background': 'var(--warn)'
        }),
        ('.overview-count', {
            'font-size': '11px',
            'text-align': 'center',
            'font-variant-numeric': 'tabular-nums'
        }),
        ('.overview-actions', {
            'display': 'grid',
            'grid-template-columns': '44px repeat(2,minmax(0,1fr))',
            'gap': '6px',
            'align-items': 'stretch'
        }),
        ('.overview-actions button', {
            'min-width': '0',
            'padding': '8px 2px',
            'font-size': '11px',
            'white-space': 'nowrap'
        }),
        ('#overview-rows', {
            'display': 'flex',
            'flex-direction': 'column'
        }),
        ('.monitor-settings > label:not(.option-row)', {
            'display': 'block',
            'margin': '12px 0'
        }),
        ('.monitor-settings .option-row input', {
            'appearance': 'auto',
            'width': '13px',
            'height': '13px',
            'min-width': '13px',
            'background': 'none'
        }),
        ('.overview-link', {
            'padding': '8px 0',
            'border-bottom': '1px solid #bbb',
            'overflow-wrap': 'anywhere'
        }),
        ('.overview-link p', {
            'margin': '4px 0'
        }),
        ('.overview-row .overview-retry', {
            'width': '24px',
            'min-width': '24px',
            'height': '26px',
            'min-height': '26px',
            'padding': '0',
            'background-image': 'var(--icon-reset)',
            'background-size': '20px',
            'background-position': 'center',
            'background-repeat': 'no-repeat'
        }),
        ('.top-setting input', {
            'appearance': 'auto',
            '-webkit-appearance': 'checkbox',
            'width': '13px',
            'height': '13px',
            'min-width': '13px',
            'background': 'none'
        }),
        ('.overview-visually-hidden', {
            'position': 'absolute',
            'width': '1px',
            'height': '1px',
            'padding': '0',
            'margin': '-1px',
            'overflow': 'hidden',
            'clip': 'rect(0,0,0,0)',
            'white-space': 'nowrap',
            'border': '0'
        }),
        ('.overview-row[hidden]', {
            'display': 'none'
        })
    ]
    
    # Convert rules to CSS string
    css_lines = []
    for selector, properties in css_rules:
        css_lines.append(f"{selector} {{")
        for prop, value in properties.items():
            css_lines.append(f"  {prop}: {value};")
        css_lines.append("}")
    
    return '\n'.join(css_lines)

def write_css_to_file(filename):
    """Write the generated CSS to a file"""
    css_content = generate_css()
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(css_content)

def main():
    """Main function to generate CSS file"""
    if len(sys.argv) != 2:
        print("Usage: python status-overview-panel.py <output-file>")
        sys.exit(1)
    
    output_file = sys.argv[1]
    write_css_to_file(output_file)
    print(f"CSS file generated: {output_file}")

if __name__ == "__main__":
    main()
