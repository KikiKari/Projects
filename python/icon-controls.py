#!/usr/bin/env python3
# icon-controls.css — portiert nach python
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

import sys
from pathlib import Path

def generate_css():
    """Generate the CSS content programmatically"""
    
    # Define icon styles and their paths
    icon_styles = {
        'plastisch': 'icons/plastisch',
        'glass': 'icons/glass',
        'linear': 'icons/linear'
    }
    
    # Define all icon names
    icon_names = [
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
    
    css_lines = []
    
    # Generate style definitions for each icon style
    for style_name, path_prefix in icon_styles.items():
        line = f'html[data-icon-style="{style_name}"] {{'
        for icon_name in icon_names:
            line += f'--icon-{icon_name}:url("{path_prefix}/{icon_name}.png");'
        line += '}'
        css_lines.append(line)
    
    # Add generic control styles
    css_lines.extend([
        'button[data-control-icon]::before,.control-icon::before { content:""; display:inline-block; width:32px; height:32px; flex:0 0 32px; background:var(--control-icon) center/contain no-repeat; vertical-align:middle; margin-inline-end:0; pointer-events:none; }',
        'button[data-control-icon] { min-height:44px; min-width:44px; font-size:0; display:inline-flex; align-items:center; justify-content:center; }',
        'button[data-control-icon][hidden] { display:none; }',
        'input[type="checkbox"] { appearance:none; -webkit-appearance:none; width:44px; height:44px; min-width:44px; border:0; background:var(--icon-off) center/40px no-repeat; cursor:pointer; vertical-align:middle; }',
        'input[type="checkbox"]:checked { background-image:var(--icon-on); }',
        'input[type="checkbox"]:focus-visible,button[data-control-icon]:focus-visible { outline:2px solid #1769df; outline-offset:2px; }',
        'input[type="checkbox"]:disabled { opacity:.45; cursor:default; }',
        '.control-icon { display:inline-flex; align-items:center; }',
        'input[type="range"] { min-height:32px; }',
        '.icon-style-setting { display:flex; align-items:center; gap:8px; }'
    ])
    
    # Add individual control icon mappings
    for icon_name in icon_names:
        css_lines.append(f'[data-control-icon="{icon_name}"] {{ --control-icon:var(--icon-{icon_name}); }}')
    
    return '\n'.join(css_lines) + '\n'

def main():
    if len(sys.argv) != 2:
        print("Usage: script.py <output_file>")
        sys.exit(1)
    
    output_file = sys.argv[1]
    css_content = generate_css()
    
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(css_content)
        print(f"CSS file generated successfully: {output_file}")
    except Exception as e:
        print(f"Error writing file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
