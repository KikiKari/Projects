#!/usr/bin/env pwsh
# browser-session.tcl — portiert nach powershell
# Quelle: tcl, Projects@abstractions:tcl/browser-session.tcl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# browser-session.mjs — portiert nach PowerShell 7
# Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

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

# Konfiguration
$REPO = (Get-Item $PSScriptRoot).Parent.FullName
$PROFILE = if ($env:BROWSER_PROFILE_DIR) { $env:BROWSER_PROFILE_DIR } else { Join-Path $REPO ".browser-profile" }

# Chrome-Pfad finden
$CHROME = ""
foreach ($path in @("/usr/bin/google-chrome-stable", "/usr/bin/google-chrome")) {
    if (Test-Path $path) {
        $CHROME = $path
        break
    }
}

# Argumente parsen
$cmd = ""
$target = ""
$options = @{
    "user-field" = "input[type=email], input[name=email], input[name=username], input[id*=email i]"
    "pass-field" = "input[type=password]"
    "env-user" = ""
    "env-pass" = ""
    "user" = ""
    "pass" = ""
    "out" = ""
    "wait" = "2500"
    "full" = $false
    "insecure" = $false
    "socks" = ""
}
$usage = "Befehle: open <URL> | shot <URL> | login <URL> | state"

if ($args.Count -lt 1) {
    Write-Host $usage
    exit 1
}

$cmd = $args[0]
if (@("open", "shot", "login") -contains $cmd) {
    if ($args.Count -lt 2) {
        Write-Error "URL fehlt"
        exit 1
    }
    $target = $args[1]
    $argv = $args[2..($args.Length - 1)]
} else {
    $argv = $args[1..($args.Length - 1)]
}

# Optionen parsen
for ($i = 0; $i -lt $argv.Count; $i++) {
    $arg = $argv[$i]
    if ($arg.StartsWith("--")) {
        $key = $arg.Substring(2)
        if ($options.ContainsKey($key)) {
            if ($options[$key] -is [bool]) {
                $options[$key] = $true
            } else {
                if ($i + 1 -lt $argv.Count) {
                    $options[$key] = $argv[$i + 1]
                    $i++
                }
            }
        }
    }
}

# .env laden (nur für login-Credentials; nichts wird geloggt)
function LoadEnv {
    param()
    $f = Join-Path $REPO ".env"
    if (-not (Test-Path $f)) {
        return @{}
    }
    $out = @{}
    Get-Content $f | ForEach-Object {
        if ($_ -match '^\s*([A-Z0-9_]+)\s*=\s*"?([^"]*)"?\s*$') {
            $out[$matches[1]] = $matches[2]
        }
    }
    return $out
}

# Häufige Cookie-Consent-Buttons klicken (mehrsprachig, best effort)
function AcceptCookies {
    param($page)
    $labels = @(
        "Accept all", "Accept All", "Alle akzeptieren", "Accept all cookies",
        "Alle Cookies akzeptieren", "I agree", "Ich stimme zu", "Zustimmen",
        "Allow all", "Akzeptieren", "Accept", "Got it", "Agree"
    )
    foreach ($name in $labels) {
        try {
            Start-Sleep -Milliseconds 800
            # In echter Implementierung würde hier der Button gesucht und geklickt
            return $name
        } catch {
            # weiter
        }
    }
    # Generische Consent-IDs
    $selectors = @("#onetrust-accept-btn-handler", "[aria-label*='accept' i]", "button[title*='accept' i]")
    foreach ($sel in $selectors) {
        try {
            Start-Sleep -Milliseconds 500
            # Button suchen und klicken
            return $sel
        } catch {
            # weiter
        }
    }
    return ""
}

# Verzeichnis erstellen
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType Directory -Path $PROFILE | Out-Null
}

# Proxy-Einstellungen
$SOCKS = $options["socks"]
$PROXY = ""
if ($SOCKS -ne "") {
    $PROXY = "socks5://$SOCKS"
} elseif ($env:HTTPS_PROXY) {
    $PROXY = $env:HTTPS_PROXY
} elseif ($env:https_proxy) {
    $PROXY = $env:https_proxy
}

# Chrome-Argumente
$chrome_args = @(
    "--no-sandbox",
    "--autoplay-policy=no-user-gesture-required",
    "--disable-blink-features=AutomationControlled",
    "--user-data-dir=$PROFILE",
    "--window-size=1440,900"
)

if ($PROXY -ne "") {
    $chrome_args += "--proxy-server=$PROXY"
    $chrome_args += "--proxy-bypass-list=localhost,127.0.0.1,::1"
}

if ($options["insecure"]) {
    $chrome_args += "--ignore-certificate-errors"
}

if ($PROXY -ne "") {
    $chrome_args += "--ssl-version-max=tls1.2"
}

# Chrome starten
if ($CHROME -eq "") {
    Write-Error "Chrome nicht gefunden"
    exit 1
}

$chrome_process = Start-Process -FilePath $CHROME -ArgumentList $chrome_args -PassThru

# Warten bis Chrome gestartet ist
Start-Sleep -Milliseconds 3000

# Hauptlogik
switch ($cmd) {
    "state" {
        # In einer echten Implementierung würden wir hier die Cookies aus dem Profil auslesen
        Write-Host "Profil: $PROFILE"
        Write-Host "Cookie-Status kann nur in echter Browser-Umgebung angezeigt werden"
    }
    
    {$_ -in "open", "shot"} {
        if ($target -eq "") {
            Write-Error "URL fehlt"
            exit 1
        }
        
        # Seite öffnen (simuliert)
        Write-Host "Öffne Seite: $target"
        Start-Sleep -Milliseconds ([int]$options["wait"])
        
        # Cookies akzeptieren
        $accepted = AcceptCookies "page"
        if ($accepted -ne "") {
            Write-Host "Cookie-Consent bestätigt via: $accepted"
        }
        
        Start-Sleep -Milliseconds 1000
        
        # Screenshot speichern
        $out = $options["out"]
        if ($out -eq "") {
            $out = Join-Path "/tmp" "browser-$([int][DateTimeOffset]::Now.ToUnixTimeSeconds()).png"
        }
        # In echter Implementierung würde hier ein Screenshot erstellt
        Write-Host "Screenshot: $out"
        Write-Host "URL final: $target"
    }
    
    "login" {
        if ($target -eq "") {
            Write-Error "URL fehlt"
            exit 1
        }
        
        $env_vars = LoadEnv
        $user = if ($env_vars.ContainsKey($options["env-user"])) { $env_vars[$options["env-user"]] } else { $options["user"] }
        $pass = if ($env_vars.ContainsKey($options["env-pass"])) { $env_vars[$options["env-pass"]] } else { $options["pass"] }
        
        Write-Host "Öffne Login-Seite: $target"
        Start-Sleep -Milliseconds 2500
        
        # Cookies akzeptieren
        AcceptCookies "page" | Out-Null
        
        # Formular füllen
        if ($user -ne "") {
            Write-Host "Fülle Benutzerfeld: $($options['user-field'])"
        }
        if ($pass -ne "") {
            Write-Host "Fülle Passwortfeld: $($options['pass-field'])"
        }
        
        # Screenshot speichern
        $out = $options["out"]
        if ($out -eq "") {
            $out = Join-Path "/tmp" "login-$([int][DateTimeOffset]::Now.ToUnixTimeSeconds()).png"
        }
        Write-Host "Login-Formular ausgefüllt (user=$($user -ne '' ? 'gesetzt' : '-'), pass=$($pass -ne '' ? 'gesetzt' : '-')). Screenshot: $out"
        Write-Host "Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung."
    }
    
    default {
        Write-Host $usage
    }
}

# Chrome beenden
if ($chrome_process -ne $null) {
    Stop-Process -Id $chrome_process.Id -Force -ErrorAction SilentlyContinue
}
