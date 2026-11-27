#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "3b9883ba447dccaed005c0e997e3a7c5da79453e4ad420d584b44922596fa8f4", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "powershell"}
# peak-limiter.html — portiert nach powershell
# Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Funktion zur Berechnung des Pegels in dBFS
function Get-PeakDb {
    param([float[]]$values)
    
    $maxValue = ($values | ForEach-Object { [Math]::Abs($_) } | Measure-Object -Maximum).Maximum
    if ($maxValue -eq 0) { $maxValue = 1e-10 }
    
    return 20 * [Math]::Log10($maxValue)
}

# Funktion zur Konvertierung der Limiter-Stärke in dBFS
function Convert-LimiterStrengthToDbfs {
    param([int]$strength)
    return -0.01 * [Math]::Pow($strength, 2)
}

# Funktion zur Kompensationsberechnung für den Make-up Gain
function Get-LimiterMakeupCompensation {
    param([float]$threshold, [float]$ratio)
    return -$threshold * (1 - 1/$ratio)
}

# Funktion zur Erstellung eines PeakLimiter-Nodes (simuliert)
function New-PeakLimiterNode {
    # In PowerShell simulieren wir die Node-Erstellung
    return @{
        SetProtection = {
            param([hashtable]$protection)
            # Simulierte Set-Protection-Logik
        }
    }
}

# Funktion zur Audiorenderung
function Invoke-AudioRender {
    param(
        [string]$kind,
        [Nullable[int]]$strength,
        [bool]$legacy
    )
    
    $rate = 48000
    $length = $rate
    
    # Erstelle leeres Array für Audiodaten
    $data = @(0) * $length
    
    # Generiere Testsignale entsprechend dem Typ
    for ($i = 0; $i -lt $length; $i++) {
        if ($kind -eq 'speech-band') {
            $data[$i] = 0.01 * [Math]::Sin(2 * [Math]::PI * 220 * $i / $rate)
        }
        elseif ($kind -eq 'short-high-tone' -and $i -ge 5000 -and $i -lt 5100) {
            $data[$i] = 0.95 * [Math]::Sin(2 * [Math]::PI * 8000 * $i / $rate)
        }
        elseif ($kind -eq 'level-step' -and $i -ge 5000 -and $i -lt 10000) {
            $data[$i] = 0.95 * [Math]::Sin(2 * [Math]::PI * 1000 * $i / $rate)
        }
    }
    
    # Impuls-Signal
    if ($kind -eq 'impulse') {
        $data[5000] = 0.95
    }
    
    # Berechne Eingangspegel
    $inputDbfs = Get-PeakDb -values $data
    
    # Simuliere Audioverarbeitungskette
    $outputData = $data.Clone()
    
    # Wenn Stärke angegeben ist, wende Verarbeitung an
    if ($strength -ne $null) {
        # Dynamische Kompression (vereinfacht)
        if ($legacy) {
            $threshold = Convert-LimiterStrengthToDbfs -strength $strength
            # Vereinfachte Kompressionslogik
            for ($i = 0; $i -lt $outputData.Length; $i++) {
                $absValue = [Math]::Abs($outputData[$i])
                if ($absValue -gt [Math]::Pow(10, $threshold/20)) {
                    # Wende Kompression an
                    $outputData[$i] = $outputData[$i] * ([Math]::Pow(10, $threshold/20) / $absValue)
                }
            }
            
            # Füge Make-up Gain hinzu
            $makeupGain = Get-LimiterMakeupCompensation -threshold $threshold -ratio 20
            $gainFactor = [Math]::Pow(10, $makeupGain/20)
            for ($i = 0; $i -lt $outputData.Length; $i++) {
                $outputData[$i] = $outputData[$i] * $gainFactor
            }
        }
        # Moderner Limiter (vereinfacht simuliert)
        else {
            # Ähnliche Logik wie oben, aber mit anderen Parametern
            $threshold = Convert-LimiterStrengthToDbfs -strength $strength
            for ($i = 0; $i -lt $outputData.Length; $i++) {
                $absValue = [Math]::Abs($outputData[$i])
                if ($absValue -gt [Math]::Pow(10, $threshold/20)) {
                    $outputData[$i] = $outputData[$i] * ([Math]::Pow(10, $threshold/20) / $absValue)
                }
            }
        }
    }
    
    # Berechne Ausgangspegel
    $outputDbfs = Get-PeakDb -values $outputData
    
    # Bestimme Pfadbezeichnung
    $path = ""
    if ($strength -eq $null) {
        $path = "off"
    }
    elseif ($legacy) {
        $path = "0.8.2-compressor"
    }
    else {
        $path = "candidate-lookahead"
    }
    
    return @{
        kind = $kind
        strength = $strength
        path = $path
        inputDbfs = $inputDbfs
        outputDbfs = $outputDbfs
    }
}

# Hauptausführung
try {
    Write-Host "Starte Audioprüfung..." -ForegroundColor Yellow
    
    $rows = @()
    
    # Definiere Testsignaltypen
    $signalKinds = @('impulse', 'short-high-tone', 'level-step', 'speech-band')
    $strengthLevels = @(25, 75, 100)
    
    # Durchlaufe alle Kombinationen
    foreach ($kind in $signalKinds) {
        # Ohne Begrenzer
        $rows += Invoke-AudioRender -kind $kind -strength $null -legacy $false
        
        # Mit verschiedenen Stärken
        foreach ($strength in $strengthLevels) {
            # Legacy-Kompressor
            $rows += Invoke-AudioRender -kind $kind -strength $strength -legacy $true
            # Moderner Begrenzer
            $rows += Invoke-AudioRender -kind $kind -strength $strength -legacy $false
        }
    }
    
    # Identifiziere Fehler
    $failures = @()
    foreach ($row in $rows) {
        if ($row.path -eq "candidate-lookahead") {
            $limitDbfs = Convert-LimiterStrengthToDbfs -strength $row.strength
            if ($row.outputDbfs -gt ($limitDbfs + 0.05) -or 
                ($row.kind -eq "speech-band" -and [Math]::Abs($row.outputDbfs - $row.inputDbfs) -gt 0.05)) {
                $failures += $row
            }
        }
    }
    
    # Erstelle Ergebnisobjekt
    $result = @{
        passed = ($failures.Count -eq 0)
        failures = $failures
        rows = $rows
    }
    
    # Konvertiere zu JSON und speichere in Datei
    $jsonResult = $result | ConvertTo-Json -Depth 10
    $jsonResult | Out-File -FilePath $OutputPath -Encoding UTF8
    
    Write-Host "Audioprüfung abgeschlossen. Ergebnisse gespeichert in: $OutputPath" -ForegroundColor Green
    
} catch {
    $errorMessage = "FEHLER: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
    $errorMessage | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Error $errorMessage
}
