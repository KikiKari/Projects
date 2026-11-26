#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "6b0744a6c18e820c89191dc036c573d3e22fd9379656e02941729cc7796bbc8d", "source_sha256": "fce23ec10c43acef00ba36b3975889539f87b908bd4cfce77616443d2b5f569e", "target_language": "javascript"}
// icon-controls.css — portiert nach javascript
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Helper function to generate CSS variables for icon styles
function generateIconStyle(styleName) {
    const icons = [
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
    ];

    const vars = icons.map(icon => 
        `--icon-${icon}:url("icons/${styleName}/${icon}.png")`
    ).join(';');

    return `html[data-icon-style="${styleName}"] {${vars};}`;
}

// Generate the complete CSS content
function generateCSS() {
    // Generate icon style rules
    const iconStyles = ['plastisch', 'glass', 'linear']
        .map(style => generateIconStyle(style))
        .join('\n');

    // Common control styles
    const controlStyles = `
button[data-control-icon]::before,.control-icon::before { content:""; display:inline-block; width:32px; height:32px; flex:0 0 32px; background:var(--control-icon) center/contain no-repeat; vertical-align:middle; margin-inline-end:0; pointer-events:none; }
button[data-control-icon] { min-height:44px; min-width:44px; font-size:0; display:inline-flex; align-items:center; justify-content:center; }
button[data-control-icon][hidden] { display:none; }
input[type="checkbox"] { appearance:none; -webkit-appearance:none; width:44px; height:44px; min-width:44px; border:0; background:var(--icon-off) center/40px no-repeat; cursor:pointer; vertical-align:middle; }
input[type="checkbox"]:checked { background-image:var(--icon-on); }
input[type="checkbox"]:focus-visible,button[data-control-icon]:focus-visible { outline:2px solid #1769df; outline-offset:2px; }
input[type="checkbox"]:disabled { opacity:.45; cursor:default; }
.control-icon { display:inline-flex; align-items:center; }
input[type="range"] { min-height:32px; }
.icon-style-setting { display:flex; align-items:center; gap:8px; }`;

    // Icon control variable mappings
    const iconControls = [
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
    ].map(icon => `[data-control-icon="${icon}"] { --control-icon:var(--icon-${icon}); }`)
      .join('\n');

    return `${iconStyles}\n${controlStyles.trim()}\n${iconControls}`;
}

// Main execution
function main() {
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
        console.error('Bitte geben Sie einen Dateinamen an.');
        process.exit(1);
    }
    
    const filename = args[0];
    const cssContent = generateCSS();
    
    try {
        writeFileSync(filename, cssContent, 'utf8');
        console.log(`CSS erfolgreich in ${filename} geschrieben.`);
    } catch (error) {
        console.error('Fehler beim Schreiben der Datei:', error.message);
        process.exit(1);
    }
}

main();
