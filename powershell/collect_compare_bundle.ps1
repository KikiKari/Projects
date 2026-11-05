#!/usr/bin/env pwsh
# collect_compare_bundle.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/collect_compare_bundle.sh
# auch in: OpenClaw@gateway2:scripts/collect_compare_bundle.sh
# Erzeugt: 2026-11-05 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

$ROOT = "/home/openclaw/.openclaw"
$OUT_DIR = "${ROOT}/workspace/vscode/compare"
$TRANSFER_DIR = "${OUT_DIR}/transfer"
$MD_FILE = "${OUT_DIR}/local-gateway-config.md"
$TREE_FILE = "${OUT_DIR}/tree.txt"
$BACKUP_FILE = "/home/openclaw/openclaw-backup.tar.gz"
$NOW_LOCAL = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"
$NOW_UTC = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$HOST = hostname

$OPENCLAW_JSON = "${ROOT}/openclaw.json"
$EXEC_APPROVALS_JSON = "${ROOT}/exec-approvals.json"
$GATEWAY_SYSTEMD_ENV = "${ROOT}/gateway.systemd.env"
$DOT_ENV = "${ROOT}/.env"
$CONFIG_DIR = "${ROOT}/.config"
$AGENTS_DIR = "${ROOT}/agents"

New-Item -ItemType Directory -Path $OUT_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $TRANSFER_DIR -Force | Out-Null

if (-not (Get-Command tree -ErrorAction SilentlyContinue)) {
    Write-Error "Fehler: 'tree' ist nicht installiert."
    exit 1
}

function append_file_verbatim {
    param(
        [string]$label,
        [string]$path,
        [string]$lang = "text"
    )
    
    $content = @"
## $label

Pfad: `$path`

```$lang
$((if (Test-Path $path) { Get-Content $path } else { "[FEHLT] $path" }) -join "`n")
```

"@
    Add-Content $MD_FILE $content
}

function append_env_verbatim {
    $envContent = @"
## Umgebungsvariablen (env)

```text
$((Get-ChildItem Env: | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "`n")
```

"@
    Add-Content $MD_FILE $envContent
}

function append_dir_files_verbatim {
    param(
        [string]$section,
        [string]$dir
    )
    
    $headerContent = @"
## $section

$((if (Test-Path $dir) { "Basisverzeichnis: `$dir" } else { "[FEHLT] $dir" }))

"@
    Add-Content $MD_FILE $headerContent
    
    if (Test-Path $dir) {
        Get-ChildItem -Path $dir -File -Recurse | Sort-Object FullName | ForEach-Object {
            $fileContent = @"

### Datei: `"$($_.FullName)`"

```text
$((Get-Content $_.FullName) -join "`n")

```

"@
            Add-Content $MD_FILE $fileContent
        }
    }
}

$header = @"
# Lokaler Gateway-Konfigurationsstand

Generiert: $NOW_LOCAL
UTC: $NOW_UTC
Host: $HOST

Diese Datei enthaelt den lokalen Stand mit unveraenderten Inhalten.
"@

Set-Content $MD_FILE $header

append_file_verbatim "openclaw.json" $OPENCLAW_JSON "json"
append_file_verbatim "exec-approvals.json" $EXEC_APPROVALS_JSON "json"
append_file_verbatim "gateway.systemd.env" $GATEWAY_SYSTEMD_ENV "dotenv"
append_file_verbatim ".env" $DOT_ENV "dotenv"
append_env_verbatim
append_dir_files_verbatim ".config (alle Dateien rekursiv)" $CONFIG_DIR
append_dir_files_verbatim "agents (alle Dateien rekursiv)" $AGENTS_DIR

tree -a -L 6 $ROOT > $TREE_FILE
openclaw backup create --output $BACKUP_FILE --verify
Copy-Item $BACKUP_FILE $OUT_DIR

Write-Output "OK"
Write-Output "Erzeugt:"
Write-Output "- $MD_FILE"
Write-Output "- $TREE_FILE"
Write-Output "- $BACKUP_FILE"
Write-Output "- $TRANSFER_DIR (leer)"
