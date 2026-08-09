#!/usr/bin/env pwsh
# ops-hub-heartbeat.js — portiert nach powershell
# Quelle: javascript, OpenClaw@gateway1:scripts/ops-hub-heartbeat.js
# auch in: OpenClaw@gateway2:scripts/ops-hub-heartbeat.js
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Aktualisiere den Statusbericht mit aktueller Zeit
$statusPath = Join-Path $PSScriptRoot "../docs/ops-hub/status.md"

function Update-Heartbeat {
    try {
        $content = Get-Content -Path $statusPath -Encoding UTF8 -Raw
    }
    catch {
        Write-Error "❌ Konnte status.md nicht lesen: $($_.Exception.Message)"
        return
    }

    $now = (Get-Date).ToString("dd.MM.yyyy HH:mm:ss")
    $updated = $content -replace "(Letzter Heartbeat:) .*$", "`$1 $now"

    try {
        Set-Content -Path $statusPath -Value $updated -Encoding UTF8
        Write-Host "✅ Heartbeat aktualisiert: $now"
    }
    catch {
        Write-Error "❌ Konnte status.md nicht schreiben: $($_.Exception.Message)"
    }
}

Update-Heartbeat
