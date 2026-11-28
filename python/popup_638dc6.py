#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "dca74d435de3c5c42b3c4b03e2d1eb9bf2f68e8f3d982efe645279ce225fa2ae", "source_sha256": "638dc60323e7b18098ef0f5b3cef4b90dd9bb4ffeca2fdedb49c5b2aebbe59c3", "target_language": "python"}
# popup.css — portiert nach python
# Quelle: css, Projects@abstractions:css/popup.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

import sys

def generate_css():
    """Generates the popup.css content as a structured representation."""
    
    # Root variables for dark theme
    root_vars_dark = {
        '--bg': '#0f1115',
        '--card': '#171a21',
        '--line': '#262b36',
        '--text': '#f2f4f8',
        '--muted': '#9aa3b2',
        '--accent': '#fe2c55',
        '--ok': '#22c55e'
    }
    
    # Root variables for light theme media query
    root_vars_light = {
        '--bg': '#fff',
        '--card': '#f6f7f9',
        '--line': '#e3e6ea',
        '--text': '#16191d',
        '--muted': '#6b7280'
    }

    # CSS rules grouped by selectors
    css_rules = [
        # Comment header
        ('comment', '/* abstraction-provenance: {"artifact_sha256": "9a98ca6b7904c136087b8d4d69db570323e127c17f3231983fad5ab0ede46fb9", "source_sha256": "460df65e46318ad1986c44053aeaeda0d4be58e1787c4233154a42f92badec94", "target_language": "css"} */'),
        ('comment', '/* popup.html — portiert nach css */'),
        ('comment', '/* Quelle: html, Projects@Telegram-Monitor:plugin/extension/popup.html */'),
        ('comment', '/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */'),
        
        # Root dark theme
        (':root', root_vars_dark, 'color-scheme: dark;'),
        
        # Media query for light theme
        ('@media (prefers-color-scheme: light)', [
            (':root', root_vars_light, '')
        ]),
        
        # Universal selector
        ('*', '', 'box-sizing: border-box;'),
        
        # Body styles
        ('body', '', 
         'margin: 0;\n'
         'width: 420px;\n'
         'max-height: 600px;\n'
         'overflow: auto;\n'
         'background: var(--bg);\n'
         'color: var(--text);\n'
         'font: 14px/1.45 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;'
        ),
        
        # Wrap class
        ('.wrap', '', 'padding: 12px;'),
        
        # Header styles
        ('header', '', 
         'display: flex;\n'
         'gap: 8px;\n'
         'align-items: center;\n'
         'margin-bottom: 10px;'
        ),
        
        # H1 styles
        ('h1', '', 
         'font-size: 14px;\n'
         'margin: 0;\n'
         'font-weight: 650;\n'
         'flex: 1;'
        ),
        
        # Badge styles
        ('.badge', '', 
         'font-size: 11px;\n'
         'font-weight: 700;\n'
         'padding: 3px 9px;\n'
         'border-radius: 99px;\n'
         'background: #2a2f3a;\n'
         'color: var(--muted);\n'
         'display: inline-flex;\n'
         'align-items: center;\n'
         'gap: 5px;'
        ),
        
        # Live badge modifier
        ('.badge.live', '', 
         'background: var(--accent);\n'
         'color: #fff;'
        ),
        
        # Dot inside badge
        ('.badge .dot', '', 
         'width: 6px;\n'
         'height: 6px;\n'
         'border-radius: 50%;\n'
         'background: currentColor;'
        ),
        
        # Animated dot for live badge
        ('.badge.live .dot', '', 'animation: pulse 1.6s infinite;'),
        
        # Pulse keyframes
        ('@keyframes pulse', '', 
         '0%, 100% {\n'
         '  opacity: 1;\n'
         '}\n'
         '50% {\n'
         '  opacity: .25;\n'
         '}'
        ),
        
        # Row layout
        ('.row', '', 
         'display: flex;\n'
         'gap: 6px;\n'
         'flex-wrap: wrap;\n'
         'align-items: center;\n'
         'margin-bottom: 8px;'
        ),
        
        # Input/select/button common styles
        ('input, select, button', '', 
         'font: inherit;\n'
         'border-radius: 7px;\n'
         'border: 1px solid var(--line);\n'
         'background: var(--card);\n'
         'color: var(--text);\n'
         'padding: 6px 9px;'
        ),
        
        # Button specific styles
        ('button', '', 
         'cursor: pointer;\n'
         'font-weight: 600;'
        ),
        
        # Primary button
        ('button.primary', '', 
         'background: var(--accent);\n'
         'border-color: var(--accent);\n'
         'color: #fff;'
        ),
        
        # Player container
        ('.player', '', 
         'position: relative;\n'
         'width: 100%;\n'
         'aspect-ratio: 9/16;\n'
         'max-height: 360px;\n'
         'background: #000;\n'
         'border-radius: 10px;\n'
         'overflow: hidden;\n'
         'border: 1px solid var(--line);\n'
         'margin: 8px 0;'
        ),
        
        # Iframe in player
        ('.player iframe', '', 
         'position: absolute;\n'
         'inset: 0;\n'
         'width: 100%;\n'
         'height: 100%;\n'
         'border: 0;'
        ),
        
        # Placeholder content
        ('.placeholder', '', 
         'position: absolute;\n'
         'inset: 0;\n'
         'display: flex;\n'
         'flex-direction: column;\n'
         'gap: 6px;\n'
         'align-items: center;\n'
         'justify-content: center;\n'
         'color: var(--muted);\n'
         'text-align: center;\n'
         'padding: 16px;\n'
         'font-size: 13px;'
        ),
        
        # Card component
        ('.card', '', 
         'background: var(--card);\n'
         'border: 1px solid var(--line);\n'
         'border-radius: 10px;\n'
         'padding: 10px 12px;\n'
         'margin-bottom: 8px;'
        ),
        
        # H2 heading
        ('h2', '', 
         'font-size: 11px;\n'
         'text-transform: uppercase;\n'
         'letter-spacing: .05em;\n'
         'color: var(--muted);\n'
         'margin: 0 0 6px;\n'
         'font-weight: 650;'
        ),
        
        # Meta text
        ('.meta', '', 
         'color: var(--muted);\n'
         'font-size: 12.5px;'
        ),
        
        # Strong text
        ('.strong', '', 
         'color: var(--text);\n'
         'font-weight: 600;'
        ),
        
        # Stream item
        ('.stream', '', 
         'display: flex;\n'
         'gap: 8px;\n'
         'padding: 5px 0;\n'
         'border-bottom: 1px solid var(--line);\n'
         'font-size: 12.5px;'
        ),
        
        # Last stream item
        ('.stream:last-child', '', 'border-bottom: 0;'),
        
        # Time element in stream
        ('.stream .when', '', 
         'color: var(--muted);\n'
         'white-space: nowrap;\n'
         'font-variant-numeric: tabular-nums;'
        ),
        
        # Title element in stream
        ('.stream .t', '', 
         'flex: 1;\n'
         'min-width: 0;\n'
         'overflow: hidden;\n'
         'text-overflow: ellipsis;\n'
         'white-space: nowrap;'
        ),
        
        # Current/live stream
        ('.stream.now', '', 
         'color: var(--accent);\n'
         'font-weight: 650;'
        ),
        
        # Error message box
        ('.err', '', 
         'background: #3a1d22;\n'
         'border: 1px solid #5c2a33;\n'
         'color: #ffb4c0;\n'
         'padding: 8px 10px;\n'
         'border-radius: 8px;\n'
         'font-size: 12.5px;\n'
         'margin-bottom: 8px;'
        ),
        
        # Light theme override for error box
        ('@media (prefers-color-scheme: light)', [
            ('.err', '', 
             'background: #fdeceb;\n'
             'border-color: #f5c6c2;\n'
             'color: #b91c1c;'
            )
        ]),
        
        # Note text
        ('.note', '', 
         'font-size: 11.5px;\n'
         'color: var(--muted);\n'
         'line-height: 1.4;\n'
         'margin-top: 8px;'
        ),
        
        # Link styles
        ('a', '', 'color: var(--accent);')
    ]
    
    return css_rules

def format_css(rules):
    """Converts structured CSS rules into a CSS string."""
    output = []
    
    for rule in rules:
        if rule[0] == 'comment':
            output.append(rule[1])
        elif isinstance(rule[1], list):  # Nested rules like @media
            output.append(f"{rule[0]} {{")
            for sub_rule in rule[1]:
                if sub_rule[0] == 'comment':
                    output.append(f"  {sub_rule[1]}")
                else:
                    output.append(f"  {sub_rule[0]} {{")
                    vars_part = ""
                    if isinstance(sub_rule[1], dict):
                        vars_lines = [f"    {k}: {v};" for k, v in sub_rule[1].items()]
                        vars_part = "\n".join(vars_lines)
                    
                    body_part = sub_rule[2]
                    if vars_part and body_part:
                        content = f"{vars_part}\n    {body_part}"
                    else:
                        content = vars_part or body_part
                        
                    output.append(content)
                    output.append("  }")
            output.append("}")
        else:
            output.append(f"{rule[0]} {{")
            vars_part = ""
            if isinstance(rule[1], dict):
                vars_lines = [f"  {k}: {v};" for k, v in rule[1].items()]
                vars_part = "\n".join(vars_lines)
            
            body_part = rule[2]
            if vars_part and body_part:
                content = f"{vars_part}\n  {body_part}"
            else:
                content = vars_part or body_part
                
            output.append(content)
            output.append("}")
    
    return "\n\n".join(output)

def main():
    """Main function to write CSS to file."""
    if len(sys.argv) != 2:
        print("Usage: python3 popup_css_generator.py <output_file>")
        sys.exit(1)
        
    output_file = sys.argv[1]
    css_rules = generate_css()
    css_content = format_css(css_rules)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(css_content)

if __name__ == "__main__":
    main()
