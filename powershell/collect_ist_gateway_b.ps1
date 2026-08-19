#!/usr/bin/env pwsh
# collect_ist_gateway_b.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway2:scripts/collect_ist_gateway_b.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

$BASE_DIR = "$env:USERPROFILE\.openclaw"
$OUT_DIR = "$BASE_DIR\workspace\vscode"
$NOW_UTC = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$NOW_LOCAL = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$TS = Get-Date -Format "yyyyMMdd-HHmmss"

New-Item -ItemType Directory -Path $OUT_DIR -Force | Out-Null

$IST_FILE = "$OUT_DIR\IST-ZUSTAND_GATEWAY-B_NODE7.md"
$INV_FILE = "$OUT_DIR\ARTEFAKT-INVENTAR_GATEWAY-B_NODE7.md"
$CFG_FILE = "$OUT_DIR\OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-B_NODE7.md"
$ENV_FILE = "$OUT_DIR\ENV-STATUS_GATEWAY-B_NODE7.md"
$RUN_FILE = "$OUT_DIR\RUN-$TS.md"

$OPENCLAW_JSON = "$BASE_DIR\openclaw.json"
$ENV_DOT = "$BASE_DIR\.env"
$ENV_SYSTEMD = "$BASE_DIR\gateway.systemd.env"
$VSCODE_DIR = "$BASE_DIR\.vscode"

try {
    $HOSTNAME_FQDN = [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName
} catch {
    $HOSTNAME_FQDN = $env:COMPUTERNAME
}
$HOSTNAME_SHORT = $env:COMPUTERNAME
$ARCH = if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { "x86" }
$KERNEL = [System.Environment]::OSVersion.Version.ToString()
$OS_PRETTY = (Get-CimInstance Win32_OperatingSystem).Caption
$IPV4_ALL = ((Get-NetIPAddress -AddressFamily IPv4).IPAddress -join " ").Trim()
try {
    $PUBLIC_IP = Invoke-RestMethod -Uri "http://ifconfig.me" -TimeoutSec 4
} catch {
    $PUBLIC_IP = "(nicht ermittelt)"
}
try {
    $TAILSCALE_IP = (tailscale ip -4 2>$null) | Select-Object -First 1
} catch {
    $TAILSCALE_IP = "(nicht ermittelt)"
}
try {
    $OPENCLAW_VER = openclaw --version 2>$null
} catch {
    $OPENCLAW_VER = "(nicht ermittelt)"
}
try {
    $NODE_VER = node -v 2>$null
} catch {
    $NODE_VER = "(nicht ermittelt)"
}

if (-not $PUBLIC_IP) { $PUBLIC_IP = "(nicht ermittelt)" }
if (-not $TAILSCALE_IP) { $TAILSCALE_IP = "(nicht ermittelt)" }
if (-not $OPENCLAW_VER) { $OPENCLAW_VER = "(nicht ermittelt)" }
if (-not $NODE_VER) { $NODE_VER = "(nicht ermittelt)" }

@"
# IST-Zustand: Gateway B / Node 7

Stand (lokal): $NOW_LOCAL  
Stand (UTC): $NOW_UTC

## 1) Identität & System

- Gateway: **B**
- Node: **7**
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

## 4) Hinweis

Diese Datei wird bei jedem Lauf neu geschrieben.
Zusätzlich wird ein Laufprotokoll als `RUN-*.md` erzeugt.
"@ | Set-Content -Path $IST_FILE -Encoding UTF8

@"
# Artefakt-Inventar: Gateway B / Node 7

Stand: $NOW_LOCAL

## Top-Level in ~/.openclaw

```text
$((Get-ChildItem -Path $BASE_DIR -Name 2>$null) -join "`n")
```

## ~/.openclaw/.vscode

```text
$(
    if (Test-Path $VSCODE_DIR) {
        (Get-ChildItem -Path $VSCODE_DIR | Out-String)
    } else {
        "(nicht vorhanden)"
    }
)
```

## plugin-skills/

```text
$(
    if (Test-Path "$BASE_DIR\plugin-skills") {
        (Get-ChildItem -Path "$BASE_DIR\plugin-skills" -Name 2>$null) -join "`n"
    } else {
        "(nicht vorhanden)"
    }
)
```

## openclaw.json Backups

```text
$(
    $backups = Get-ChildItem -Path "$BASE_DIR\openclaw.json.bak*" -ErrorAction SilentlyContinue
    if ($backups) {
        ($backups.Name -join "`n")
    } else {
        "(keine gefunden)"
    }
)
```
"@ | Set-Content -Path $INV_FILE -Encoding UTF8

@"
# OpenClaw Config Snapshot: Gateway B / Node 7

Stand: $NOW_LOCAL

## Schlüsselpositionen (grep)

```text
$(
    if (Test-Path $OPENCLAW_JSON) {
        (Select-String -Path $OPENCLAW_JSON -Pattern '"gateway"|\"session\"|\"dmScope\"|\"auth\"|\"secrets\"|\"tools\"|\"plugins\"|\"profile\"|\"alsoAllow\"|\"denyCommands\"' | ForEach-Object { $_.Line.Trim() }) -join "`n"
    } else {
        "openclaw.json fehlt"
    }
)
```

## Ausschnitt gateway/session/auth (ungefiltert, betriebsnah)

```json
$(
    if (Test-Path $OPENCLAW_JSON) {
        try {
            $content = Get-Content -Path $OPENCLAW_JSON -Raw
            $lines = $content -split "`n"
            $lines[579..779] -join "`n"
        } catch {
            "{ `"error`": `"Fehler beim Lesen der Zeilen 580-780`" }"
        }
    } else {
        "{ `"error`": `"openclaw.json fehlt`" }"
    }
)
```
"@ | Set-Content -Path $CFG_FILE -Encoding UTF8

@"
# ENV-Status: Gateway B / Node 7

Stand: $NOW_LOCAL

## Dateien

```text
$(
    try {
        (Get-ChildItem -Path $ENV_DOT, $ENV_SYSTEMD -ErrorAction Stop | Out-String)
    } catch {
        # Ignore errors silently
    }
)
```

## .env (vollständig, ungefiltert)

```dotenv
$(
    if (Test-Path $ENV_DOT) {
        Get-Content -Path $ENV_DOT -Raw
    } else {
        "# .env fehlt"
    }
)
```

## gateway.systemd.env (vollständig, ungefiltert)

```dotenv
$(
    if (Test-Path $ENV_SYSTEMD) {
        Get-Content -Path $ENV_SYSTEMD -Raw
    } else {
        "# gateway.systemd.env fehlt"
    }
)
```
"@ | Set-Content -Path $ENV_FILE -Encoding UTF8

@"
# Laufprotokoll Gateway B / Node 7

- Zeit (lokal): $NOW_LOCAL
- Zeit (UTC): $NOW_UTC
- Script: $((Get-Item $MyInvocation.MyCommand.Path).FullName)

## Erzeugte Dateien

- $(Split-Path $IST_FILE -Leaf)
- $(Split-Path $INV_FILE -Leaf)
- $(Split-Path $CFG_FILE -Leaf)
- $(Split-Path $ENV_FILE -Leaf)

"@ | Set-Content -Path $RUN_FILE -Encoding UTF8

Write-Output "OK: IST-Zustand erfasst."
Write-Output "Ausgabeordner: $OUT_DIR"
Write-Output "Dateien:"
Get-ChildItem -Path $OUT_DIR -Name | ForEach-Object { Write-Output "- $_" }
