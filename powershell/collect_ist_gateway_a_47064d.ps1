#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "30c5553219b4b37b7954c134e7efb28be4f30c4a86a18d3bf0342925a5a157a1", "source_sha256": "47064dbc7b32c01d57d42222f8cc3ac7caf9c8d82b98029dc5fc6ecb0d32f2c9", "target_language": "powershell"}
# collect_ist_gateway_a.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/collect_ist_gateway_a.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

$BASE_DIR = "$env:USERPROFILE\.openclaw"
$OUT_DIR = "$BASE_DIR\workspace\vscode"
$NOW_UTC = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$NOW_LOCAL = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss zzz").Replace(":", "")
$TS = (Get-Date).ToString("yyyyMMdd-HHmmss")

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

try {
    $HOSTNAME_FQDN = [System.Net.Dns]::GetHostEntry($env:COMPUTERNAME).HostName
} catch {
    $HOSTNAME_FQDN = $env:COMPUTERNAME
}
$HOSTNAME_SHORT = $env:COMPUTERNAME
$ARCH = if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") { "x86_64" } else { $env:PROCESSOR_ARCHITECTURE }
$KERNEL = [System.Environment]::OSVersion.VersionString
try {
    $OS_INFO = Get-CimInstance Win32_OperatingSystem
    $OS_PRETTY = "$($OS_INFO.Caption) $($OS_INFO.Version)"
} catch {
    $OS_PRETTY = "Windows (Version nicht ermittelbar)"
}
$IPV4_ALL = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"}).IPAddress -join ", "
try {
    $PUBLIC_IP = Invoke-RestMethod -Uri "http://ifconfig.me/ip" -TimeoutSec 4 -ErrorAction Stop
} catch {
    $PUBLIC_IP = "(nicht ermittelt)"
}
try {
    $TAILSCALE_IP = (tailscale ip -4 2>$null) | Select-Object -First 1
} catch {
    $TAILSCALE_IP = "(nicht ermittelt)"
}
try {
    $OPENCLAW_VER = & openclaw --version 2>$null
} catch {
    $OPENCLAW_VER = "(nicht ermittelt)"
}
try {
    $NODE_VER = & node -v 2>$null
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

Set-Content -Path $INV_FILE -Value @"
# Artefakt-Inventar: Gateway A / Node 1

Stand: $NOW_LOCAL

## Top-Level in ~/.openclaw

````text
$((Get-ChildItem -Path $BASE_DIR -Name -ErrorAction SilentlyContinue) -join "`n")
````

## ~/.openclaw/.vscode

````text
$((Get-ChildItem -Path $VSCODE_DIR -Recurse -ErrorAction SilentlyContinue | Format-Table -Property Mode, LastWriteTime, Length, Name -AutoSize | Out-String).Trim())
````

## plugin-skills/

````text
$((Get-ChildItem -Path "$BASE_DIR\plugin-skills" -Name -ErrorAction SilentlyContinue) -join "`n")
````

## openclaw.json Backups

````text
$((Get-ChildItem -Path "$BASE_DIR\openclaw.json.bak*" -Name -ErrorAction SilentlyContinue) -join "`n")
````
"@ -Encoding UTF8

Set-Content -Path $CFG_FILE -Value @"
# OpenClaw Config Snapshot: Gateway A / Node 1

Stand: $NOW_LOCAL

## Schluesselpositionen (grep)

````text
$((Get-Content -Path $OPENCLAW_JSON -ErrorAction SilentlyContinue | Select-String -Pattern '"gateway"|"session"|"dmScope"|"auth"|"secrets"|"tools"|"plugins"|"profile"|"alsoAllow"|"denyCommands"') -join "`n")
````

## Ausschnitt gateway/session/auth

````json
$((Get-Content -Path $OPENCLAW_JSON -ErrorAction SilentlyContinue)[579..779] -join "`n")
````
"@ -Encoding UTF8

Set-Content -Path $ENV_FILE -Value @"
# ENV-Status: Gateway A / Node 1

Stand: $NOW_LOCAL

## Dateien

````text
$((Get-ChildItem -Path $ENV_DOT, $ENV_SYSTEMD -ErrorAction SilentlyContinue | Format-Table -Property Mode, LastWriteTime, Length, Name -AutoSize | Out-String).Trim())
````

## .env (vollstaendig)

````dotenv
$((Get-Content -Path $ENV_DOT -ErrorAction SilentlyContinue) -join "`n")
````

## gateway.systemd.env (vollstaendig)

````dotenv
$((Get-Content -Path $ENV_SYSTEMD -ErrorAction SilentlyContinue) -join "`n")
````
"@ -Encoding UTF8

@"
# Laufprotokoll Gateway A / Node 1

- Zeit (lokal): $NOW_LOCAL
- Zeit (UTC): $NOW_UTC
- Script: $PSCommandPath

## Erzeugte Dateien

- $(Split-Path -Leaf $IST_FILE)
- $(Split-Path -Leaf $INV_FILE)
- $(Split-Path -Leaf $CFG_FILE)
- $(Split-Path -Leaf $ENV_FILE)
"@ | Set-Content -Path $RUN_FILE -Encoding UTF8

Write-Output "OK: IST-Zustand erfasst."
Get-ChildItem -Path $OUT_DIR -Name | ForEach-Object { Write-Output "- $_" }
