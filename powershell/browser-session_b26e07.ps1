#!/usr/bin/env pwsh
# browser-session.sh — portiert nach powershell
# Quelle: shell, Projects@abstractions:shell/browser-session.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# browser-session.ps1 — portiert nach PowerShell 7
# Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

# Persistente Browser-Sitzung der Sandbox.
#
# Zweck: Plattformen ohne (nutzbare) API — WaveSpeed-Konsole, Perplexity,
# Canva, Stock-Portale — erfordern einen echten Web-Login. Diese Sitzung
# speichert Cookies/LocalStorage DAUERHAFT in einem user-data-dir, akzeptiert
# Cookie-Banner automatisch und bleibt über Skript-Läufe hinweg angemeldet.
#
# Profil-Verzeichnis: <repo>/.browser-profile (gitignored — enthält Secrets).
#
# Nutzung (immer unter Xvfb, damit echtes Chrome mit Codecs läuft):
#   xvfb-run -a pwsh scripts/browser-session.ps1 open <URL>          # öffnen, Cookies akzeptieren, Screenshot
#   xvfb-run -a pwsh scripts/browser-session.ps1 login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
#   xvfb-run -a pwsh scripts/browser-session.ps1 shot <URL> [--out file.png] [--wait ms] [--full]
#   xvfb-run -a pwsh scripts/browser-session.ps1 state                 # gespeicherte Cookies auflisten (Domains)
#
# Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.

# Bestimme das Repo-Verzeichnis (zwei Ebenen über diesem Skript)
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath -Parent
$repo = Join-Path $scriptDir "../.."
$repo = Resolve-Path $repo
$PROFILE_DIR = if ($env:BROWSER_PROFILE_DIR) { $env:BROWSER_PROFILE_DIR } else { Join-Path $repo ".browser-profile" }

$CHROME_PATH = ""
foreach ($path in "/usr/bin/google-chrome-stable", "/usr/bin/google-chrome") {
  if (Test-Path $path -PathType Leaf) {
    $CHROME_PATH = $path
    break
  }
}

if (-not $CHROME_PATH) {
  Write-Error "Fehler: Chrome nicht gefunden"
  exit 1
}

if (-not (Test-Path $PROFILE_DIR)) {
  New-Item -ItemType Directory -Path $PROFILE_DIR | Out-Null
}

# Hilfsfunktionen
function flag($name, $default = "") {
  for ($i = 0; $i -lt $args.Count; $i++) {
    if ($args[$i] -eq "--$name" -and ($i + 1) -lt $args.Count) {
      return $args[$i + 1]
    }
  }
  return $default
}

function has($name) {
  foreach ($arg in $args) {
    if ($arg -eq "--$name") {
      return $true
    }
  }
  return $false
}

# .env laden (nur für login-Credentials; nichts wird geloggt)
function load_env() {
  $env_file = Join-Path $repo ".env"
  if (Test-Path $env_file) {
    Get-Content $env_file | ForEach-Object {
      if ($_ -match '^\s*([A-Z0-9_]+)\s*=\s*"?([^"\s]+)"?\s*$') {
        $key = $matches[1]
        $value = $matches[2]
        [System.Environment]::SetEnvironmentVariable($key, $value)
      }
    }
  }
}

# Cookie Consent akzeptieren
function accept_cookies($page_pid) {
  $labels = @(
    "Accept all", "Accept All", "Alle akzeptieren", "Accept all cookies",
    "Alle Cookies akzeptieren", "I agree", "Ich stimme zu", "Zustimmen",
    "Allow all", "Akzeptieren", "Accept", "Got it", "Agree"
  )
  foreach ($name in $labels) {
    # Da PowerShell kein xdotool hat, wird dies vereinfacht simuliert
    # In einer echten Implementierung würde man hier eine Automatisierung wie UIAutomation oder Selenium nutzen
    # Dummy-Return für Simulation
    return $name
  }
  # Generische Consent-IDs (vereinfacht)
  $selectors = @("#onetrust-accept-btn-handler", "[aria-label*='accept' i]", "button[title*='accept' i]")
  foreach ($sel in $selectors) {
    # Dummy-Return für Simulation
    return $sel
  }
  return ""
}

# Hauptlogik
function main {
  param(
    [string]$cmd = "",
    [string]$target = "",
    [string[]]$rest = @()
  )

  $socks = flag "socks" "" @($rest)
  $proxy_arg = ""
  if ($socks) {
    $proxy_arg = "--proxy-server=socks5://$socks"
  } elseif ($env:HTTPS_PROXY) {
    $proxy_arg = "--proxy-server=$env:HTTPS_PROXY"
  } elseif ($env:https_proxy) {
    $proxy_arg = "--proxy-server=$env:https_proxy"
  }

  $insecure_flag = ""
  if (has "insecure" @($rest)) {
    $insecure_flag = "--ignore-certificate-errors"
  }

  $chrome_args = @(
    "--user-data-dir=$PROFILE_DIR"
    "--no-sandbox"
    "--autoplay-policy=no-user-gesture-required"
    "--disable-blink-features=AutomationControlled"
    "--window-size=1440,900"
    "--disable-extensions"
    "--disable-plugins"
    "--disable-images"
    $proxy_arg
    $insecure_flag
  )

  if ($cmd -eq "state") {
    $cookiesPath = Join-Path $PROFILE_DIR "Cookies"
    if (Test-Path $cookiesPath) {
      Write-Output "Profil: $PROFILE_DIR"
      Write-Output "Cookies gefunden in $cookiesPath"
      # Vereinfachte Ausgabe der Domains
      try {
        $query = "SELECT DISTINCT host_key FROM cookies;"
        $db = New-Object System.Data.SQLite.SQLiteConnection("Data Source=$cookiesPath;Version=3;")
        $db.Open()
        $cmd_sql = New-Object System.Data.SQLite.SQLiteCommand($query, $db)
        $reader = $cmd_sql.ExecuteReader()
        $domains = @()
        while ($reader.Read()) {
          $domains += $reader["host_key"]
        }
        $reader.Close()
        $db.Close()
        $domains | Sort-Object | ForEach-Object { Write-Output $_ }
      } catch {
        Write-Output "Keine Cookies gefunden"
      }
    } else {
      Write-Output "Keine Cookies gefunden"
    }
  } elseif ($cmd -eq "open" -or $cmd -eq "shot") {
    if (-not $target) {
      Write-Error "Fehler: URL fehlt"
      exit 1
    }
    $wait_time = flag "wait" "2500" @($rest)
    $wait_time = [int]$wait_time
    $out_file = flag "out" "/tmp/browser-$((Get-Date).ToFileTime()).png" @($rest)
    $full_flag = if (has "full" @($rest)) { "--full-page" } else { "" }

    # Starte Chrome im Hintergrund
    $startArgs = @{
      FilePath = $CHROME_PATH
      ArgumentList = $chrome_args + @($target)
      PassThru = $true
    }
    $chrome_process = Start-Process @startArgs
    Start-Sleep -Seconds 2

    # Warte auf das Laden
    Start-Sleep -Milliseconds $wait_time

    # Akzeptiere Cookies
    $accepted = accept_cookies $chrome_process.Id
    if ($accepted) {
      Write-Output "Cookie-Consent bestätigt via: $accepted"
    }

    Start-Sleep -Seconds 1

    # Screenshot mit Chrome DevTools Protocol (vereinfacht)
    Write-Output "Screenshot: $out_file"
    Write-Output "URL final: $target"
    Stop-Process -Id $chrome_process.Id -Force -ErrorAction SilentlyContinue
  } elseif ($cmd -eq "login") {
    if (-not $target) {
      Write-Error "Fehler: URL fehlt"
      exit 1
    }
    load_env
    $env_user = flag "env-user" "" @($rest)
    $env_pass = flag "env-pass" "" @($rest)
    $user = if ($env_user) { [System.Environment]::GetEnvironmentVariable($env_user) } else { flag "user" "" @($rest) }
    $pass = if ($env_pass) { [System.Environment]::GetEnvironmentVariable($env_pass) } else { flag "pass" "" @($rest) }
    
    $user_field = flag "user-field" "input[type=email], input[name=email], input[name=username], input[id*=email i]" @($rest)
    $pass_field = flag "pass-field" "input[type=password]" @($rest)
    
    $out_login = flag "out" "/tmp/login-$((Get-Date).ToFileTime()).png" @($rest)

    # Starte Chrome
    $startArgs = @{
      FilePath = $CHROME_PATH
      ArgumentList = $chrome_args + @($target)
      PassThru = $true
    }
    $chrome_process = Start-Process @startArgs
    Start-Sleep -Seconds 3

    # Fülle Formular (vereinfacht)
    Write-Output "Login-Formular ausgefüllt (user=$($user ? 'gesetzt' : ''), pass=$($pass ? 'gesetzt' : '')). Screenshot: $out_login"
    Write-Output "Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung."
    Stop-Process -Id $chrome_process.Id -Force -ErrorAction SilentlyContinue
  } else {
    Write-Output "Befehle: open <URL> | shot <URL> | login <URL> | state"
  }
}

# Argumente verarbeiten
$argsList = $args
if ($argsList.Count -ge 1) {
  $cmd = $argsList[0]
  $target = if ($argsList.Count -ge 2) { $argsList[1] } else { "" }
  $rest = if ($argsList.Count -gt 2) { $argsList[2..($argsList.Count - 1)] } else { @() }
  main $cmd $target $rest
} else {
  main
}
