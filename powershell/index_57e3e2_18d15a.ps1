#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "2bf282accef5ba06cc6cbffc0ffbdeab19f358780772b78462528f6a6e305187", "source_sha256": "18d15a289b831c9da96c808e0cc1de4dae7bf3dfc35a804a239a992cd82cde89", "target_language": "powershell"}
# index_57e3e2.css — portiert nach powershell
# Quelle: css, Projects@abstractions:css/index_57e3e2.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

<#
    .SYNOPSIS
        Generates the index_57e3e2.css file from PowerShell logic.

    .DESCRIPTION
        This script programmatically constructs the CSS rules defined in index_57e3e2.css,
        and writes them to a specified output file or to stdout if no file is given.

    .PARAMETER OutputPath
        The path where the generated CSS should be saved. If not provided, output goes to stdout.

    .EXAMPLE
        .\generate-css.ps1 -OutputPath "index_57e3e2.css"
#>

param(
    [string]$OutputPath
)

# Define helper function to generate CSS rule blocks
function New-CssRule {
    param (
        [string]$Selector,
        [hashtable]$Properties
    )

    $propLines = $Properties.GetEnumerator() | ForEach-Object {
        "  $($_.Key): $($_.Value);"
    }

    "$Selector {`n$($propLines -join "`n")`n}"
}

# Build CSS rules as objects
$rules = @()

# Root
$rules += ":root {`n  color-scheme: light;`n}"

# Universal selector
$rules += "* {`n  box-sizing: border-box;`n}"

# Body
$rules += New-CssRule "body" @{
    margin = "0"
    "font-family" = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif'
    background = "#f7f7f5"
    color = "#1d1c1a"
}

# Wrap
$rules += New-CssRule ".wrap" @{
    "max-width" = "880px"
    margin = "0 auto"
    padding = "20px 16px 60px"
}

# Headings
$rules += New-CssRule "h1" @{
    "font-size" = "22px"
    margin = "0 0 2px"
}

# Subtitle
$rules += New-CssRule ".sub" @{
    color = "#6b6a66"
    "font-size" = "13px"
    "margin-bottom" = "16px"
}

# Bar
$rules += New-CssRule ".bar" @{
    display = "flex"
    gap = "10px"
    "align-items" = "center"
    "margin-bottom" = "16px"
    "flex-wrap" = "wrap"
}

# Buttons
$rules += New-CssRule "button" @{
    "font-size" = "13px"
    "font-weight" = "600"
    padding = "7px 13px"
    border = "1px solid #d9d8d3"
    "border-radius" = "8px"
    background = "#fff"
    cursor = "pointer"
}

$rules += New-CssRule "button:hover" @{
    background = "#f2f1ec"
}

$rules += New-CssRule "button.primary" @{
    background = "#1d1c1a"
    color = "#fff"
    "border-color" = "#1d1c1a"
}

# Note
$rules += New-CssRule ".note" @{
    background = "#fffdf4"
    border = "1px solid #f0e9c8"
    "border-radius" = "10px"
    padding = "12px 14px"
    "font-size" = "13px"
    color = "#4a4734"
    "margin-bottom" = "16px"
    "line-height" = "1.5"
}

# Section
$rules += New-CssRule ".section" @{
    background = "#fff"
    border = "1px solid #e8e7e3"
    "border-radius" = "12px"
    "margin-bottom" = "14px"
    overflow = "hidden"
}

$rules += New-CssRule ".section > h2" @{
    "font-size" = "15px"
    margin = "0"
    padding = "13px 16px"
    "border-bottom" = "1px solid #efeee9"
    display = "flex"
    "align-items" = "center"
    gap = "9px"
}

$rules += New-CssRule ".section > h2 .badge" @{
    "margin-left" = "auto"
    "font-size" = "12px"
    "font-weight" = "600"
    background = "#efeee9"
    color = "#5a5852"
    padding = "2px 9px"
    "border-radius" = "20px"
}

# Body content
$rules += New-CssRule ".body" @{
    padding = "8px 16px 14px"
    "font-size" = "14px"
}

# Muted text
$rules += New-CssRule ".muted" @{
    color = "#8a8884"
}

# Error text
$rules += New-CssRule ".err" @{
    color = "#c0392b"
}

# Key-value list
$rules += New-CssRule ".kv" @{
    display = "flex"
    "justify-content" = "space-between"
    padding = "4px 0"
    "border-bottom" = "1px solid #f4f3ee"
}

$rules += New-CssRule ".kv:last-child" @{
    border = "none"
}

$rules += New-CssRule ".kv .k" @{
    color = "#6b6a66"
}

$rules += New-CssRule ".kv .v" @{
    "font-weight" = "600"
}

# Links
$rules += New-CssRule "a" @{
    color = "#2b5cc4"
    "text-decoration" = "none"
}

$rules += New-CssRule "a:hover" @{
    "text-decoration" = "underline"
}

# Modal
$rules += New-CssRule ".modal" @{
    position = "fixed"
    inset = "0"
    background = "rgba(0, 0, 0, .35)"
    display = "none"
    "align-items" = "flex-start"
    "justify-content" = "center"
    padding = "40px 16px"
    overflow = "auto"
}

$rules += New-CssRule ".modal.open" @{
    display = "flex"
}

# Card
$rules += New-CssRule ".card" @{
    background = "#fff"
    "border-radius" = "14px"
    "max-width" = "560px"
    width = "100%"
    padding = "20px"
}

$rules += New-CssRule ".card h3" @{
    margin = "0 0 4px"
    "font-size" = "17px"
}

$rules += New-CssRule ".card p.hint" @{
    margin = "0 0 16px"
    "font-size" = "12px"
    color = "#8a8884"
}

# Field
$rules += New-CssRule ".field" @{
    "margin-bottom" = "12px"
}

$rules += New-CssRule ".field label" @{
    display = "block"
    "font-size" = "12px"
    "font-weight" = "600"
    color = "#5a5852"
    "margin-bottom" = "3px"
}

$rules += New-CssRule ".field input" @{
    width = "100%"
    "font-size" = "13px"
    padding = "7px 9px"
    border = "1px solid #d9d8d3"
    "border-radius" = "7px"
    "font-family" = "ui-monospace, Menlo, monospace"
}

$rules += New-CssRule ".field .desc" @{
    "font-size" = "11px"
    color = "#a8a6a1"
    "margin-top" = "2px"
}

# Actions
$rules += New-CssRule ".actions" @{
    display = "flex"
    gap = "10px"
    "justify-content" = "flex-end"
    "margin-top" = "8px"
}

# Warning box
$rules += New-CssRule ".warn" @{
    background = "#fdf3f3"
    border = "1px solid #f3d9d9"
    color = "#9a3b3b"
    "border-radius" = "8px"
    padding = "10px 12px"
    "font-size" = "12px"
    "margin-bottom" = "14px"
}

# Combine all rules with newlines
$outputContent = ($rules -join "`n`n")

# Add comments at the top (as in original)
$headerComment = @"
/* abstraction-provenance: {"artifact_sha256": "a05439af4536c91ed01734c3151c3870ffe206fc2433d74fe3db29d4666579ca", "source_sha256": "57e3e28b7c96948ea289f7d9401b6d0bf990d118129de570394784d35e23cf4c", "target_language": "css"} */
/* index.html — portiert nach css */
/* Quelle: html, Projects@tagesstatus-live-public:tagesstatus-live-public/index.html */
/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */

"@

$fullOutput = $headerComment + $outputContent

# Write to file or stdout
if ($OutputPath) {
    Set-Content -Path $OutputPath -Value $fullOutput -Encoding Utf8
} else {
    Write-Output $fullOutput
}
