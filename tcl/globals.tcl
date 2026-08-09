#!/usr/bin/env tclsh
# globals.css — portiert nach tcl
# Quelle: css, Onboarding@main:app/globals.css
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Tcl-Programm zur Erzeugung der CSS-Datei globals.css
# Portierung von CSS nach Tcl 8.6

proc write_css_file {filename} {
    set fh [open $filename w]
    
    # Schreibe @import
    puts $fh {@import "tailwindcss";}
    puts $fh ""
    
    # Schreibe :root Block
    puts $fh ":root {"
    puts $fh "  --bg: #faf8f4;"
    puts $fh "  --surface: #ffffff;"
    puts $fh "  --surface-2: #f1eee7;"
    puts $fh "  --ink: #1b1a17;"
    puts $fh "  --ink-2: #3c3a34;"
    puts $fh "  --muted: #6e6a61;"
    puts $fh "  --line: #e5e1d8;"
    puts $fh "  --line-strong: #d4cfc3;"
    puts $fh "  --accent: #a8542f;"
    puts $fh "  --accent-press: #8e4526;"
    puts $fh "  --accent-tint: #f1e5dd;"
    puts $fh "  --on-accent: #ffffff;"
    puts $fh "  --accent-2: #2e7d7b;"
    puts $fh "  --accent-2-press: #225e5b;"
    puts $fh "  --accent-3: #c77d2e;"
    puts $fh "  --footer-bg: #191815;"
    puts $fh "  --footer-fg: #efeae0;"
    puts $fh "  --footer-muted: #9a958a;"
    puts $fh "  --success: #2e7d5b;"
    puts $fh "  --danger: #9e3f32;"
    puts $fh {  --font-display: "Iowan Old Style", "Palatino Linotype", Georgia, "Times New Roman", serif;}
    puts $fh {  --font-sans: "Segoe UI", Inter, system-ui, -apple-system, sans-serif;}
    puts $fh {  --font-mono: "Cascadia Code", "SFMono-Regular", Consolas, ui-monospace, monospace;}
    puts $fh "  --space-1: 0.25rem;"
    puts $fh "  --space-2: 0.5rem;"
    puts $fh "  --space-3: 0.75rem;"
    puts $fh "  --space-4: 1rem;"
    puts $fh "  --space-5: 1.25rem;"
    puts $fh "  --space-6: 1.5rem;"
    puts $fh "  --space-8: 2rem;"
    puts $fh "  --space-10: 2.5rem;"
    puts $fh "  --space-12: 3rem;"
    puts $fh "  --space-16: 4rem;"
    puts $fh "  --space-20: 5rem;"
    puts $fh "  --space-24: 6rem;"
    puts $fh "  --space-30: 7.5rem;"
    puts $fh "  --radius-sm: 0.375rem;"
    puts $fh "  --radius-md: 0.625rem;"
    puts $fh "  --radius-lg: 1.125rem;"
    puts $fh "  --radius-pill: 999px;"
    puts $fh "  --shadow-sm: 0 1px 2px rgb(27 26 23 / 6%);"
    puts $fh "  --shadow-md: 0 10px 30px -16px rgb(27 26 23 / 22%);"
    puts $fh "  --shadow-lg: 0 34px 70px -34px rgb(27 26 23 / 32%);"
    puts $fh "  --container: 75rem;"
    puts $fh "  --motion-fast: 180ms;"
    puts $fh "  --motion-base: 350ms;"
    puts $fh "  --motion-slow: 800ms;"
    puts $fh "  --ease-out: cubic-bezier(0.22, 0.61, 0.36, 1);"
    puts $fh "}"
    puts $fh ""
    
    # Schreibe @theme inline Block
    puts $fh "@theme inline {"
    puts $fh "  --color-bg: var(--bg);"
    puts $fh "  --color-surface: var(--surface);"
    puts $fh "  --color-surface-2: var(--surface-2);"
    puts $fh "  --color-ink: var(--ink);"
    puts $fh "  --color-ink-2: var(--ink-2);"
    puts $fh "  --color-muted: var(--muted);"
    puts $fh "  --color-line: var(--line);"
    puts $fh "  --color-line-strong: var(--line-strong);"
    puts $fh "  --color-accent: var(--accent);"
    puts $fh "  --color-accent-2: var(--accent-2);"
    puts $fh "  --color-accent-3: var(--accent-3);"
    puts $fh "  --font-display: var(--font-display);"
    puts $fh "  --font-sans: var(--font-sans);"
    puts $fh "  --font-mono: var(--font-mono);"
    puts $fh "}"
    puts $fh ""
    
    # Schreibe allgemeine CSS-Regeln
    puts $fh "* { box-sizing: border-box; }"
    puts $fh "html { scroll-behavior: smooth; }"
    puts $fh "body {"
    puts $fh "  margin: 0;"
    puts $fh "  background: var(--bg);"
    puts $fh "  color: var(--ink);"
    puts $fh "  font-family: var(--font-sans);"
    puts $fh "  line-height: 1.5;"
    puts $fh "  -webkit-font-smoothing: antialiased;"
    puts $fh "}"
    puts $fh "a { color: inherit; }"
    puts $fh "button, input, textarea { font: inherit; }"
    puts $fh "::selection { background: var(--accent-tint); color: var(--ink); }"
    puts $fh ""
    
    # Schreibe spezifische Klassen
    puts $fh ".display {"
    puts $fh "  font-family: var(--font-display);"
    puts $fh "  font-weight: 400;"
    puts $fh "  letter-spacing: -0.022em;"
    puts $fh "}"
    puts $fh ".eyebrow {"
    puts $fh "  font-family: var(--font-mono);"
    puts $fh "  font-size: 0.75rem;"
    puts $fh "  letter-spacing: 0.16em;"
    puts $fh "  text-transform: uppercase;"
    puts $fh "}"
    puts $fh ".focus-ring:focus-visible {"
    puts $fh "  outline: 2px solid var(--accent);"
    puts $fh "  outline-offset: 4px;"
    puts $fh "}"
    puts $fh ".content-auto { content-visibility: auto; contain-intrinsic-size: 1px 800px; }"
    puts $fh ""
    
    # Schreibe Media Query
    puts $fh "@media (prefers-reduced-motion: reduce) {"
    puts $fh "  html { scroll-behavior: auto; }"
    puts $fh "  *, *::before, *::after {"
    puts $fh "    animation-duration: 0.01ms !important;"
    puts $fh "    animation-iteration-count: 1 !important;"
    puts $fh "    scroll-behavior: auto !important;"
    puts $fh "    transition-duration: 0.01ms !important;"
    puts $fh "  }"
    puts $fh "}"
    puts $fh ""
    
    # Schreibe Kommentar und Header-Ausblend-Regeln
    puts $fh "/* Header ausblenden solange PondExperience aktiv ist (data-hero-immersive) */"
    puts $fh {body[data-hero-immersive="true"] > header,}
    puts $fh {body[data-hero-immersive="true"] header[data-site-header] { }
    puts $fh "  opacity: 0;"
    puts $fh "  pointer-events: none;"
    puts $fh "  transition: opacity 0.4s ease-out;"
    puts $fh "}"
    puts $fh ""
    
    # Schreibe Keyframes
    puts $fh "/* Wassertropfen die frontal am Screen herunterlaufen (Splash-Overlay) */"
    puts $fh "@keyframes dropfall {"
    puts $fh "  0% {"
    puts $fh "    transform: translateY(0);"
    puts $fh "    opacity: 0;"
    puts $fh "  }"
    puts $fh "  10% {"
    puts $fh "    opacity: 0.9;"
    puts $fh "  }"
    puts $fh "  90% {"
    puts $fh "    opacity: 0.7;"
    puts $fh "  }"
    puts $fh "  100% {"
    puts $fh "    transform: translateY(110vh);"
    puts $fh "    opacity: 0;"
    puts $fh "  }"
    puts $fh "}"
    
    close $fh
}

# Hauptprogramm
if {$argc != 1} {
    puts "Verwendung: [info script] <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
write_css_file $output_file
