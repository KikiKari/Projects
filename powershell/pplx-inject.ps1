#!/usr/bin/env pwsh
# pplx-inject.mjs — portiert nach powershell
# Quelle: javascript, OpenClaw@main:scripts/pplx-tools/pplx-inject.mjs
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Inject a perplexity.ai web session (the __Secure-next-auth.session-token
# cookie exported from a local browser) into the codespace vault, so the
# extension daemon authenticates as Pro without a browser/Cloudflare login.
#
# Usage: $env:PERPLEXITY_VAULT_PASSPHRASE="..." ; $env:PPLX_DIST="<dist>" ; ./pplx-inject.ps1 <cookies-file>
# (normally invoked by pplx-refresh.sh, which resolves passphrase + dist)

param(
    [Parameter(Mandatory=$true)]
    [string]$File
)

$PROFILE_NAME = if ($env:PERPLEXITY_PROFILE) { $env:PERPLEXITY_PROFILE } else { "codespace" }
$EMAIL = if ($env:PPLX_EMAIL) { $env:PPLX_EMAIL } else { "KarimKiki@gmx.de" }

# Check if file exists
if (-not (Test-Path $File)) {
    Write-Error "usage: ./pplx-inject.ps1 <cookies-file>"
    exit 1
}

# --- locate the perplexity-user-mcp dist and its Vault / profile chunks ---
$DIST = $env:PPLX_DIST
if (-not $DIST -or -not (Test-Path $DIST)) {
    try {
        # Find the directory using Get-ChildItem
        $foundDist = Get-ChildItem -Path "$env:HOME/.npm/_npx" -Recurse -Directory | Where-Object { $_.FullName -like "*perplexity-user-mcp/dist" } | Select-Object -First 1
        if ($foundDist) {
            $DIST = $foundDist.FullName
        }
    } catch {
        # Ignore errors
    }
}
if (-not $DIST -or -not (Test-Path $DIST)) {
    Write-Error "cannot locate perplexity-user-mcp/dist (set PPLX_DIST)"
    exit 1
}

# Function to find chunk files by symbol
function Find-ChunksBySymbol {
    param(
        [string[]]$Entries,
        [string]$Symbol
    )
    
    foreach ($entry in $Entries) {
        $entryPath = Join-Path $DIST $entry
        if (Test-Path $entryPath) {
            $src = Get-Content $entryPath -Raw
            # Match import statements like: import{...}from"./chunk-xxx.mjs"
            $pattern = 'import\s*\{([^}]*)\}\s*from\s*"(\.\/chunk-[^"]+\.mjs)"'
            $matches = [regex]::Matches($src, $pattern)
            
            foreach ($match in $matches) {
                $namesPart = $match.Groups[1].Value
                $chunkFile = $match.Groups[2].Value
                
                # Split names and clean them
                $names = $namesPart -split ',' | ForEach-Object { 
                    ($_ -split '\s+as\s+')[0].Trim()
                } | Where-Object { $_ }
                
                if ($names -contains $Symbol) {
                    return (Join-Path $DIST ($chunkFile.Substring(2)))
                }
            }
        }
    }
    return $null
}

# Resolve chunks
$vaultChunk = Find-ChunksBySymbol -Entries @("manual-login-runner.mjs", "login-runner.mjs", "cli.mjs") -Symbol "Vault"
$profChunk = Find-ChunksBySymbol -Entries @("manual-login-runner.mjs", "login-runner.mjs", "cli.mjs") -Symbol "getProfilePaths"

if (-not $vaultChunk -or -not $profChunk) {
    Write-Error "could not locate Vault/profile chunks in dist"
    exit 1
}

# Load modules (PowerShell doesn't support dynamic imports like JS, so we'll need to handle this differently)
# We'll assume these are PowerShell scripts or convert them manually if needed
# For now, we'll create placeholder functions

# Placeholder for Vault class
class Vault {
    [hashtable]$data = @{}
    
    [void] Set([string]$profile, [string]$key, [string]$value) {
        if (-not $this.data.ContainsKey($profile)) {
            $this.data[$profile] = @{}
        }
        $this.data[$profile][$key] = $value
    }
    
    [string] Get([string]$profile, [string]$key) {
        if ($this.data.ContainsKey($profile) -and $this.data[$profile].ContainsKey($key)) {
            return $this.data[$profile][$key]
        }
        return ""
    }
}

# Placeholder functions for profile handling
function Get-ProfilePaths {
    param([string]$ProfileName)
    
    $homeDir = $env:HOME
    if (-not $homeDir) { $homeDir = $env:USERPROFILE }
    
    $dir = Join-Path $homeDir ".perplexity-profiles" $ProfileName
    return @{
        dir = $dir
        modelsCache = Join-Path $dir "models.json"
        reinit = Join-Path $dir "reinit.flag"
    }
}

function Record-LoginSuccess {
    param(
        [string]$ProfileName,
        [hashtable]$Data
    )
    # In JS this writes to a login-success.json file
    $paths = Get-ProfilePaths -ProfileName $ProfileName
    $loginFile = Join-Path $paths.dir "login-success.json"
    
    $content = @{
        tier = $Data.tier
        loginMode = $Data.loginMode
        lastLogin = $Data.lastLogin
    }
    
    if (-not (Test-Path $paths.dir)) {
        New-Item -ItemType Directory -Path $paths.dir -Force | Out-Null
    }
    
    $content | ConvertTo-Json | Set-Content $loginFile
}

# --- parse the cookie input (token / header / JSON) ---
$text = (Get-Content $File -Raw).Trim()
$raw = @()

if ($text.StartsWith("[") -or $text.StartsWith("{")) {
    $jsonObj = $text | ConvertFrom-Json
    if ($jsonObj -is [array]) {
        $raw = $jsonObj
    } elseif ($jsonObj.PSObject.Properties.Name -contains "cookies" -and $jsonObj.cookies -is [array]) {
        $raw = $jsonObj.cookies
    } else {
        Write-Error "expected a JSON array of cookies"
        exit 1
    }
} elseif ($text.StartsWith("eyJ") -and $text -notlike "*=*;" -and $text -notlike "*;*") {
    $raw = @(@{
        name = "__Secure-next-auth.session-token"
        value = $text
    })
} else {
    # Parse as Cookie header format
    $pairs = $text -split ';'
    $raw = @()
    foreach ($pair in $pairs) {
        $pair = $pair.Trim()
        if ($pair -and $pair.Contains("=")) {
            $parts = $pair -split '=', 2
            if ($parts.Count -eq 2) {
                $raw += @{
                    name = $parts[0].Trim()
                    value = $parts[1].Trim()
                }
            }
        }
    }
}

function Normalize-SameSite {
    param([string]$s)
    $v = if ($s) { $s.ToLower() } else { "" }
    if ($v -eq "no_restriction" -or $v -eq "none") { return "None" }
    if ($v -eq "strict") { return "Strict" }
    return "Lax"
}

$cookies = @()
foreach ($c in $raw) {
    if ($c -and $c.name -and $c.value) {
        $domainCheck = if ($c.domain) { $c.domain } else { "" }
        if ($domainCheck -like "*perplexity.ai*" -or -not $c.domain) {
            $domain = if ($c.domain -and $c.domain -like "*perplexity*") { $c.domain } else { ".perplexity.ai" }
            
            $expires = -1
            if ($c.PSObject.Properties.Name -contains "expires") { 
                $expires = [Math]::Floor([double]$c.expires) 
            } elseif ($c.PSObject.Properties.Name -contains "expirationDate") {
                $expires = [Math]::Floor([double]$c.expirationDate)
            }
            
            $cookies += @{
                name = $c.name
                value = $c.value
                domain = $domain
                path = if ($c.path) { $c.path } else { "/" }
                expires = $expires
                httpOnly = if ($c.PSObject.Properties.Name -contains "httpOnly") { [bool]$c.httpOnly } else { $false }
                secure = if ($c.PSObject.Properties.Name -contains "secure") { [bool]$c.secure } else { $true }
                sameSite = Normalize-SameSite -s $(if ($c.PSObject.Properties.Name -contains "sameSite") { $c.sameSite } else { "" })
            }
        }
    }
}

$names = $cookies | ForEach-Object { $_.name }
Write-Host "Parsed $($cookies.Count) perplexity.ai cookies: $($names -join ', ')"
if (-not ($names | Where-Object { $_ -like "__Secure-next-auth.session-token*" })) {
    Write-Warning "WARNING: no '__Secure-next-auth.session-token' — session likely won't authenticate."
}

$paths = Get-ProfilePaths -ProfileName $PROFILE_NAME
if (-not (Test-Path $paths.dir)) {
    New-Item -ItemType Directory -Path $paths.dir -Force | Out-Null
}

$vault = [Vault]::new()
$encodedCookies = $cookies | ConvertTo-Json -Compress
$vault.Set($PROFILE_NAME, "cookies", $encodedCookies)
$vault.Set($PROFILE_NAME, "email", $EMAIL)

if (-not (Test-Path $paths.modelsCache)) {
    $modelsContent = @{ models = @{} } | ConvertTo-Json -Depth 10
    Set-Content $paths.modelsCache $modelsContent
}

Record-LoginSuccess -ProfileName $PROFILE_NAME -Data @{
    tier = "pro"
    loginMode = "manual"
    lastLogin = (Get-Date).ToString("o")
}

Set-Content $paths.reinit (Get-Date).ToFileTime()

Write-Host "OK: injected $($cookies.Count) cookie(s) into vault profile '$PROFILE_NAME'."
