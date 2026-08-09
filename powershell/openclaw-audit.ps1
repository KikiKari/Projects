#!/usr/bin/env pwsh
# openclaw-audit.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-audit.sh
# auch in: OpenClaw@gateway2:scripts/openclaw-audit.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# OpenClaw read-only audit/diagnostic sweep
# Output: openclaw-audit-YYYY-MM-DD.log im selben Verzeichnis wie dieses Script

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path $MyInvocation.MyCommand.Path -Parent
$DATE_STAMP = Get-Date -Format "yyyy-MM-dd"
$OUT = Join-Path $SCRIPT_DIR "openclaw-audit-$DATE_STAMP.log"

$OC = @("openclaw", "--no-color")

# Create initial log content
@"
================================================================
OpenClaw audit run
Started:  $(Get-Date -Format o)
Host:     $env:COMPUTERNAME
User:     $env:USERNAME
Version:  $(try { openclaw --version 2>$null } catch { "unknown" })
Output:   $OUT
================================================================
"@ | Out-File -FilePath $OUT -Encoding UTF8

function Run-Cmd {
    param(
        [string]$title,
        [string[]]$command
    )
    
    $cmdString = ($command | ForEach-Object { "'$_'" }) -join " "
    
    @"
    
----------------------------------------------------------------
### $title
### \$ $cmdString
### $(Get-Date -Format o)
----------------------------------------------------------------
"@ | Out-File -FilePath $OUT -Encoding UTF8 -Append
    
    try {
        $result = & $command 2>&1
        $result | Out-File -FilePath $OUT -Encoding UTF8 -Append
        $rc = 0
        if ($LASTEXITCODE) { $rc = $LASTEXITCODE }
    } catch {
        $_.Exception.Message | Out-File -FilePath $OUT -Encoding UTF8 -Append
        $rc = 1
    }
    
    "[exit: $rc]" | Out-File -FilePath $OUT -Encoding UTF8 -Append
}

Run-Cmd "tasks audit --severity error" ($OC + "tasks", "audit", "--severity", "error")
Run-Cmd "secrets audit" ($OC + "secrets", "audit")
Run-Cmd "security audit" ($OC + "security", "audit")
Run-Cmd "plugins doctor" ($OC + "plugins", "doctor")
Run-Cmd "plugins deps" ($OC + "plugins", "deps")
Run-Cmd "plugins registry" ($OC + "plugins", "registry")
Run-Cmd "skills check" ($OC + "skills", "check")
Run-Cmd "hooks check" ($OC + "hooks", "check")
Run-Cmd "gateway status --deep" ($OC + "gateway", "status", "--deep")
Run-Cmd "channels status --probe" ($OC + "channels", "status", "--probe")
Run-Cmd "memory status --deep" ($OC + "memory", "status", "--deep")
Run-Cmd "sessions --all-agents" ($OC + "sessions", "--all-agents")
Run-Cmd "tasks list" ($OC + "tasks", "list")
Run-Cmd "cron list" ($OC + "cron", "list")

@"
    
================================================================
Audit complete: $(Get-Date -Format o)
================================================================
"@ | Out-File -FilePath $OUT -Encoding UTF8 -Append

Write-Host "Audit complete. Output: $OUT"
