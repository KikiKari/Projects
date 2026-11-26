#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "ba0eea975beda9ce23774ea3e9fd207787b19613e4590f92f5fddb0f70d6620d", "source_sha256": "fce23ec10c43acef00ba36b3975889539f87b908bd4cfce77616443d2b5f569e", "target_language": "powershell"}
# icon-controls.css — portiert nach powershell
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Define the icon styles and their corresponding paths
$iconStyles = @{
    "plastisch" = "icons/plastisch"
    "glass"     = "icons/glass"
    "linear"    = "icons/linear"
}

# Define all icon names
$iconNames = @(
    "auto-chat-refresh-counter",
    "browser",
    "captions",
    "chat-counter",
    "fullscreen",
    "mute",
    "off",
    "on",
    "pip",
    "play",
    "player",
    "protection-slider",
    "recommendation-counter",
    "report",
    "reset",
    "settings",
    "status",
    "stop",
    "unmute",
    "volume-slider"
)

# Start building the CSS content
$cssContent = ""

# Generate CSS for each icon style
foreach ($style in $iconStyles.Keys) {
    $cssContent += "html[data-icon-style=`"$style`"] {"
    
    foreach ($icon in $iconNames) {
        $path = "$($iconStyles[$style])/$icon.png"
        $cssContent += "--icon-$icon:url(`"$path`");"
    }
    
    $cssContent += "}`n"
}

# Add the common control styles
$cssContent += @"
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

"@

# Add the control icon variables
foreach ($icon in $iconNames) {
    $cssContent += "[data-control-icon=`"$icon`"] { --control-icon:var(--icon-$icon); }`n"
}

# Write the CSS content to the specified output file
Set-Content -Path $OutputPath -Value $cssContent

Write-Host "CSS file generated at: $OutputPath"
