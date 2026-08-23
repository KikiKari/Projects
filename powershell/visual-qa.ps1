#!/usr/bin/env pwsh
# visual-qa.mjs — portiert nach powershell
# Quelle: javascript, Onboarding@main:scripts/visual-qa.mjs
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Visual-QA-Tool der Sandbox — rendert eine laufende Seite in echten Browsern
bei mehreren Auflösungen und legt Screenshots ab, damit Claude das Ergebnis
SELBST betrachten kann, bevor es weiterverwendet wird.

.DESCRIPTION
Warum echtes Chrome: Der Playwright-Bundle-Chromium hat keine proprietären
Codecs (H.264/AAC) → Videos bleiben schwarz. Google Chrome Stable
(channel/executablePath) dekodiert die MP4-Hero-Videos korrekt.

.PARAMETER Url
Die URL zur Seite, die getestet werden soll

.PARAMETER Engines
Liste der Browser-Engines, z.B. chrome,firefox,webkit

.PARAMETER OutDir
Ausgabeverzeichnis für Screenshots

.PARAMETER Click
ARIA-Name des Buttons, der geklickt werden soll

.PARAMETER Wait
Wartezeit in Millisekunden vor dem Screenshot

.PARAMETER Full
Vollständige Seite aufnehmen

.EXAMPLE
xvfb-run -a pwsh visual-qa.ps1 http://localhost:3000 -Engines @("chrome","firefox") -OutDir /tmp/visual-qa
#>

param(
    [string]$Url = "http://localhost:3000",
    [string[]]$Engines = @("chrome"),
    [string]$OutDir = "/tmp/visual-qa",
    [int]$Wait = 3500,
    [string]$Click = $null,
    [switch]$Full
)

# Prüfen ob Playwright installiert ist
try {
    Add-Type -AssemblyName System.Net.Http
    $playwrightModule = Get-Module -ListAvailable -Name Microsoft.Playwright
    if (-not $playwrightModule) {
        Write-Error "Playwright PowerShell module nicht gefunden. Bitte installieren mit: Install-Module -Name Microsoft.Playwright"
        exit 1
    }
    Import-Module Microsoft.Playwright
} catch {
    Write-Error "Fehler beim Laden des Playwright Moduls: $_"
    exit 1
}

$RESOLUTIONS = @(
    @{ Name = "desktop-1920"; Width = 1920; Height = 1080 },
    @{ Name = "desktop-1366"; Width = 1366; Height = 768 },
    @{ Name = "laptop-1440"; Width = 1440; Height = 900 },
    @{ Name = "tablet-1024"; Width = 1024; Height = 768 },
    @{ Name = "mobile-390"; Width = 390; Height = 844 }
)

$CHROME_PATHS = @("/usr/bin/google-chrome-stable", "/usr/bin/google-chrome")

function Launch-Browser([string]$Engine) {
    if ($Engine -eq "chrome") {
        $proxy = $env:HTTPS_PROXY ?? $env:https_proxy ?? $null
        $chromePath = $CHROME_PATHS | Where-Object { Test-Path $_ } | Select-Object -First 1
        
        $launchOptions = @{
            ExecutablePath = $chromePath
        }
        
        if ($proxy) {
            $launchOptions.Proxy = @{
                Server = $proxy
                Bypass = "localhost,127.0.0.1,::1"
            }
        }
        
        return [Microsoft.Playwright.Program]::CreateAsync() | 
               ForEach-Object { $_.Channel.StartAsync("chromium", $launchOptions) }
    }
    
    if ($Engine -eq "firefox") {
        return [Microsoft.Playwright.Program]::CreateAsync() | 
               ForEach-Object { $_.Channel.StartAsync("firefox") }
    }
    
    if ($Engine -eq "webkit") {
        return [Microsoft.Playwright.Program]::CreateAsync() | 
               ForEach-Object { $_.Channel.StartAsync("webkit") }
    }
    
    throw "Unbekannte Engine: $Engine"
}

# Ausgabeverzeichnis erstellen
if (!(Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$manifest = @()

foreach ($engine in $Engines) {
    $browser = $null
    try {
        $browser = Launch-Browser -Engine $engine
    } catch {
        Write-Error "[$engine] Start fehlgeschlagen: $_"
        continue
    }
    
    foreach ($res in $RESOLUTIONS) {
        $context = $null
        try {
            $context = $browser.NewContextAsync(@{
                Viewport = @{ Width = $res.Width; Height = $res.Height }
                DeviceScaleFactor = 1
            }).Result
            
            $page = $context.NewPageAsync().Result
            
            # Seite laden
            $page.GotoAsync($Url, @{ 
                WaitUntil = "networkidle"
                Timeout = 60000 
            }).Wait()
            
            # Warten
            Start-Sleep -Milliseconds $Wait
            
            # Klicken wenn angegeben
            if ($Click) {
                try {
                    $button = $page.GetByRoleAsync("button", @{ Name = $Click }).Result
                    $button.First.ClickAsync(@{ Timeout = 8000 }).Wait()
                    Start-Sleep -Milliseconds 2000
                } catch {
                    Write-Error "[$engine/$($res.Name)] Klick '$Click' fehlgeschlagen: $_"
                }
            }
            
            # Screenshot speichern
            $file = Join-Path $OutDir "$engine-$($res.Name).png"
            $page.ScreenshotAsync(@{ 
                Path = $file
                FullPage = $Full.IsPresent
            }).Wait()
            
            # Phase ermitteln
            $phaseElement = $page.Locator("[data-pond-phase]")
            $phase = try { 
                $phaseElement.GetAttributeAsync("data-pond-phase").Result 
            } catch { 
                $null 
            }
            
            $manifest += @{
                Engine = $engine
                Res = $res.Name
                File = $file
                Phase = $phase
            }
            
            Write-Host ("OK  {0,-8} {1,-13} phase={2,-7}  {3}" -f 
                $engine, $res.Name, ($phase ?? "-"), $file)
                
        } catch {
            Write-Error "ERR $engine/$($res.Name): $_"
        } finally {
            if ($context) {
                $context.Dispose()
            }
        }
    }
    
    if ($browser) {
        $browser.Dispose()
    }
}

Write-Host "`n$($manifest.Count) Screenshots in $OutDir"
