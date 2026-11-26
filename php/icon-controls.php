<?php
// abstraction-provenance: {"artifact_sha256": "ba1a2553188264f7628e6b5dc84fb32c7e57b2dfb10de94a55cc7f7673c74e94", "source_sha256": "fce23ec10c43acef00ba36b3975889539f87b908bd4cfce77616443d2b5f569e", "target_language": "php"}
// icon-controls.css — portiert nach php
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
function generateIconControlsCSS($outputFile) {
    $styles = ['plastisch', 'glass', 'linear'];
    $icons = [
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

    $css = "";

    // Generate style definitions for each icon style
    foreach ($styles as $style) {
        $css .= "html[data-icon-style=\"$style\"] {";
        foreach ($icons as $icon) {
            $css .= "--icon-$icon:url(\"icons/$style/$icon.png\");";
        }
        $css .= "}\n";
    }

    // Add generic control styles
    $css .= <<<CSS
button[data-control-icon]::before,.control-icon::before { content:""; display:inline-block; width:32px; height:32px; flex:0 0 32px; background:var(--control-icon) center/contain no-repeat; vertical-align:middle; margin-inline-end:0; pointer-events:none; }
button[data-control-icon] { min-height:44px; min-width:44px; font-size:0; display:inline-flex; align-items:center; justify-content:center; }
button[data-control-icon][hidden] { display:none; }
input[type="checkbox"] { appearance:none; -webkit-appearance:none; width:44px; height:44px; min-width:44px; border:0; background:var(--icon-off) center/40px no-repeat; cursor:pointer; vertical-align:middle; }
input[type="checkbox"]:checked { background-image:var(--icon-on); }
input[type="checkbox"]:focus-visible,button[data-control-icon]:focus-visible { outline:2px solid #1769df; outline-offset:2px; }
input[type="checkbox"]:disabled { opacity:.45; cursor:default; }
.control-icon { display:inline-flex; align-items:center; }
input[type="range"] { min-height:32px; }
.icon-style-setting { display:flex; align-items:center; gap:8px; }

CSS;

    // Add individual icon control definitions
    foreach ($icons as $icon) {
        $css .= "[data-control-icon=\"$icon\"] { --control-icon:var(--icon-$icon); }\n";
    }

    // Write to file
    file_put_contents($outputFile, $css);
    
    return true;
}

// Example usage:
// generateIconControlsCSS('icon-controls.css');

?>
