#!/usr/bin/env python3
# status-overview.css — portiert nach python
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.css
# Erzeugt: 2026-11-01 durch ABSTRACTIONS_MANAGER.py

import sys
import argparse
from dataclasses import dataclass
from typing import List, TextIO

@dataclass
class CSSRule:
    selector: str
    properties: dict[str, str]

class CSSGenerator:
    def __init__(self):
        self.rules: List[CSSRule] = []
        
    def add_rule(self, selector: str, properties: dict[str, str]) -> None:
        self.rules.append(CSSRule(selector, properties))
        
    def generate_css(self) -> str:
        lines = []
        for rule in self.rules:
            # Format properties
            prop_lines = [f"  {prop}: {value};" for prop, value in rule.properties.items()]
            # Combine into rule
            lines.append(f"{rule.selector}{{{''.join(prop_lines)}}}")
        return '\n'.join(lines)
        
    def write_to_file(self, filename: str) -> None:
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(self.generate_css())

def create_status_overview_css() -> CSSGenerator:
    generator = CSSGenerator()
    
    # Universal selector
    generator.add_rule("*", {"box-sizing": "border-box"})
    
    # HTML and body
    generator.add_rule("html,body", {
        "margin": "0",
        "min-height": "100%",
        "background": "#101015",
        "color": "#fff",
        "font": "14px system-ui,sans-serif"
    })
    
    # Body
    generator.add_rule("body", {
        "display": "flex",
        "flex-direction": "column",
        "height": "100vh"
    })
    
    # Header
    generator.add_rule("header", {
        "display": "flex",
        "gap": "1em",
        "align-items": "baseline",
        "padding": "0 12px"
    })
    
    # H1
    generator.add_rule("h1", {
        "font-size": "17px",
        "margin": "8px 0"
    })
    
    # Header p
    generator.add_rule("header p", {
        "font-size": "12px",
        "color": "#bbb",
        "margin": "0"
    })
    
    # Main
    generator.add_rule("main", {
        "flex": "1",
        "min-height": "0",
        "display": "grid",
        "grid-template-columns": "repeat(3,minmax(0,1fr))",
        "grid-template-rows": "repeat(3,minmax(0,1fr))",
        "gap": "4px",
        "padding": "0"
    })
    
    # Tile
    generator.add_rule(".tile", {
        "min-width": "0",
        "min-height": "0",
        "display": "flex",
        "flex-direction": "column",
        "background": "#202026",
        "border": "1px solid #393940"
    })
    
    # Tile h2
    generator.add_rule(".tile h2", {
        "font-size": "13px",
        "margin": "3px 8px"
    })
    
    # Tile video
    generator.add_rule(".tile video", {
        "min-height": "0",
        "width": "100%",
        "flex": "1",
        "object-fit": "contain",
        "background": "#000"
    })
    
    # Tile p
    generator.add_rule(".tile p", {
        "font-size": "11px",
        "margin": "3px 8px",
        "color": "#ddd"
    })
    
    # Grid2 variant
    generator.add_rule("main.grid2", {
        "grid-template-columns": "repeat(2,minmax(0,1fr))",
        "grid-template-rows": "repeat(2,minmax(0,1fr))"
    })
    
    # Hidden tile
    generator.add_rule(".tile[hidden]", {
        "display": "none"
    })
    
    return generator

def main():
    parser = argparse.ArgumentParser(description="Generate status-overview.css")
    parser.add_argument("output_file", help="Output CSS file path")
    args = parser.parse_args()
    
    css_generator = create_status_overview_css()
    css_generator.write_to_file(args.output_file)
    print(f"CSS written to {args.output_file}")

if __name__ == "__main__":
    main()
