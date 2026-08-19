#!/usr/bin/env pwsh
# pplx-refresh.sh — portiert nach powershell
# Quelle: shell, OpenClaw@main:scripts/pplx-tools/pplx-refresh.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Refresh the codespace Perplexity session from a locally-exported cookie.
#
# Usage:
#   ./pplx-refresh.ps1 [cookie-file]
#
# cookie-file defaults to ~/pplx-cookies.txt. Put your local browser's
# __Secure-next-auth.session-token value (raw), or the whole Cookie header,
# or a JSON cookie export, into that file first.
#
# Steps: ensure daemon browser -> read daemon passphrase -> inject into vault
#        -> trigger reinit -> verify authenticated.

$ErrorActionPreference = "Stop"

$HERE = Split-Path -Parent $MyInvocation.MyCommand.Definition
$CFG = if ($env:PERPLEXITY_CONFIG_DIR) { $env:PERPLEXITY_CONFIG_DIR } else { Join-Path $HOME ".perplexity-mcp" }
$PROFILE_NAME = if ($env:PERPLEXITY_PROFILE) { $env:PERPLEXITY_PROFILE } else { "codespace" }
$COOKIE_FILE = if ($args.Count -gt 0) { $args[0] } else { Join-Path $HOME "pplx-cookies.txt" }

if (-not (Test-Path $COOKIE_FILE -PathType Leaf) -or (Get-Item $COOKIE_FILE).Length -eq 0) {
    Write-Host "✗ Cookie file empty/missing: $COOKIE_FILE"
    Write-Host "  Export __Secure-next-auth.session-token from your local browser"
    Write-Host "  (DevTools → Application → Cookies → www.perplexity.ai) into that file."
    exit 1
}

# 1. ensure the extension daemon has a usable browser (idempotent)
& "$HERE/pplx-setup.ps1"

# 2. daemon pid + vault passphrase (never guessed — read from the live daemon)
$LOCK = Join-Path $CFG "daemon.lock"
if (-not (Test-Path $LOCK)) {
    Write-Host "✗ no daemon.lock at $LOCK — is the extension running?"
    exit 1
}

try {
    $lockContent = Get-Content $LOCK | ConvertFrom-Json
    $PID = $lockContent.pid
} catch {
    Write-Host "✗ Failed to parse daemon.lock JSON"
    exit 1
}

if (-not (Get-Process -Id $PID -ErrorAction SilentlyContinue)) {
    Write-Host "✗ daemon pid $PID not running"
    exit 1
}

# Read environment variables of the process
$process = Get-WmiObject Win32_Process -Filter "ProcessId=$PID"
$envVars = $process.GetEnvironmentStrings()
$PASS = ""
foreach ($line in $envVars) {
    if ($line -match "^PERPLEXITY_VAULT_PASSPHRASE=(.*)") {
        $PASS = $matches[1]
        break
    }
}

if ([string]::IsNullOrEmpty($PASS)) {
    Write-Host "✗ no PERPLEXITY_VAULT_PASSPHRASE in daemon env"
    exit 1
}

# 3. locate the perplexity-user-mcp dist (populate npx cache if needed)
$NPM_CACHE = Join-Path $HOME ".npm\_npx"
$DIST = ""
if (Test-Path $NPM_CACHE) {
    $distDirs = Get-ChildItem -Recurse -Directory -Path $NPM_CACHE | Where-Object { $_.FullName -like "*perplexity-user-mcp*" -and $_.Name -eq "dist" }
    if ($distDirs.Count -gt 0) {
        $DIST = $distDirs[0].FullName
    }
}

if ([string]::IsNullOrEmpty($DIST)) {
    try {
        # Attempt to populate npx cache
        npx -y perplexity-user-mcp --version *>$null
        $distDirs = Get-ChildItem -Recurse -Directory -Path $NPM_CACHE | Where-Object { $_.FullName -like "*perplexity-user-mcp*" -and $_.Name -eq "dist" }
        if ($distDirs.Count -gt 0) {
            $DIST = $distDirs[0].FullName
        }
    } catch {
        # Ignore errors during population attempt
    }
}

# 4. inject
$env:PERPLEXITY_VAULT_PASSPHRASE = $PASS
$env:PERPLEXITY_CONFIG_DIR = $CFG
$env:PERPLEXITY_PROFILE = $PROFILE_NAME
$env:PPLX_DIST = $DIST
node "$HERE/pplx-inject.mjs" "$COOKIE_FILE"
Remove-Item Env:\PERPLEXITY_VAULT_PASSPHRASE, Env:\PERPLEXITY_CONFIG_DIR, Env:\PERPLEXITY_PROFILE, Env:\PPLX_DIST -ErrorAction SilentlyContinue

# 5. trigger daemon reinit
$REINIT_PATH = Join-Path $CFG "profiles/$PROFILE_NAME/.reinit"
$timestamp = [int][double]::Parse((Get-Date -UFormat %s))
Set-Content -Path $REINIT_PATH -Value $timestamp
Write-Host "→ reinit triggered, waiting for daemon..."

# 6. verify
$STAT = Join-Path $CFG "profiles/$PROFILE_NAME/daemon-status.json"
for ($i = 1; $i -le 20; $i++) {
    Start-Sleep -Seconds 1.5
    $AUTH = ""
    $TIER = ""
    try {
        $statusData = Get-Content $STAT | ConvertFrom-Json
        $AUTH = $statusData.authenticated.ToString()
        $TIER = $statusData.tier
    } catch {
        # Ignore parsing errors
    }

    if ($AUTH -eq "True") {
        Write-Host "✅ authenticated — tier: $TIER"
        exit 0
    }
}
Write-Host "⚠️  not authenticated yet. Check: Get-Content -Tail 20 '$(Join-Path $CFG "daemon.log")'"
exit 1
