#!/usr/bin/env pwsh
# collect_ist_gateway_a.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/collect_ist_gateway_a.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

$BASE_DIR = "$env:USERPROFILE\.openclaw"
$OUT_DIR = "$BASE_DIR\workspace\vscode"
$NOW_UTC = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$NOW_LOCAL = Get-Date
$TS = Get-Date -Format "yyyyMMdd-HHmmss"

New-Item -ItemType Directory -Path $OUT_DIR -Force | Out-Null

$IST_FILE = "$OUT_DIR\IST-ZUSTAND_GATEWAY-A_NODE1.md"
$INV_FILE = "$OUT_DIR\ARTEFAKT-INVENTAR_GATEWAY-A_NODE1.md"
$CFG_FILE = "$OUT_DIR\OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-A_NODE1.md"
$ENV_FILE = "$OUT_DIR\ENV-STATUS_GATEWAY-A_NODE1.md"
$RUN_FILE = "$OUT_DIR\RUN-$TS.md"

$OPENCLAW_JSON = "$BASE_DIR\openclaw.json"
$ENV_DOT = "$BASE_DIR\.env"
$ENV_SYSTEMD = "$BASE_DIR\gateway.systemd.env"
$VSCODE_DIR = "$BASE_DIR\.vscode"

$HOSTNAME_FQDN = [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName
$HOSTNAME_SHORT = $env:COMPUTERNAME
$ARCH = (Get-WmiObject -Class Win32_Processor | Select-Object -First 1).Architecture
$KERNEL = [System.Environment]::OSVersion.VersionString
$OS_PRETTY = (Get-WmiObject -Class Win32_OperatingSystem).Caption
$IPV4_ALL = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"}).IPAddress -join " "
try {
    $PUBLIC_IP = (Invoke-WebRequest -Uri "http://ifconfig.me" -UseBasicParsing -TimeoutSec 4).Content.Trim()
} catch {
    $PUBLIC_IP = "(nicht ermittelt)"
}
try {
    $TAILSCALE_IP = (tailscale ip -4) -split "`n" | Select-Object -First 1
} catch {
    $TAILSCALE_IP = "(nicht ermittelt)"
}
try {
    $OPENCLAW_VER = (openclaw --version 2>&1) -replace "`n", ""
} catch {
    $OPENCLAW_VER = "(nicht ermittelt)"
}
try {
    $NODE_VER = (node -v 2>&1) -replace "`n", ""
} catch {
    $NODE_VER = "(nicht ermittelt)"
}

if ([string]::IsNullOrEmpty($PUBLIC_IP)) { $PUBLIC_IP = "(nicht ermittelt)" }
if ([string]::IsNullOrEmpty($TAILSCALE_IP)) { $TAILSCALE_IP = "(nicht ermittelt)" }
if ([string]::IsNullOrEmpty($OPENCLAW_VER)) { $OPENCLAW_VER = "(nicht ermittelt)" }
if ([string]::IsNullOrEmpty($NODE_VER)) { $NODE_VER = "(nicht ermittelt)" }

@"
# IST-Zustand: Gateway A / Node 1

Stand (lokal): $NOW_LOCAL  
Stand (UTC): $NOW_UTC

## 1) Identitaet & System

- Gateway: **A**
- Node: **1**
- Hostname (short): `$HOSTNAME_SHORT`
- Hostname (FQDN): `$HOSTNAME_FQDN`
- Architektur: `$ARCH`
- Kernel: `$KERNEL`
- OS: `$OS_PRETTY`
- IPv4 (lokal): `$IPV4_ALL`
- Public IPv4: `$PUBLIC_IP`
- Tailscale IPv4: `$TAILSCALE_IP`
- OpenClaw Version: `$OPENCLAW_VER`
- Node.js Version: `$NODE_VER`

## 2) Arbeitsverzeichnisse

- Basis: `$BASE_DIR`
- Funktionell VSCode: `$VSCODE_DIR`
- Workspace Doku: `$OUT_DIR`

## 3) Kernartefakte (Existenz)

- `$OPENCLAW_JSON`: $(if (Test-Path $OPENCLAW_JSON) { "vorhanden" } else { "fehlt" })
- `$ENV_DOT`: $(if (Test-Path $ENV_DOT) { "vorhanden" } else { "fehlt" })
- `$ENV_SYSTEMD`: $(if (Test-Path $ENV_SYSTEMD) { "vorhanden" } else { "fehlt" })
- `$BASE_DIR\plugins\installs.json`: $(if (Test-Path "$BASE_DIR\plugins\installs.json") { "vorhanden" } else { "fehlt" })
- `$BASE_DIR\plugin-skills`: $(if (Test-Path "$BASE_DIR\plugin-skills") { "vorhanden" } else { "fehlt" })
"@ | Set-Content -Path $IST_FILE -Encoding UTF8

@"
# Artefakt-Inventar: Gateway A / Node 1

Stand: $NOW_LOCAL

## Top-Level in ~/.openclaw

```text
$(@(
    if (Test-Path $BASE_DIR) {
        Get-ChildItem -Path $BASE_DIR -Name | ForEach-Object { $_ }
    }
) -join "`n")
```

## ~/.openclaw/.vscode

```text
$(@(
    if (Test-Path $VSCODE_DIR) {
        Get-ChildItem -Path $VSCODE_DIR -Force | ForEach-Object {
            "$($_.Mode) $($_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) $($_.Length.ToString().PadLeft(10)) $($_.Name)"
        }
    } else {
        "(nicht vorhanden)"
    }
) -join "`n")
```

## plugin-skills/

```text
$(@(
    if (Test-Path "$BASE_DIR\plugin-skills") {
        Get-ChildItem -Path "$BASE_DIR\plugin-skills" -Name | ForEach-Object { $_ }
    } else {
        "(nicht vorhanden)"
    }
) -join "`n")
```

## openclaw.json Backups

```text
$(@(
    $backupFiles = Get-ChildItem -Path "$BASE_DIR\openclaw.json.bak*" -ErrorAction SilentlyContinue
    if ($backupFiles) {
        $backupFiles | ForEach-Object { $_.Name }
    } else {
        "(keine gefunden)"
    }
) -join "`n")
```
"@ | Set-Content -Path $INV_FILE -Encoding UTF8

@"
# OpenClaw Config Snapshot: Gateway A / Node 1

Stand: $NOW_LOCAL

## Schluesselpositionen (grep)

```text
$(@(
    if (Test-Path $OPENCLAW_JSON) {
        $content = Get-Content -Path $OPENCLAW_JSON -Raw
        $lines = $content -split "`n"
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '"gateway"|\"session\"|\"dmScope\"|\"auth\"|\"secrets\"|\"tools\"|\"plugins\"|\"profile\"|\"alsoAllow\"|\"denyCommands\"') {
                "$($i + 1): $($lines[$i].Trim())"
            }
        }
    } else {
        "openclaw.json fehlt"
    }
) -join "`n")
```

## Ausschnitt gateway/session/auth

```json
$(@(
    if (Test-Path $OPENCLAW_JSON) {
        $lines = Get-Content -Path $OPENCLAW_JSON
        $start = 579
        $end = 779
        if ($lines.Count -ge $start) {
            if ($lines.Count -lt $end) { $end = $lines.Count }
            $lines[$start..$end] | ForEach-Object { $_ }
        }
    } else {
        '{ "error": "openclaw.json fehlt" }'
    }
) -join "`n")
```
"@ | Set-Content -Path $CFG_FILE -Encoding UTF8

@"
# ENV-Status: Gateway A / Node 1

Stand: $NOW_LOCAL

## Dateien

```text
$(@(
    if (Test-Path $ENV_DOT) {
        $item = Get-Item $ENV_DOT
        "$($item.Mode) $($item.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) $($item.Length.ToString().PadLeft(10)) $($item.Name)"
    }
    if (Test-Path $ENV_SYSTEMD) {
        $item = Get-Item $ENV_SYSTEMD
        "$($item.Mode) $($item.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) $($item.Length.ToString().PadLeft(10)) $($item.Name)"
    }
) -join "`n")
```

## .env (vollstaendig)

```dotenv
$(@(
    if (Test-Path $ENV_DOT) {
        Get-Content -Path $ENV_DOT
    } else {
        "# .env fehlt"
    }
) -join "`n")
```

## gateway.systemd.env (vollstaendig)

```dotenv
$(@(
    if (Test-Path $ENV_SYSTEMD) {
        Get-Content -Path $ENV_SYSTEMD
    } else {
        "# gateway.systemd.env fehlt"
    }
) -join "`n")
```
"@ | Set-Content -Path $ENV_FILE -Encoding UTF8

@"
# Laufprotokoll Gateway A / Node 1

- Zeit (lokal): $NOW_LOCAL
- Zeit (UTC): $NOW_UTC
- Script: $((Get-Item $MyInvocation.MyCommand.Path).FullName)

## Erzeugte Dateien

- $(Split-Path -Leaf $IST_FILE)
- $(Split-Path -Leaf $INV_FILE)
- $(Split-Path -Leaf $CFG_FILE)
- $(Split-Path -Leaf $ENV_FILE)
"@ | Set-Content -Path $RUN_FILE -Encoding UTF8

Write-Host "OK: IST-Zustand erfasst."
Get-ChildItem -Path $OUT_DIR -Name | ForEach-Object { Write-Host "- $_" }
