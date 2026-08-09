#!/usr/bin/env python3
# globals.css — portiert nach python
# Quelle: css, Onboarding@main:app/globals.css
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import sys
from pathlib import Path

def generate_css():
    """Generate the CSS content programmatically"""
    
    # Define variables
    variables = {
        'bg': '#faf8f4',
        'surface': '#ffffff',
        'surface-2': '#f1eee7',
        'ink': '#1b1a17',
        'ink-2': '#3c3a34',
        'muted': '#6e6a61',
        'line': '#e5e1d8',
        'line-strong': '#d4cfc3',
        'accent': '#a8542f',
        'accent-press': '#8e4526',
        'accent-tint': '#f1e5dd',
        'on-accent': '#ffffff',
        'accent-2': '#2e7d7b',
        'accent-2-press': '#225e5b',
        'accent-3': '#c77d2e',
        'footer-bg': '#191815',
        'footer-fg': '#efeae0',
        'footer-muted': '#9a958a',
        'success': '#2e7d5b',
        'danger': '#9e3f32',
        'font-display': '"Iowan Old Style", "Palatino Linotype", Georgia, "Times New Roman", serif',
        'font-sans': '"Segoe UI", Inter, system-ui, -apple-system, sans-serif',
        'font-mono': '"Cascadia Code", "SFMono-Regular", Consolas, ui-monospace, monospace',
        'space-1': '0.25rem',
        'space-2': '0.5rem',
        'space-3': '0.75rem',
        'space-4': '1rem',
        'space-5': '1.25rem',
        'space-6': '1.5rem',
        'space-8': '2rem',
        'space-10': '2.5rem',
        'space-12': '3rem',
        'space-16': '4rem',
        'space-20': '5rem',
        'space-24': '6rem',
        'space-30': '7.5rem',
        'radius-sm': '0.375rem',
        'radius-md': '0.625rem',
        'radius-lg': '1.125rem',
        'radius-pill': '999px',
        'shadow-sm': '0 1px 2px rgb(27 26 23 / 6%)',
        'shadow-md': '0 10px 30px -16px rgb(27 26 23 / 22%)',
        'shadow-lg': '0 34px 70px -34px rgb(27 26 23 / 32%)',
        'container': '75rem',
        'motion-fast': '180ms',
        'motion-base': '350ms',
        'motion-slow': '800ms',
        'ease-out': 'cubic-bezier(0.22, 0.61, 0.36, 1)'
    }
    
    # Build CSS content
    css_parts = []
    
    # Import
    css_parts.append('@import "tailwindcss";')
    css_parts.append('')
    
    # Root variables
    css_parts.append(':root {')
    for key, value in variables.items():
        css_parts.append(f'  --{key}: {value};')
    css_parts.append('}')
    css_parts.append('')
    
    # Theme inline
    css_parts.append('@theme inline {')
    theme_vars = [
        'color-bg', 'color-surface', 'color-surface-2', 'color-ink', 'color-ink-2',
        'color-muted', 'color-line', 'color-line-strong', 'color-accent',
        'color-accent-2', 'color-accent-3', 'font-display', 'font-sans', 'font-mono'
    ]
    for var in theme_vars:
        if var.startswith('color-'):
            original_var = var.replace('color-', '')
            css_parts.append(f'  --{var}: var(--{original_var});')
        else:
            css_parts.append(f'  --{var}: var(--{var});')
    css_parts.append('}')
    css_parts.append('')
    
    # Base styles
    css_parts.append('* { box-sizing: border-box; }')
    css_parts.append('html { scroll-behavior: smooth; }')
    css_parts.append('body {')
    css_parts.append('  margin: 0;')
    css_parts.append('  background: var(--bg);')
    css_parts.append('  color: var(--ink);')
    css_parts.append('  font-family: var(--font-sans);')
    css_parts.append('  line-height: 1.5;')
    css_parts.append('  -webkit-font-smoothing: antialiased;')
    css_parts.append('}')
    css_parts.append('a { color: inherit; }')
    css_parts.append('button, input, textarea { font: inherit; }')
    css_parts.append('::selection { background: var(--accent-tint); color: var(--ink); }')
    css_parts.append('')
    
    # Utility classes
    css_parts.append('.display {')
    css_parts.append('  font-family: var(--font-display);')
    css_parts.append('  font-weight: 400;')
    css_parts.append('  letter-spacing: -0.022em;')
    css_parts.append('}')
    css_parts.append('.eyebrow {')
    css_parts.append('  font-family: var(--font-mono);')
    css_parts.append('  font-size: 0.75rem;')
    css_parts.append('  letter-spacing: 0.16em;')
    css_parts.append('  text-transform: uppercase;')
    css_parts.append('}')
    css_parts.append('.focus-ring:focus-visible {')
    css_parts.append('  outline: 2px solid var(--accent);')
    css_parts.append('  outline-offset: 4px;')
    css_parts.append('}')
    css_parts.append('.content-auto { content-visibility: auto; contain-intrinsic-size: 1px 800px; }')
    css_parts.append('')
    
    # Media query
    css_parts.append('@media (prefers-reduced-motion: reduce) {')
    css_parts.append('  html { scroll-behavior: auto; }')
    css_parts.append('  *, *::before, *::after {')
    css_parts.append('    animation-duration: 0.01ms !important;')
    css_parts.append('    animation-iteration-count: 1 !important;')
    css_parts.append('    scroll-behavior: auto !important;')
    css_parts.append('    transition-duration: 0.01ms !important;')
    css_parts.append('  }')
    css_parts.append('}')
    css_parts.append('')
    
    # Comments and special styles
    css_parts.append('/* Header ausblenden solange PondExperience aktiv ist (data-hero-immersive) */')
    css_parts.append('body[data-hero-immersive="true"] > header,')
    css_parts.append('body[data-hero-immersive="true"] header[data-site-header] {')
    css_parts.append('  opacity: 0;')
    css_parts.append('  pointer-events: none;')
    css_parts.append('  transition: opacity 0.4s ease-out;')
    css_parts.append('}')
    css_parts.append('')
    
    # Keyframes
    css_parts.append('/* Wassertropfen die frontal am Screen herunterlaufen (Splash-Overlay) */')
    css_parts.append('@keyframes dropfall {')
    css_parts.append('  0% {')
    css_parts.append('    transform: translateY(0);')
    css_parts.append('    opacity: 0;')
    css_parts.append('  }')
    css_parts.append('  10% {')
    css_parts.append('    opacity: 0.9;')
    css_parts.append('  }')
    css_parts.append('  90% {')
    css_parts.append('    opacity: 0.7;')
    css_parts.append('  }')
    css_parts.append('  100% {')
    css_parts.append('    transform: translateY(110vh);')
    css_parts.append('    opacity: 0;')
    css_parts.append('  }')
    css_parts.append('}')
    
    return '\n'.join(css_parts)

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 globals.py <output_file>")
        sys.exit(1)
    
    output_file = sys.argv[1]
    css_content = generate_css()
    
    # Write to file
    Path(output_file).write_text(css_content, encoding='utf-8')

if __name__ == "__main__":
    main()
