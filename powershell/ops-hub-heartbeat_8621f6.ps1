#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "d2181e9ba377cecd91ce21f1cdda374015e070b5e2767d786b9859ee17b42a0f", "source_sha256": "8621f6f7e524474de82b3d877ee62bbcbd9fa3b247b69c437b063b71fa995f5a", "target_language": "powershell"}
# ops-hub-heartbeat.js — portiert nach powershell
# Quelle: javascript, OpenClaw@gateway1:scripts/ops-hub-heartbeat.js
# auch in: OpenClaw@gateway2:scripts/ops-hub-heartbeat.js
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Aktualisiere den Statusbericht mit aktueller Zeit
$statusPath = Join-Path $PSScriptRoot "../docs/ops-hub/status.md"

function Update-Heartbeat {
    try {
        $content = Get-Content -Path $statusPath -Encoding UTF8 -Raw
    } catch {
        Write-Error "❌ Konnte status.md nicht lesen: $($_.Exception.Message)"
        return
    }

    $now = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTimeOffset]::Now, 'W. Europe Standard Time').ToString('dd.MM.yyyy HH:mm:ss')
    $updated = $content -replace '(Letzter Heartbeat:) .*', "`$1 $now"

    try {
        Set-Content -Path $statusPath -Value $updated -Encoding UTF8
        Write-Output "✅ Heartbeat aktualisiert: $now"
    } catch {
        Write-Error "❌ Konnte status.md nicht schreiben: $($_.Exception.Message)"
    }
}

Update-Heartbeat
