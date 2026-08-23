#!/usr/bin/env pwsh
# wavespeed-image.js — portiert nach powershell
# Quelle: javascript, OpenClaw@gateway1:scripts/wavespeed-image.js
# auch in: OpenClaw@gateway2:wavespeed-image.js
# auch in: OpenClaw@gateway2:scripts/wavespeed-image.js
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
WaveSpeed Image Analysis Tool
.DESCRIPTION
User-Requested Only — kostenpflichtig ($0.14/Bild)
#>

# Config
$API_BASE = 'https://api.wavespeed.ai/v1'
$MAX_IMAGES = 7
$PRICE_PER_IMAGE = 0.14

# Load token from env
$BANANA_TOKEN = $env:BANANA_TOKEN

function Show-Usage {
    Write-Host @"
Usage: wavespeed-image <command> [options]

Commands:
  analyze <image...>    Analyze one or more images

Options:
  --prompt <text>       Analysis prompt (required)
  --dry-run             Show cost without executing
  -h, --help            Show this help

Examples:
  wavespeed-image analyze photo.jpg --prompt "What's in this image?"
  wavespeed-image analyze img1.jpg img2.jpg --prompt "Compare these"
"@
}

function Show-CostWarning($imageCount) {
    $totalCost = ($imageCount * $PRICE_PER_IMAGE).ToString("F2")
    $imageCountStr = $imageCount.ToString().PadRight(44)
    $pricePerImageStr = $PRICE_PER_IMAGE.ToString().PadRight(43)
    $totalCostStr = ('$' + $totalCost).PadRight(44)
    
    Write-Host @"

╔════════════════════════════════════════════════════════════╗
║  ⚠️  KOSTENHINWEIS — WaveSpeed Image Analysis              ║
╠════════════════════════════════════════════════════════════╣
║  Anzahl Bilder: $imageCountStr║
║  Preis pro Bild: `$pricePerImageStr║
║  Gesamtkosten: ~`$totalCostStr║
╠════════════════════════════════════════════════════════════╣
║  Abrechnung über dein WaveSpeed Guthaben                   ║
║  https://wavespeed.ai/account/billing                      ║
╚════════════════════════════════════════════════════════════╝
"@
}

function Confirm-Execution {
    # In OpenClaw context, this would be handled by the system
    # For CLI: require explicit --confirm flag
    return $args.Contains('--confirm')
}

function Analyze-Images($imagePaths, $prompt) {
    Write-Host "`n🖼️  Analysiere $($imagePaths.Count) Bilder..."
    Write-Host "📝 Prompt: `"$prompt`""
    Write-Host "`n⏳ Anfrage wird gesendet...`n"
    
    # TODO: Implement actual API call
    # For now, return simulated response
    $results = @()
    foreach ($img in $imagePaths) {
        $fileName = Split-Path $img -Leaf
        $results += [PSCustomObject]@{
            file = $fileName
            analysis = "[Analyse-Ergebnis für $fileName würde hier stehen]"
        }
    }
    
    return [PSCustomObject]@{
        success = $true
        results = $results
    }
}

function Main {
    $args = $args
    
    if ($args.Count -eq 0 -or $args -contains '-h' -or $args -contains '--help') {
        Show-Usage
        exit 0
    }
    
    # Check auth
    if (-not $BANANA_TOKEN) {
        Write-Error "❌ Fehler: BANANA_TOKEN nicht gesetzt in ~/.config/openclaw/env"
        exit 1
    }
    
    $command = $args[0]
    
    if ($command -eq 'analyze') {
        # Parse arguments
        $imagePaths = @()
        $prompt = ''
        $i = 1
        
        while ($i -lt $args.Count) {
            if ($args[$i] -eq '--prompt') {
                $i++
                if ($i -lt $args.Count) {
                    $prompt = $args[$i]
                }
            } elseif ($args[$i] -eq '--dry-run' -or $args[$i] -eq '--confirm') {
                # Skip
            } elseif (-not $args[$i].StartsWith('--')) {
                $imagePaths += $args[$i]
            }
            $i++
        }
        
        # Validate
        if ($imagePaths.Count -eq 0) {
            Write-Error "❌ Fehler: Mindestens ein Bild-Pfad erforderlich"
            exit 1
        }
        
        if ($imagePaths.Count -gt $MAX_IMAGES) {
            Write-Error "❌ Fehler: Maximum $MAX_IMAGES Bilder erlaubt"
            exit 1
        }
        
        if (-not $prompt) {
            Write-Error "❌ Fehler: --prompt erforderlich"
            exit 1
        }
        
        # Validate files exist
        foreach ($img in $imagePaths) {
            if (-not (Test-Path $img)) {
                Write-Error "❌ Fehler: Datei nicht gefunden: $img"
                exit 1
            }
        }
        
        # Show cost warning
        Show-CostWarning -imageCount $imagePaths.Count
        
        # Dry run
        if ($args -contains '--dry-run') {
            Write-Host "✅ Dry-run: Keine API-Anfrage gesendet`n"
            exit 0
        }
        
        # Check for confirmation
        if (-not (Confirm-Execution -args $args)) {
            Write-Host "`n⚠️  Hinweis: Füge --confirm hinzu um die Anfrage auszuführen"
            Write-Host "   Befehl: wavespeed-image analyze $($imagePaths -join ' ') --prompt `"$prompt`" --confirm`n"
            exit 0
        }
        
        # Execute
        $result = Analyze-Images -imagePaths $imagePaths -prompt $prompt
        
        if ($result.success) {
            Write-Host "✅ Analyse abgeschlossen`n"
            foreach ($r in $result.results) {
                Write-Host "📄 $($r.file):"
                Write-Host "   $($r.analysis)`n"
            }
        }
        
    } else {
        Write-Error "❌ Unbekannter Befehl: $command"
        Show-Usage
        exit 1
    }
}

try {
    Main
} catch {
    Write-Error "❌ Fehler: $($_.Exception.Message)"
    exit 1
}
