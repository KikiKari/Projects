#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "3ab9f192dc00873879238964b776ecaefff984d5fb67745ec9be4ba4bb577f50", "source_sha256": "08fdd65a33a6ec90261b4ce48be82ca8338400da1b321dfc70a57bedabfa45aa", "target_language": "powershell"}
# App.css — portiert nach powershell
# Quelle: css, OpenClaw@main:src/App.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Function to create CSS rule
function New-CssRule {
    param(
        [string]$Selector,
        [hashtable]$Properties
    )
    
    $propStrings = @()
    foreach ($key in $Properties.Keys) {
        if ($Properties[$key] -is [array]) {
            foreach ($value in $Properties[$key]) {
                $propStrings += "  $($key): $($value);"
            }
        } else {
            $propStrings += "  $($key): $($Properties[$key]);"
        }
    }
    
    return "$($Selector) {`n$($propStrings -join "`n")`n}"
}

# Build CSS rules
$cssRules = @()

# Root rule
$cssRules += New-CssRule ":root" @{
    "color-scheme" = "dark"
    "font-family" = "Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, `"Segoe UI`", sans-serif"
    "background" = "#0b1020"
    "color" = "#eef2ff"
}

# Universal selector
$cssRules += New-CssRule "*" @{
    "box-sizing" = "border-box"
}

# Body rule
$cssRules += New-CssRule "body" @{
    "margin" = "0"
    "min-width" = "320px"
    "min-height" = "100vh"
    "background" = @(
        "radial-gradient(circle at 20% 20%, rgba(56, 189, 248, 0.22), transparent 30rem)"
        "radial-gradient(circle at 80% 10%, rgba(168, 85, 247, 0.2), transparent 28rem)"
        "linear-gradient(135deg, #050816 0%, #111827 55%, #172033 100%)"
    )
}

# Page shell rule
$cssRules += New-CssRule ".page-shell" @{
    "min-height" = "100vh"
    "display" = "grid"
    "place-items" = "center"
    "padding" = "2rem"
}

# Hero card rule
$cssRules += New-CssRule ".hero-card" @{
    "width" = "min(100%, 56rem)"
    "padding" = "clamp(2rem, 6vw, 4.5rem)"
    "border" = "1px solid rgba(148, 163, 184, 0.28)"
    "border-radius" = "2rem"
    "background" = "rgba(15, 23, 42, 0.72)"
    "box-shadow" = "0 2rem 6rem rgba(0, 0, 0, 0.35)"
    "backdrop-filter" = "blur(18px)"
}

# Eyebrow rule
$cssRules += New-CssRule ".eyebrow" @{
    "margin" = "0 0 1rem"
    "color" = "#67e8f9"
    "font-size" = "0.8rem"
    "font-weight" = "700"
    "letter-spacing" = "0.18em"
    "text-transform" = "uppercase"
}

# H1 rule
$cssRules += New-CssRule "h1" @{
    "margin" = "0"
    "max-width" = "12ch"
    "font-size" = "clamp(2.75rem, 8vw, 6rem)"
    "line-height" = "0.95"
    "letter-spacing" = "-0.06em"
}

# Lead rule
$cssRules += New-CssRule ".lead" @{
    "margin" = "1.5rem 0 0"
    "max-width" = "42rem"
    "color" = "#cbd5e1"
    "font-size" = "clamp(1.05rem, 2vw, 1.35rem)"
    "line-height" = "1.65"
}

# Link grid container rule
$cssRules += New-CssRule ".link-grid" @{
    "display" = "grid"
    "gap" = "0.85rem"
    "margin-top" = "2rem"
}

# Link grid item rule
$cssRules += New-CssRule ".link-grid a" @{
    "display" = "flex"
    "align-items" = "center"
    "justify-content" = "space-between"
    "gap" = "1rem"
    "padding" = "1rem 1.15rem"
    "border" = "1px solid rgba(148, 163, 184, 0.25)"
    "border-radius" = "1rem"
    "color" = "#f8fafc"
    "text-decoration" = "none"
    "background" = "rgba(255, 255, 255, 0.06)"
}

# Link grid hover/focus rule
$cssRules += New-CssRule ".link-grid a:hover, .link-grid a:focus-visible" @{
    "border-color" = "rgba(103, 232, 249, 0.75)"
    "outline" = "none"
    "background" = "rgba(103, 232, 249, 0.12)"
}

# Join all rules with double newlines
$cssContent = $cssRules -join "`n`n"

# Write to file
$cssContent | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "CSS file written to: $OutputPath"
