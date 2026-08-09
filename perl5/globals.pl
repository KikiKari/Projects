#!/usr/bin/perl
# globals.css — portiert nach perl5
# Quelle: css, Onboarding@main:app/globals.css
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

sub write_globals_css {
    my ($filename) = @_;
    
    open my $fh, '>', $filename or die "Cannot open $filename: $!";
    
    print $fh '@import "tailwindcss";' . "\n\n";
    
    print $fh ":root {\n";
    print $fh "  --bg: #faf8f4;\n";
    print $fh "  --surface: #ffffff;\n";
    print $fh "  --surface-2: #f1eee7;\n";
    print $fh "  --ink: #1b1a17;\n";
    print $fh "  --ink-2: #3c3a34;\n";
    print $fh "  --muted: #6e6a61;\n";
    print $fh "  --line: #e5e1d8;\n";
    print $fh "  --line-strong: #d4cfc3;\n";
    print $fh "  --accent: #a8542f;\n";
    print $fh "  --accent-press: #8e4526;\n";
    print $fh "  --accent-tint: #f1e5dd;\n";
    print $fh "  --on-accent: #ffffff;\n";
    print $fh "  --accent-2: #2e7d7b;\n";
    print $fh "  --accent-2-press: #225e5b;\n";
    print $fh "  --accent-3: #c77d2e;\n";
    print $fh "  --footer-bg: #191815;\n";
    print $fh "  --footer-fg: #efeae0;\n";
    print $fh "  --footer-muted: #9a958a;\n";
    print $fh "  --success: #2e7d5b;\n";
    print $fh "  --danger: #9e3f32;\n";
    print $fh "  --font-display: \"Iowan Old Style\", \"Palatino Linotype\", Georgia, \"Times New Roman\", serif;\n";
    print $fh "  --font-sans: \"Segoe UI\", Inter, system-ui, -apple-system, sans-serif;\n";
    print $fh "  --font-mono: \"Cascadia Code\", \"SFMono-Regular\", Consolas, ui-monospace, monospace;\n";
    print $fh "  --space-1: 0.25rem;\n";
    print $fh "  --space-2: 0.5rem;\n";
    print $fh "  --space-3: 0.75rem;\n";
    print $fh "  --space-4: 1rem;\n";
    print $fh "  --space-5: 1.25rem;\n";
    print $fh "  --space-6: 1.5rem;\n";
    print $fh "  --space-8: 2rem;\n";
    print $fh "  --space-10: 2.5rem;\n";
    print $fh "  --space-12: 3rem;\n";
    print $fh "  --space-16: 4rem;\n";
    print $fh "  --space-20: 5rem;\n";
    print $fh "  --space-24: 6rem;\n";
    print $fh "  --space-30: 7.5rem;\n";
    print $fh "  --radius-sm: 0.375rem;\n";
    print $fh "  --radius-md: 0.625rem;\n";
    print $fh "  --radius-lg: 1.125rem;\n";
    print $fh "  --radius-pill: 999px;\n";
    print $fh "  --shadow-sm: 0 1px 2px rgb(27 26 23 / 6%);\n";
    print $fh "  --shadow-md: 0 10px 30px -16px rgb(27 26 23 / 22%);\n";
    print $fh "  --shadow-lg: 0 34px 70px -34px rgb(27 26 23 / 32%);\n";
    print $fh "  --container: 75rem;\n";
    print $fh "  --motion-fast: 180ms;\n";
    print $fh "  --motion-base: 350ms;\n";
    print $fh "  --motion-slow: 800ms;\n";
    print $fh "  --ease-out: cubic-bezier(0.22, 0.61, 0.36, 1);\n";
    print $fh "}\n\n";
    
    print $fh "\@theme inline {\n";
    print $fh "  --color-bg: var(--bg);\n";
    print $fh "  --color-surface: var(--surface);\n";
    print $fh "  --color-surface-2: var(--surface-2);\n";
    print $fh "  --color-ink: var(--ink);\n";
    print $fh "  --color-ink-2: var(--ink-2);\n";
    print $fh "  --color-muted: var(--muted);\n";
    print $fh "  --color-line: var(--line);\n";
    print $fh "  --color-line-strong: var(--line-strong);\n";
    print $fh "  --color-accent: var(--accent);\n";
    print $fh "  --color-accent-2: var(--accent-2);\n";
    print $fh "  --color-accent-3: var(--accent-3);\n";
    print $fh "  --font-display: var(--font-display);\n";
    print $fh "  --font-sans: var(--font-sans);\n";
    print $fh "  --font-mono: var(--font-mono);\n";
    print $fh "}\n\n";
    
    print $fh "* { box-sizing: border-box; }\n";
    print $fh "html { scroll-behavior: smooth; }\n";
    print $fh "body {\n";
    print $fh "  margin: 0;\n";
    print $fh "  background: var(--bg);\n";
    print $fh "  color: var(--ink);\n";
    print $fh "  font-family: var(--font-sans);\n";
    print $fh "  line-height: 1.5;\n";
    print $fh "  -webkit-font-smoothing: antialiased;\n";
    print $fh "}\n";
    print $fh "a { color: inherit; }\n";
    print $fh "button, input, textarea { font: inherit; }\n";
    print $fh "::selection { background: var(--accent-tint); color: var(--ink); }\n\n";
    
    print $fh ".display {\n";
    print $fh "  font-family: var(--font-display);\n";
    print $fh "  font-weight: 400;\n";
    print $fh "  letter-spacing: -0.022em;\n";
    print $fh "}\n";
    print $fh ".eyebrow {\n";
    print $fh "  font-family: var(--font-mono);\n";
    print $fh "  font-size: 0.75rem;\n";
    print $fh "  letter-spacing: 0.16em;\n";
    print $fh "  text-transform: uppercase;\n";
    print $fh "}\n";
    print $fh ".focus-ring:focus-visible {\n";
    print $fh "  outline: 2px solid var(--accent);\n";
    print $fh "  outline-offset: 4px;\n";
    print $fh "}\n";
    print $fh ".content-auto { content-visibility: auto; contain-intrinsic-size: 1px 800px; }\n\n";
    
    print $fh "\@media (prefers-reduced-motion: reduce) {\n";
    print $fh "  html { scroll-behavior: auto; }\n";
    print $fh "  *, *::before, *::after {\n";
    print $fh "    animation-duration: 0.01ms !important;\n";
    print $fh "    animation-iteration-count: 1 !important;\n";
    print $fh "    scroll-behavior: auto !important;\n";
    print $fh "    transition-duration: 0.01ms !important;\n";
    print $fh "  }\n";
    print $fh "}\n\n";
    
    print $fh "/* Header ausblenden solange PondExperience aktiv ist (data-hero-immersive) */\n";
    print $fh "body[data-hero-immersive=\"true\"] > header,\n";
    print $fh "body[data-hero-immersive=\"true\"] header[data-site-header] {\n";
    print $fh "  opacity: 0;\n";
    print $fh "  pointer-events: none;\n";
    print $fh "  transition: opacity 0.4s ease-out;\n";
    print $fh "}\n\n";
    
    print $fh "/* Wassertropfen die frontal am Screen herunterlaufen (Splash-Overlay) */\n";
    print $fh "\@keyframes dropfall {\n";
    print $fh "  0% {\n";
    print $fh "    transform: translateY(0);\n";
    print $fh "    opacity: 0;\n";
    print $fh "  }\n";
    print $fh "  10% {\n";
    print $fh "    opacity: 0.9;\n";
    print $fh "  }\n";
    print $fh "  90% {\n";
    print $fh "    opacity: 0.7;\n";
    print $fh "  }\n";
    print $fh "  100% {\n";
    print $fh "    transform: translateY(110vh);\n";
    print $fh "    opacity: 0;\n";
    print $fh "  }\n";
    print $fh "}\n";
    
    close $fh;
}

# Hauptprogramm
if (@ARGV != 1) {
    die "Usage: $0 <output_filename>\n";
}

my $output_file = $ARGV[0];
write_globals_css($output_file);
