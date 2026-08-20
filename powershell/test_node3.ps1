#!/usr/bin/env pwsh
# test_node3.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/test_node3.sh
# auch in: OpenClaw@gateway2:scripts/test_node3.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

# Test Node 3 Connection
$env:OPENCLAW_ALLOW_INSECURE_PRIVATE_WS = "1"
Write-Host "Starting node connection test..."
$process = Start-Process -FilePath "/usr/local/bin/openclaw" -ArgumentList "node", "run", "--host", "152.53.145.65", "--port", "18789" -NoNewWindow -PassThru -Wait -RedirectStandardOutput /tmp/openclaw_stdout.txt -RedirectStandardError /tmp/openclaw_stderr.txt
Start-Sleep -Seconds 15
if (!$process.HasExited) {
    Stop-Process -Id $process.Id -Force
}
Get-Content /tmp/openclaw_stdout.txt -ErrorAction SilentlyContinue
Get-Content /tmp/openclaw_stderr.txt -ErrorAction SilentlyContinue
Remove-Item /tmp/openclaw_stdout.txt -ErrorAction SilentlyContinue
Remove-Item /tmp/openclaw_stderr.txt -ErrorAction SilentlyContinue
Write-Host "Exit code: $($process.ExitCode)"
