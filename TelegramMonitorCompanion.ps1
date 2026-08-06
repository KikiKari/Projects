<#
    Telegram Monitor Companion — Starter

    Startet den lokalen Monitor im Hintergrund (kein Konsolenfenster), wartet,
    bis der Port wirklich antwortet, und oeffnet die Oberflaeche als eigenes
    Fenster ohne Adressleiste. Laeuft der Monitor schon, wird er nicht erneut
    gestartet — dann wird nur das Fenster geoeffnet.

    Aufruf:
      .\TelegramMonitorCompanion.ps1              starten und oeffnen
      .\TelegramMonitorCompanion.ps1 -Stop        beenden
      .\TelegramMonitorCompanion.ps1 -Status      nachsehen, ob er laeuft
      .\TelegramMonitorCompanion.ps1 -Port 9000   anderer Port
      .\TelegramMonitorCompanion.ps1 -Console     mit sichtbarem Fenster (Fehlersuche)
#>
[CmdletBinding()]
param(
  [int]    $Port     = 8765,
  [int]    $Interval = 120,
  [switch] $Stop,
  [switch] $Status,
  [switch] $Console,
  [switch] $NoBrowser
)

$ErrorActionPreference = 'Stop'
$Root    = Split-Path -Parent $MyInvocation.MyCommand.Path
$PidFile = Join-Path $Root 'data\companion.pid'
$LogFile = Join-Path $Root 'data\companion.log'
$Url     = "http://127.0.0.1:$Port"

function Write-Step($msg) { Write-Host "  $msg" }

function Test-Monitor {
  try {
    $r = Invoke-WebRequest -Uri "$Url/api/status" -TimeoutSec 2 -UseBasicParsing
    return $r.StatusCode -eq 200
  } catch { return $false }
}

function Get-MonitorProcess {
  if (-not (Test-Path $PidFile)) { return $null }
  $id = (Get-Content $PidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
  if (-not $id) { return $null }
  return Get-Process -Id ([int]$id) -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------- beenden ---
if ($Stop) {
  $p = Get-MonitorProcess
  if ($p) { Stop-Process -Id $p.Id -Force; Write-Step "Monitor beendet (PID $($p.Id))." }
  else    { Write-Step 'Es lief kein Monitor aus diesem Starter.' }
  Remove-Item $PidFile -ErrorAction SilentlyContinue
  return
}

# ----------------------------------------------------------------- Status ---
if ($Status) {
  if (Test-Monitor) {
    $p = Get-MonitorProcess
    Write-Step "Monitor laeuft auf $Url$(if ($p) { "  (PID $($p.Id))" })."
  } else {
    Write-Step "Auf $Url antwortet nichts."
  }
  return
}

# ------------------------------------------------------------------ Start ---
Write-Host ''
Write-Host '  Telegram Monitor Companion'
Write-Host '  --------------------------'

# Python suchen: erst py-Starter, dann python im Pfad.
$exe = $null; $pre = @()
foreach ($c in @(@{e='py';a=@('-3')}, @{e='python';a=@()}, @{e='python3';a=@()})) {
  if (Get-Command $c.e -ErrorAction SilentlyContinue) { $exe = $c.e; $pre = $c.a; break }
}
if (-not $exe) {
  Write-Host ''
  Write-Host '  Python wurde nicht gefunden.' -ForegroundColor Yellow
  Write-Host '  Herunterladen: https://www.python.org/downloads/'
  Write-Host '  Beim Installieren "Add python.exe to PATH" ankreuzen.'
  Write-Host ''
  Read-Host '  Eingabetaste zum Schliessen'
  exit 1
}
Write-Step "Python: $exe $($pre -join ' ')"

if (Test-Monitor) {
  Write-Step "Monitor laeuft bereits auf $Url — wird nicht erneut gestartet."
} else {
  New-Item -ItemType Directory -Force -Path (Split-Path $PidFile) | Out-Null
  $args = $pre + @('server.py', '--port', "$Port", '--poll-interval', "$Interval", '--no-browser')

  if ($Console) {
    $proc = Start-Process -FilePath $exe -ArgumentList $args -WorkingDirectory $Root -PassThru
  } else {
    # Ohne Fenster, Ausgabe in die Protokolldatei.
    $proc = Start-Process -FilePath $exe -ArgumentList $args -WorkingDirectory $Root `
              -WindowStyle Hidden -PassThru `
              -RedirectStandardOutput $LogFile -RedirectStandardError "$LogFile.err"
  }
  Set-Content -Path $PidFile -Value $proc.Id
  Write-Step "Gestartet (PID $($proc.Id)), warte auf Antwort ..."

  $ok = $false
  foreach ($i in 1..40) {                     # bis zu 20 Sekunden
    Start-Sleep -Milliseconds 500
    if (Test-Monitor) { $ok = $true; break }
    if ($proc.HasExited) { break }
  }
  if (-not $ok) {
    Write-Host ''
    Write-Host '  Der Monitor hat nicht geantwortet.' -ForegroundColor Yellow
    if (Test-Path "$LogFile.err") {
      Write-Host '  Letzte Zeilen der Fehlerausgabe:'
      Get-Content "$LogFile.err" -Tail 15 | ForEach-Object { Write-Host "    $_" }
    }
    Write-Host ''
    Write-Host '  Nochmal mit sichtbarem Fenster:  .\TelegramMonitorCompanion.ps1 -Console'
    Read-Host '  Eingabetaste zum Schliessen'
    exit 1
  }
  Write-Step 'Antwortet.'
}

if ($NoBrowser) { Write-Step "Bereit: $Url"; return }

# Als eigenes Fenster oeffnen (App-Modus), sonst normaler Tab.
$edge   = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$chrome = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
if     (Test-Path $edge)   { Start-Process $edge   "--app=$Url"; Write-Step 'Als eigenes Fenster geoeffnet (Edge).' }
elseif (Test-Path $chrome) { Start-Process $chrome "--app=$Url"; Write-Step 'Als eigenes Fenster geoeffnet (Chrome).' }
else                       { Start-Process $Url;                 Write-Step 'Im Standardbrowser geoeffnet.' }

Write-Host ''
Write-Host "  Laeuft im Hintergrund auf $Url"
Write-Host '  Beenden:  .\TelegramMonitorCompanion.ps1 -Stop'
Write-Host ''
