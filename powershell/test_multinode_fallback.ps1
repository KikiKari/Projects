#!/usr/bin/env pwsh
# test_multinode_fallback.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:scripts/test_multinode_fallback.py
# auch in: OpenClaw@gateway2:scripts/test_multinode_fallback.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

<#
.Testet Multi-Node Fallback-Logik des db-maintainer
Simuliert: Worker-Node nicht erreichbar → Fallback auf lokal
#>

$WORKSPACE = "/home/openclaw/.openclaw/workspace"

function Check-NodeReachable {
    param(
        [string]$NodeId
    )
    <#
    .Prüft ob Node erreichbar ist
    #>
    try {
        # Versuche Node-Status abzufragen
        $result = & openclaw nodes status 2>&1 | Out-String
        return ($result -like "*$NodeId*" -and $result -like "*connected*")
    } catch {
        return $false
    }
}

function Spawn-OnNode {
    param(
        [string]$NodeId,
        [string]$Task
    )
    <#
    .Versucht Task auf Node auszuführen
    #>
    Write-Host "Versuche Task auf Node $NodeId zu starten..."
    try {
        # Simuliert: openclaw agent spawn --node {node_id}
        $result = & echo "Spawned on $NodeId`: $Task" 2>&1 | Out-String
        Write-Host "✅ Erfolgreich delegiert an $NodeId"
        return $true
    } catch {
        Write-Host "❌ Node $NodeId nicht erreichbar: $_"
        return $false
    }
}

function Execute-Locally {
    param(
        [string]$Task
    )
    <#
    .Führt Task lokal aus (Fallback)
    #>
    Write-Host "🔄 Fallback: Führe Task lokal aus..."
    try {
        if ($Task -eq 'db_maintainer') {
            $scriptPath = Join-Path $WORKSPACE "skills/db-maintainer/scripts/db_maintainer.py"
            $result = & python3 $scriptPath 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Lokale Ausführung erfolgreich"
                return $true
            } else {
                Write-Host "❌ Fehler: $($result.Substring(0, [Math]::Min($result.Length, 200)))"
                return $false
            }
        }
    } catch {
        Write-Host "❌ Lokale Ausführung fehlgeschlagen: $_"
        return $false
    }
}

function Main {
    Write-Host ("=" * 60)
    Write-Host "MULTI-NODE FALLBACK TEST"
    Write-Host ("=" * 60)
    Write-Host ""
    
    # Konfiguration
    $primaryNode = 'v2202603104722445775'  # Node 2
    $task = 'db_maintainer'
    
    Write-Host "Primärer Node: $primaryNode"
    Write-Host "Task: $task"
    Write-Host ""
    
    # 1. Prüfe Node-Erreichbarkeit
    Write-Host "--- 1. Prüfe Node-Erreichbarkeit ---"
    if (Check-NodeReachable -NodeId $primaryNode) {
        Write-Host "✅ Node $primaryNode ist erreichbar"
        
        # 2. Versuche Delegation
        Write-Host "`n--- 2. Versuche Delegation ---"
        if (Spawn-OnNode -NodeId $primaryNode -Task $task) {
            Write-Host "`n✅ MULTI-NODE: Task erfolgreich delegiert"
            return 0
        } else {
            Write-Host "`n⚠️ Delegation fehlgeschlagen, aktiviere Fallback..."
        }
    } else {
        Write-Host "❌ Node $primaryNode nicht erreichbar"
        Write-Host "🔄 Fallback wird aktiviert..."
    }
    
    # 3. Lokale Ausführung (Fallback)
    Write-Host "`n--- 3. Lokale Ausführung (Fallback) ---"
    if (Execute-Locally -Task $task) {
        Write-Host "`n✅ FALLBACK: Task lokal erfolgreich ausgeführt"
        return 0
    } else {
        Write-Host "`n❌ FEHLER: Weder Delegation noch Fallback erfolgreich"
        return 1
    }
}

exit (Main)
