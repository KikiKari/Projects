#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "a5def8300e08410cb8813696f4ddbb6a313c49b7339772934c3359905ed9ad85", "source_sha256": "b32c733987d23de98ace1b2a5119f7cb7989a0887c165c1db133ecb4ef278438", "target_language": "powershell"}
# index_f17dea.css — portiert nach powershell
# Quelle: css, Projects@abstractions:css/index_f17dea.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
    Generates a CSS file with styling for a web page layout.
.DESCRIPTION
    This script generates CSS rules that can be used to style a web page with a navbar,
    hero section, cards, and footer. The output is written to a specified file.
.PARAMETER OutputPath
    The path where the generated CSS file will be saved.
.EXAMPLE
    .\Generate-CSS.ps1 -OutputPath "index_f17dea.css"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Define CSS content as here-string
$cssContent = @'
/* abstraction-provenance: {"artifact_sha256": "9ebfdd610ffe88b7273a5ac8e215314a7bee0dffecf25fe9a995b6a39703e204", "source_sha256": "f17deae3e31b89fd76d250bd20903b36591af417c97b34d987e923632be9ac37", "target_language": "css"} */
/* index.html — portiert nach css */
/* Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/index.html */
/* auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/index.html */
/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */

/* General Styles */
html {
    scroll-padding-top: 60px;
}

body.has-navbar-fixed-top {
    padding-top: 60px;
}

/* Navbar Styles */
.navbar.is-fixed-top {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    z-index: 30;
    min-height: 3.25rem;
}

.navbar.is-flex-touch {
    display: flex;
}

.container.is-justify-content-space-around {
    justify-content: space-around;
}

.navbar-brand {
    display: flex;
    align-items: center;
}

.navbar-logo {
    display: flex;
    align-items: center;
}

.navbar-logo-tm {
    font-size: 0.75rem;
    margin-left: 0.25rem;
}

.navbar-burger {
    display: block;
    position: relative;
    cursor: pointer;
}

.navbar-burger span {
    display: block;
    height: 1px;
    width: 20px;
    background-color: currentColor;
    margin: 5px 0;
    transition: transform 0.3s ease;
}

.navbar-menu {
    display: none;
}

.navbar-start, .navbar-end {
    display: flex;
    align-items: center;
}

.navbar-item {
    display: block;
    padding: 0.5rem 0.75rem;
}

.navbar-link {
    display: block;
    padding: 0.5rem 0.75rem;
}

.navbar-dropdown {
    display: none;
    position: absolute;
    top: 100%;
    left: 0;
    background-color: white;
    border-radius: 4px;
    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1);
}

.navbar-dropdown.is-right {
    left: auto;
    right: 0;
}

.navbar-dropdown.is-rounded {
    border-radius: 4px;
}

.navbar-divider {
    display: block;
    height: 1px;
    background-color: #dbdbdb;
    margin: 0.5rem 0;
}

.has-dropdown:hover .navbar-dropdown {
    display: block;
}

.navbar-search-wrapper {
    display: flex;
    align-items: center;
}

.field.has-addons {
    display: flex;
}

.control {
    position: relative;
}

.autoComplete_options {
    flex-grow: 1;
}

.input {
    display: block;
    width: 100%;
    padding: 0.375rem 0.75rem;
    font-size: 1rem;
    line-height: 1.5;
    color: #495057;
    background-color: #fff;
    background-clip: padding-box;
    border: 1px solid #ced4da;
    border-radius: 0.25rem;
    transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;
}

.button.is-primary {
    background-color: #00d1b2;
    border-color: transparent;
    color: #fff;
}

.icon {
    display: inline-flex;
    justify-content: center;
    align-items: center;
}

.modal {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 40;
    display: none;
    opacity: 0;
    transition: opacity 0.15s linear;
}

.modal.is-active {
    display: flex;
    opacity: 1;
}

.modal-background {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(10, 10, 10, 0.86);
}

.modal-content {
    position: relative;
    width: 100%;
    max-height: calc(100vh - 160px);
    overflow: auto;
    margin: 0 auto;
    padding: 20px;
}

.box {
    background-color: white;
    border-radius: 6px;
    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02);
    padding: 1.25rem;
}

.modal-close {
    position: absolute;
    top: 20px;
    right: 20px;
    width: 40px;
    height: 40px;
    background: none;
    border: none;
    cursor: pointer;
}

.options-search-controls {
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

.centreToggle {
    display: flex;
    align-items: center;
    gap: 0.5rem;
}

.centreToggle input[type="checkbox"] {
    width: var(--switch-width, 10.5em);
    height: 2em;
    appearance: none;
    background: #ccc;
    border-radius: 1em;
    position: relative;
    cursor: pointer;
}

.centreToggle input[type="checkbox"]:checked {
    background: #00d1b2;
}

.centreToggle input[type="checkbox"]::before {
    content: '';
    position: absolute;
    width: 1.6em;
    height: 1.6em;
    background: white;
    border-radius: 50%;
    top: 0.2em;
    left: 0.2em;
    transition: transform 0.3s;
}

.centreToggle input[type="checkbox"]:checked::before {
    transform: translateX(calc(var(--switch-width, 10.5em) - 2em));
}

.centreToggle .text,
.centreToggle .on,
.centreToggle .off {
    font-weight: bold;
}

.centreToggle .on,
.centreToggle .off {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
}

.centreToggle .on {
    left: 0.5em;
    color: white;
}

.centreToggle .off {
    right: 0.5em;
    color: #333;
}

/* Hero Section */
.hero.is-medium {
    min-height: 300px;
}

.hero.is-primary {
    background-color: #00d1b2;
    color: #fff;
}

.hero-body {
    padding: 3rem 1.5rem;
}

.title.is-1 {
    font-size: 3rem;
}

.subtitle.is-4 {
    font-size: 1.5rem;
}

.mt-3 {
    margin-top: 0.75rem;
}

.has-text-centered {
    text-align: center;
}

/* Cards */
.card-home {
    border-radius: 6px;
    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02);
    background-color: white;
    margin-bottom: 1.5rem;
}

.card-content {
    padding: 1.5rem;
}

.content.has-text-centered {
    text-align: center;
}

.title.is-5 {
    font-size: 1.25rem;
    margin-bottom: 0.5rem;
}

.has-text-primary {
    color: #00d1b2 !important;
}

.icon.is-large {
    font-size: 2rem;
}

.button.is-primary {
    background-color: #00d1b2;
    border-color: transparent;
    color: #fff;
}

/* Links Block */
.raku.links-block {
    background-color: #f5f5f5;
    padding: 2rem 0;
}

.columns.is-vcentered {
    align-items: center;
}

.column.is-one-third {
    flex: none;
    width: 33.3333%;
}

.column.is-two-thirds {
    flex: none;
    width: 66.6666%;
}

.pt-5 {
    padding-top: 1.5rem;
}

.head {
    font-weight: bold;
    margin-bottom: 0.5rem;
}

/* Footer */
.footer.main-footer {
    background-color: #fafafa;
    padding: 3rem 1.5rem;
}

.level {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.level-left, .level-right {
    display: flex;
    align-items: center;
}

.level-item {
    margin: 0 0.5rem;
}

/* Responsive Adjustments */
@media screen and (max-width: 1023px) {
    .navbar-menu {
        background-color: white;
        box-shadow: 0 8px 16px rgba(10, 10, 10, 0.1);
        padding: 0.5rem 0;
    }
    
    .navbar-menu.is-active {
        display: block;
    }
    
    .navbar-end {
        margin-top: 1rem;
    }
}

@media screen and (max-width: 768px) {
    .title.is-1.is-size-2-mobile {
        font-size: 2rem;
    }
    
    .columns.is-multiline {
        display: flex;
        flex-wrap: wrap;
    }
    
    .column.is-one-half, 
    .column.is-one-third {
        width: 100%;
    }
    
    .raku.links-block .columns {
        flex-direction: column;
    }
    
    .column.is-one-third, 
    .column.is-two-thirds {
        width: 100%;
    }
}
'@

# Write CSS content to the specified output file
Set-Content -Path $OutputPath -Value $cssContent -Encoding UTF8

Write-Host "CSS file has been generated at: $OutputPath"
