#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "50b73ab241bbeeb951597958092555010c2b25d8bf1cf87afaef89785a54fc94", "source_sha256": "dd115a5287b5db772bd4af098a6620a66b294c0e327633048101753a48a3976b", "target_language": "powershell"}
# openclaw-node-autostart-termux.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
# auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

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
try {
    $tmuxCheck = tmux has-session -t $SESSION 2>$null
    if ($LASTEXITCODE -eq 0) {
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') OpenClaw Node läuft bereits in tmux Session '$SESSION'" | Out-File -Append -FilePath $LOGFILE
        exit 0
    }
} catch {}

# Neue tmux Session erstellen und OpenClaw starten
$tmuxCommand = @"
while ( `$true ) {
    Write-Output "`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') Starting OpenClaw Node Mode..." | Tee-Object -Append -FilePath '$LOGFILE'
    
    # Prüfe WireGuard Verbindung
    if (-not (Test-Connection -Count 1 -TimeoutSeconds 3 $GATEWAY -Quiet)) {
        Write-Output "`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') FEHLER: WireGuard Gateway $GATEWAY nicht erreichbar!" | Tee-Object -Append -FilePath '$LOGFILE'
        Write-Output "`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') Warte 10 Sekunden..." | Tee-Object -Append -FilePath '$LOGFILE'
        Start-Sleep -Seconds 10
        continue
    }
    
    # OpenClaw Node Mode starten
    openclaw node run --host $GATEWAY --port $PORT 2>&1 | Tee-Object -Append -FilePath '$LOGFILE'
    
    # Wenn der Prozess endet, warte und neustarten
    Write-Output "`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') OpenClaw beendet. Neustart in 5 Sekunden..." | Tee-Object -Append -FilePath '$LOGFILE'
    Start-Sleep -Seconds 5
}
"@

# Entferne Zeilenumbrüche und maskiere Anführungszeichen für tmux
$escapedTmuxCommand = $tmuxCommand -replace '"', '\"'

tmux new-session -d -s $SESSION -n "node" "pwsh -Command `"$escapedTmuxCommand`""

"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') OpenClaw Node Autostart aktiviert (tmux Session: $SESSION)" | Out-File -Append -FilePath $LOGFILE

# Optional: tmux attach Hinweis falls interaktiv gestartet
if ([Environment]::UserInteractive) {
    Write-Host "OpenClaw Node Mode gestartet in tmux Session '$SESSION'"
    Write-Host "Zum Anschauen: tmux attach -t $SESSION"
    Write-Host "Log-Datei: $LOGFILE"
}
