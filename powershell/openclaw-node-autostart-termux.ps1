#!/usr/bin/env pwsh
# openclaw-node-autostart-termux.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
# auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# OpenClaw Node Mode Autostart für Termux (Node 5 - Redmi Note 11)
# Installiert nach: ~/.termux/boot/openclaw-node.sh
# Getestet mit: Termux + Android + OpenClaw

$SESSION = "openclaw-node"
$LOGFILE = "$env:HOME/.openclaw/node.log"
$GATEWAY = "10.10.0.1"
$PORT = "18789"

# Log-Verzeichnis erstellen
$null = New-Item -ItemType Directory -Path "$env:HOME/.openclaw" -Force

# Prüfen ob tmux Session bereits läuft
$tmuxCheck = tmux has-session -t $SESSION 2>$null
if ($LASTEXITCODE -eq 0) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LOGFILE -Value "[$timestamp] OpenClaw Node läuft bereits in tmux Session '$SESSION'"
    exit 0
}

# Neue tmux Session erstellen und OpenClaw starten
$scriptBlock = @"
while ( `$true ) {
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[`$timestamp] Starting OpenClaw Node Mode..." | Tee-Object -FilePath '$LOGFILE' -Append

    # Prüfe WireGuard Verbindung
    if ( ! ( Test-Connection -ComputerName $GATEWAY -Count 1 -TimeoutSeconds 3 -Quiet ) ) {
        `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Output "[`$timestamp] FEHLER: WireGuard Gateway $GATEWAY nicht erreichbar!" | Tee-Object -FilePath '$LOGFILE' -Append
        Write-Output "[`$timestamp] Warte 10 Sekunden..." | Tee-Object -FilePath '$LOGFILE' -Append
        Start-Sleep -Seconds 10
        continue
    }

    # OpenClaw Node Mode starten
    openclaw node run --host $GATEWAY --port $PORT 2>&1 | Tee-Object -FilePath '$LOGFILE' -Append

    # Wenn der Prozess endet, warte und neustarten
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[`$timestamp] OpenClaw beendet. Neustart in 5 Sekunden..." | Tee-Object -FilePath '$LOGFILE' -Append
    Start-Sleep -Seconds 5
}
"@

# PowerShell-Befehl in eine temporäre Datei schreiben
$tempScript = [System.IO.Path]::GetTempFileName()
Set-Content -Path $tempScript -Value $scriptBlock

# tmux Session mit PowerShell-Skript starten
tmux new-session -d -s $SESSION -n "node" "pwsh -File `"$tempScript`""

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $LOGFILE -Value "[$timestamp] OpenClaw Node Autostart aktiviert (tmux Session: $SESSION)"

# Optional: tmux attach Hinweis falls interaktiv gestartet
if ([Environment]::UserInteractive) {
    Write-Output "OpenClaw Node Mode gestartet in tmux Session '$SESSION'"
    Write-Output "Zum Anschauen: tmux attach -t $SESSION"
    Write-Output "Log-Datei: $LOGFILE"
}
