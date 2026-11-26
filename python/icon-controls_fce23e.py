#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "8f4deb5631f9058bb40d9664269f7a4b0c71b7fa18faa5e609a4a66a2d32c984", "source_sha256": "fce23ec10c43acef00ba36b3975889539f87b908bd4cfce77616443d2b5f569e", "target_language": "python"}
# icon-controls.css — portiert nach python
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import sys
import argparse


def generate_css():
    """Generates the CSS content dynamically."""
    styles = ['plastisch', 'glass', 'linear']
    icons = [
        'auto-chat-refresh-counter',
        'browser',
        'captions',
        'chat-counter',
        'fullscreen',
        'mute',
        'off',
        'on',
        'pip',
        'play',
        'player',
        'protection-slider',
        'recommendation-counter',
        'report',
        'reset',
        'settings',
        'status',
        'stop',
        'unmute',
        'volume-slider'
    ]

    lines = []

    # Generate style-specific icon variables
    for style in styles:
        line = f'html[data-icon-style="{style}"] {{'
        for icon in icons:
            line += f'--icon-{icon}:url("icons/{style}/{icon}.png");'
        line += '}'
        lines.append(line)

    # Add general control styles
    lines.append('button[data-control-icon]::before,.control-icon::before { content:""; display:inline-block; width:32px; height:32px; flex:0 0 32px; background:var(--control-icon) center/contain no-repeat; vertical-align:middle; margin-inline-end:0; pointer-events:none; }')
    lines.append('button[data-control-icon] { min-height:44px; min-width:44px; font-size:0; display:inline-flex; align-items:center; justify-content:center; }')
    lines.append('button[data-control-icon][hidden] { display:none; }')
    lines.append('input[type="checkbox"] { appearance:none; -webkit-appearance:none; width:44px; height:44px; min-width:44px; border:0; background:var(--icon-off) center/40px no-repeat; cursor:pointer; vertical-align:middle; }')
    lines.append('input[type="checkbox"]:checked { background-image:var(--icon-on); }')
    lines.append('input[type="checkbox"]:focus-visible,button[data-control-icon]:focus-visible { outline:2px solid #1769df; outline-offset:2px; }')
    lines.append('input[type="checkbox"]:disabled { opacity:.45; cursor:default; }')
    lines.append('.control-icon { display:inline-flex; align-items:center; }')
    lines.append('input[type="range"] { min-height:32px; }')
    lines.append('.icon-style-setting { display:flex; align-items:center; gap:8px; }')

    # Add individual control icon mappings
    for icon in icons:
        lines.append(f'[data-control-icon="{icon}"] {{ --control-icon:var(--icon-{icon}); }}')

    return '\n'.join(lines)


def main(output_file):
    """Main function to write CSS to file."""
    css_content = generate_css()
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(css_content)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate icon-controls.css')
    parser.add_argument('output', help='Output CSS file path')
    args = parser.parse_args()
    main(args.output)
