#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "3053e2ebae455a294827b906ded91a3a6ba30ef8cc61fbc55fb6acf0b0e56e4f", "source_sha256": "f9571a381240f9d09733d99d5efdbd1df3ed653107eadfccbced6324e1b78049", "target_language": "python"}
# index_6925e5.css — portiert nach python
# Quelle: css, Projects@abstractions:css/index_6925e5.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import sys

def generate_css():
    """Generates the CSS content as a string."""
    
    # Define CSS rules using Python dictionaries and strings to represent structure
    
    # Root variables for light mode
    root_light = {
        '--bg': '#fff',
        '--soft': '#f6f7f9',
        '--line': '#e3e6ea',
        '--text': '#16191d',
        '--muted': '#5f6773',
        '--ac': '#6d5bd0',
        '--ac-soft': '#efecfb',
        '--ok': '#15803d',
        '--ok-soft': '#e7f6ec',
        '--warn': '#b45309',
        '--warn-soft': '#fdf3e3',
        'color-scheme': 'light'
    }

    # Dark mode media query with overridden variables
    root_dark = {
        '--bg': '#0f1115',
        '--soft': '#171a21',
        '--line': '#262b36',
        '--text': '#f2f4f8',
        '--muted': '#9aa3b2',
        '--ac-soft': '#1e1a33',
        '--ok-soft': '#12261a',
        '--warn-soft': '#2c2110',
        'color-scheme': 'dark'
    }

    # Universal selector
    universal = {
        'box-sizing': 'border-box'
    }

    # Body styles
    body = {
        'margin': '0',
        'background': 'var(--bg)',
        'color': 'var(--text)',
        'font': '16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif'
    }

    # Wrap class
    wrap = {
        'max-width': '840px',
        'margin': '0 auto',
        'padding': '0 20px 72px'
    }

    # Header styles
    header = {
        'padding': '64px 0 36px',
        'border-bottom': '1px solid var(--line)'
    }

    # H1 styles
    h1 = {
        'font-size': '34px',
        'line-height': '1.2',
        'margin': '0 0 12px',
        'letter-spacing': '-.02em'
    }

    # Lede paragraph
    lede = {
        'font-size': '18px',
        'color': 'var(--muted)',
        'margin': '0 0 20px',
        'max-width': '62ch'
    }

    # H2 heading
    h2 = {
        'font-size': '13px',
        'margin': '48px 0 14px',
        'text-transform': 'uppercase',
        'letter-spacing': '.06em',
        'color': 'var(--muted)',
        'font-weight': '650'
    }

    # H3 heading
    h3 = {
        'font-size': '17px',
        'margin': '24px 0 6px'
    }

    # Paragraph styles
    p = {
        'margin': '0 0 14px',
        'max-width': '70ch'
    }

    # Badges container
    badges = {
        'display': 'flex',
        'gap': '7px',
        'flex-wrap': 'wrap',
        'margin-bottom': '20px'
    }

    # Individual badge style
    badge = {
        'font-size': '12px',
        'font-weight': '650',
        'padding': '4px 11px',
        'border-radius': '99px',
        'background': 'var(--soft)',
        'color': 'var(--muted)',
        'border': '1px solid var(--line)'
    }

    # Active badge modifier
    badge_on = {
        'background': 'var(--ok-soft)',
        'color': 'var(--ok)',
        'border-color': 'transparent'
    }

    # Table styling
    table = {
        'border-collapse': 'collapse',
        'width': '100%',
        'font-size': '14.5px',
        'margin': '0 0 14px'
    }

    # Table headers and cells
    th_td = {
        'text-align': 'left',
        'padding': '9px 10px',
        'border-bottom': '1px solid var(--line)',
        'vertical-align': 'top'
    }

    th = {
        'font-size': '12px',
        'text-transform': 'uppercase',
        'letter-spacing': '.04em',
        'color': 'var(--muted)'
    }

    # Inline code
    code = {
        'background': 'var(--soft)',
        'padding': '2px 7px',
        'border-radius': '5px',
        'font-size': '13.5px',
        'font-family': 'ui-monospace,SFMono-Regular,Menlo,monospace',
        'word-break': 'break-word'
    }

    # Preformatted text blocks
    pre = {
        'background': 'var(--soft)',
        'border': '1px solid var(--line)',
        'border-radius': '10px',
        'padding': '13px 15px',
        'overflow-x': 'auto',
        'margin': '0 0 14px'
    }

    # Nested code inside pre doesn't need background
    pre_code = {
        'background': 'none',
        'padding': '0'
    }

    # Card component
    card = {
        'border': '1px solid var(--line)',
        'border-radius': '12px',
        'padding': '18px 20px',
        'background': 'var(--bg)'
    }

    # Note alert box
    note = {
        'background': 'var(--warn-soft)',
        'border': '1px solid transparent',
        'border-radius': '10px',
        'padding': '14px 16px',
        'margin': '0 0 16px',
        'font-size': '14.5px'
    }

    # Strong text in notes
    note_b = {
        'color': 'var(--warn)'
    }

    # Fieldset grouping
    fieldset = {
        'border': '1px solid var(--line)',
        'border-radius': '10px',
        'padding': '14px 16px',
        'margin': '0 0 14px'
    }

    # Legend within fieldsets
    legend = {
        'font-size': '12px',
        'text-transform': 'uppercase',
        'letter-spacing': '.05em',
        'color': 'var(--muted)',
        'padding': '0 6px'
    }

    # Question label layout
    label_q = {
        'display': 'flex',
        'gap': '10px',
        'align-items': 'flex-start',
        'padding': '7px 0',
        'font-size': '15px',
        'cursor': 'pointer'
    }

    # Input alignment tweak
    label_q_input = {
        'margin-top': '4px',
        'flex': 'none'
    }

    # Supporting text under labels
    label_q_span_small = {
        'display': 'block',
        'color': 'var(--muted)',
        'font-size': '13px'
    }

    # Results section spacing
    ergebnis = {
        'margin-top': '6px'
    }

    # Final verdict display
    verdict = {
        'border': '1px solid var(--line)',
        'border-left': '4px solid var(--ac)',
        'border-radius': '10px',
        'padding': '16px 18px',
        'background': 'var(--soft)'
    }

    # Heading in verdict
    verdict_h3 = {
        'margin': '0 0 6px',
        'font-size': '18px'
    }

    # Step indicators
    verdict_step = {
        'font-weight': '650',
        'margin': '10px 0 0'
    }

    # Warning highlight in verdict
    verdict_w = {
        'margin-top': '12px',
        'padding': '11px 13px',
        'background': 'var(--warn-soft)',
        'border-radius': '8px',
        'font-size': '14px'
    }

    # Probe input group
    probe = {
        'display': 'flex',
        'gap': '8px',
        'flex-wrap': 'wrap',
        'margin-bottom': '12px'
    }

    # Text inputs in probes
    probe_input = {
        'flex': '1 1 240px',
        'padding': '10px 12px',
        'border': '1px solid var(--line)',
        'border-radius': '9px',
        'background': 'var(--bg)',
        'color': 'var(--text)',
        'font-size': '15px'
    }

    # Button base
    btn = {
        'font-weight': '650',
        'font-size': '15px',
        'padding': '10px 18px',
        'border-radius': '9px',
        'border': '1px solid var(--ac)',
        'background': 'var(--ac)',
        'color': '#fff',
        'cursor': 'pointer'
    }

    # Ghost button variant
    btn_ghost = {
        'background': 'var(--bg)',
        'color': 'var(--text)',
        'border-color': 'var(--line)'
    }

    # Footer area
    footer = {
        'margin-top': '56px',
        'padding-top': '22px',
        'border-top': '1px solid var(--line)',
        'color': 'var(--muted)',
        'font-size': '14px'
    }

    # Link colors
    a = {
        'color': 'var(--ac)'
    }

    # Build CSS output from defined rules
    css_content = ""

    # Add comments at start
    css_content += "/* abstraction-provenance: {\"artifact_sha256\": \"ede701dd0faa101fb7d23c7e6bd8e28625c33e7b3d07a7ededc1bf14cbfcb761\", \"source_sha256\": \"6925e5ed34d3344b10c23ce3442546a31631cc8434f3b7df4bdc003d32218523\", \"target_language\": \"css\"} */\n"
    css_content += "/* index.html — portiert nach css */\n"
    css_content += "/* Quelle: html, Projects@MCP-Server-Monitor:public/index.html */\n"
    css_content += "/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */\n\n"

    # Root light theme
    css_content += ":root{\n"
    for prop, value in root_light.items():
        css_content += f"  {prop}:{value}; "
    css_content = css_content.rstrip() + "\n}\n"

    # Media query for dark theme
    css_content += "@media (prefers-color-scheme: dark){\n"
    css_content += "  :root{ "
    for prop, value in root_dark.items():
        css_content += f"{prop}:{value}; "
    css_content = css_content.rstrip() + " }\n}\n"

    # Universal selector
    css_content += "*{"
    for prop, value in universal.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Body
    css_content += "body{"
    for prop, value in body.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Wrap
    css_content += ".wrap{"
    for prop, value in wrap.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Header
    css_content += "header{"
    for prop, value in header.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # H1
    css_content += "h1{"
    for prop, value in h1.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Lede
    css_content += ".lede{"
    for prop, value in lede.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # H2
    css_content += "h2{"
    for prop, value in h2.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # H3
    css_content += "h3{"
    for prop, value in h3.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # P
    css_content += "p{"
    for prop, value in p.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Badges container
    css_content += ".badges{"
    for prop, value in badges.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Badge
    css_content += ".badge{"
    for prop, value in badge.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Badge on state
    css_content += ".badge.on{"
    for prop, value in badge_on.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Table
    css_content += "table{"
    for prop, value in table.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # TH & TD shared
    css_content += "th,td{"
    for prop, value in th_td.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # TH specific
    css_content += "th{"
    for prop, value in th.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Code
    css_content += "code{"
    for prop, value in code.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Pre
    css_content += "pre{"
    for prop, value in pre.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Pre > Code
    css_content += "pre code{"
    for prop, value in pre_code.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Card
    css_content += ".card{"
    for prop, value in card.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Note
    css_content += ".note{"
    for prop, value in note.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Note B
    css_content += ".note b{"
    for prop, value in note_b.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Fieldset
    css_content += "fieldset{"
    for prop, value in fieldset.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Legend
    css_content += "legend{"
    for prop, value in legend.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Label Q
    css_content += "label.q{"
    for prop, value in label_q.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Label Q Input
    css_content += "label.q input{"
    for prop, value in label_q_input.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Label Q Span Small
    css_content += "label.q span small{"
    for prop, value in label_q_span_small.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Ergebnis
    css_content += "#ergebnis{"
    for prop, value in ergebnis.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Verdict
    css_content += ".verdict{"
    for prop, value in verdict.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Verdict H3
    css_content += ".verdict h3{"
    for prop, value in verdict_h3.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Verdict Step
    css_content += ".verdict .step{"
    for prop, value in verdict_step.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Verdict W
    css_content += ".verdict .w{"
    for prop, value in verdict_w.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Probe
    css_content += ".probe{"
    for prop, value in probe.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Probe Input
    css_content += ".probe input{"
    for prop, value in probe_input.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Btn
    css_content += ".btn{"
    for prop, value in btn.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Btn Ghost
    css_content += ".btn.ghost{"
    for prop, value in btn_ghost.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Footer
    css_content += "footer{"
    for prop, value in footer.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    # Anchor tag
    css_content += "a{"
    for prop, value in a.items():
        css_content += f"{prop}:{value};"
    css_content += "}\n"

    return css_content


def write_css_to_file(filename):
    """Writes generated CSS to specified file."""
    css_data = generate_css()
    with open(filename, 'w') as f:
        f.write(css_data)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <output_filename>")
        sys.exit(1)
    
    output_file = sys.argv[1]
    write_css_to_file(output_file)
    print(f"CSS written to {output_file}")
